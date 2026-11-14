import Foundation
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

/// The `GetVehicleData` field numbers of the seven groups only the probe asks (car_server.proto).
private let probeOnlyFields: Set<Int> = [7, 10, 11, 15, 16, 17, 19]

/// A logger on the fake car, in temporary folders.
@MainActor
private final class ProbeHarness {
    let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
    let suite = "DriveLoggerProbeTests.\(UUID().uuidString)"
    let link: MockLink
    let feed: CarFeed
    let logger: DriveLogger

    init(vehicle: FakeVehicle = FakeVehicle()) {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(ProtocolDoc.vin, forKey: "driveLogger.vin")
        link = MockLink(vehicle: vehicle)
        // First probe asks 50 ms apart instead of 5 s, so all seven come in about a second.
        feed = CarFeed(
            client: TeslaVehicleClient(link: link, keyStore: InMemoryKeyStore(), configuration: .app),
            cadence: CarFeed.Cadence(probeFirstAskSpacing: .milliseconds(50))
        )
        logger = DriveLogger(
            feed: feed, defaults: defaults,
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory)
        )
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: root)
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    /// Requests for a probe-only group the fake car has seen so far.
    func probeOnlyRequests() async -> Int {
        await link.vehicle.vehicleDataRequests.filter { $0.count == 1 && probeOnlyFields.contains($0[0]) }.count
    }

    func requestCount() async -> Int {
        await link.vehicle.vehicleDataRequests.count
    }

    /// Waits up to 5 s (real time) for `condition`.
    func wait(_ condition: () async -> Bool) async throws {
        for _ in 0..<500 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("condition never became true")
    }
}

@Suite("Drive logger probe", .serialized)
struct DriveLoggerProbeTests {
    @Test("the probe switch is off by default; recording with it off asks no probe group and writes no probe.jsonl")
    @MainActor func offByDefault() async throws {
        let harness = ProbeHarness()
        defer { harness.cleanUp() }
        let logger = harness.logger
        #expect(!logger.probeEnabled)

        await logger.connect()
        logger.startRecording()
        try await harness.wait { await harness.requestCount() >= 15 }
        await logger.stopRecording()

        #expect(await harness.probeOnlyRequests() == 0)
        let folder = try #require(logger.lastFolder)
        #expect(!FileManager.default.fileExists(atPath: folder.appending(path: LogSession.probeFileName).path()))
        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appending(path: "meta.json"))) as? [String: Any]
        let settings = meta?["settings"] as? [String: Any]
        #expect(settings?["probe_on"] as? Bool == false)
        #expect(settings?["unencrypted_reply_payloads_saved"] as? Bool == false)
        #expect(settings?["gps_coordinates_logged"] as? Bool == false)
        #expect(meta?["probe_reply_count"] == nil)
    }

    @Test("probe groups are asked only while the logger records with the switch on")
    @MainActor func onlyWhileRecordingWithTheSwitchOn() async throws {
        let harness = ProbeHarness()
        defer { harness.cleanUp() }
        let logger = harness.logger
        await logger.connect()
        // The main screen keeps the feed polling, recording or not.
        let polls = harness.feed.polls()
        let mainScreen = Task { for await _ in polls {} }
        defer { mainScreen.cancel() }

        logger.probeEnabled = true
        let before = await harness.requestCount()
        try await harness.wait { await harness.requestCount() >= before + 15 }
        #expect(await harness.probeOnlyRequests() == 0)

        logger.startRecording()
        try await harness.wait { await harness.probeOnlyRequests() == probeOnlyFields.count }
        await logger.stopRecording()

        let asked = await harness.probeOnlyRequests()
        let stopped = await harness.requestCount()
        try await harness.wait { await harness.requestCount() >= stopped + 15 }
        #expect(await harness.probeOnlyRequests() == asked)
    }

    @Test("a link drop during a probe request: the row says drive was skipped, and why")
    @MainActor func probeLinkDropRow() throws {
        let poll = VehicleDataPoll(entries: [], skipped: [.drive], skipCause: .disconnected)
        let kept = try #require(DriveLogger.recordable(poll))
        let row = SampleCSV.row(Sample(poll: kept, phoneTime: Date(), monotonicMs: 0, gps: nil))
            .trimmingCharacters(in: .newlines).components(separatedBy: ",")
        let column = { (key: String) in SampleCSV.columns.firstIndex { $0.key == key }! }
        #expect(row[column("error")] == "disconnected")
        #expect(row[column("drive_error")] == "skipped")
    }

    @Test("probe.jsonl holds every group's decrypted reply in full: known fields, unknown fields at nested levels, and the bytes")
    @MainActor func logsFullReplies() async throws {
        var vehicle = FakeVehicle()
        vehicle.responsePlaintext = try ProbeFixture.replyWithUnknownFields()
        let harness = ProbeHarness(vehicle: vehicle)
        defer { harness.cleanUp() }
        let logger = harness.logger
        await logger.connect()
        logger.probeEnabled = true
        logger.startRecording()
        try await harness.wait { await harness.probeOnlyRequests() == probeOnlyFields.count }
        try await Task.sleep(for: .milliseconds(600))
        // The car parks and the unknown drive field changes with it: the analysis script's sample.
        let parked = try ProbeFixture.replyWithUnknownFields(speedFloat: 0, parked: true, driveUnknown: 8)
        await harness.link.update { $0.responsePlaintext = parked }
        try await Task.sleep(for: .milliseconds(1000))
        await logger.stopRecording()

        let folder = try #require(logger.lastFolder)
        let lines = try String(contentsOf: folder.appending(path: LogSession.probeFileName), encoding: .utf8)
            .split(separator: "\n")
            .map { try #require(JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: Any]) }
        #expect(Set(lines.compactMap { $0["group"] as? String }) == Set(VehicleDataGroup.allCases.map(\.rawValue)))
        #expect(lines.allSatisfy { $0["answered"] as? Bool == true && $0["phone_time"] is String && $0["monotonic_ms"] is Int })

        let drive = try #require(lines.first { $0["group"] as? String == "drive" })
        let driveText = try #require(drive["text"] as? String)
        #expect(driveText.contains("speed_float: 60.5"))
        #expect(driveText.contains("999: 7"))
        #expect(lines.contains { $0["group"] as? String == "drive" && ($0["text"] as? String)?.contains("999: 8") == true })
        let location = try #require(lines.first { $0["group"] as? String == "location" })
        let locationText = try #require(location["text"] as? String)
        #expect(locationText.contains("heading: 90"))
        #expect(locationText.contains("200 {"))
        #expect(locationText.contains("2: 0x04030201"))
        let hex = try #require(location["plaintext_hex"] as? String)
        let decoded = try CarServer_Response(serializedBytes: Data(hex: hex))
        #expect(decoded.vehicleData.locationState.heading == 90)
        #expect(!decoded.vehicleData.locationState.unknownFields.data.isEmpty)

        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appending(path: "meta.json"))) as? [String: Any]
        let settings = meta?["settings"] as? [String: Any]
        #expect(settings?["probe_on"] as? Bool == true)
        #expect(settings?["probe_saves_decrypted_replies_with_location_and_destination"] as? Bool == true)
        #expect(settings?["unencrypted_reply_payloads_saved"] as? Bool == true)
        #expect(settings?["gps_coordinates_logged"] as? Bool == true)
        #expect(meta?["probe_reply_count"] as? Int == lines.count)

        // Kept as a sample for Tools/probe_changes.py (the newest run replaces it).
        let sample = FileManager.default.temporaryDirectory.appending(path: "probe-sample", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: sample)
        try FileManager.default.copyItem(at: folder, to: sample)
    }
}
