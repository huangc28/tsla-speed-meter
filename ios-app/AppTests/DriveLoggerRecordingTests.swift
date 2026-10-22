import Foundation
import Testing
import TeslaBLE
@testable import SpeedHUD

/// A link with no car: connect fails, writes fail.
private final class StubLink: BLELink, @unchecked Sendable {
    let events: AsyncStream<BLELinkEvent>
    private let continuation: AsyncStream<BLELinkEvent>.Continuation

    init() {
        (events, continuation) = AsyncStream.makeStream(of: BLELinkEvent.self)
    }

    deinit { continuation.finish() }

    func connect(localName: String, timeout: Duration) async throws -> Int { throw BLELinkError.scanTimedOut }
    func write(_ value: Data) async throws { throw BLELinkError.notConnected }
    func disconnect() async {}
}

private final class MemoryKeyStore: TeslaKeyStore, @unchecked Sendable {
    private let key = SoftwareKeyAgreementKey()
    func clientKey() throws -> any KeyAgreementKey { key }
    func pairedVIN() throws -> String? { nil }
    func setPairedVIN(_ vin: String) throws {}
    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? { nil }
    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws {}
}

@Suite("Drive logger recording")
struct DriveLoggerRecordingTests {
    @Test("start, poll about once a second, stop: rows, meta and the export folder")
    @MainActor func recordsWithoutACar() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
        let suite = "DriveLoggerRecordingTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer {
            try? FileManager.default.removeItem(at: root)
            defaults.removePersistentDomain(forName: suite)
        }
        let client = TeslaVehicleClient(link: StubLink(), keyStore: MemoryKeyStore(), configuration: DriveLogger.configuration)
        let logger = DriveLogger(client: client, defaults: defaults, logsRoot: root)
        #expect(logger.lastFolder == nil)

        logger.startRecording()
        #expect(logger.isRecording)
        try await Task.sleep(for: .milliseconds(2500))
        let stopStarted = ContinuousClock.now
        await logger.stopRecording()
        #expect(ContinuousClock.now - stopStarted < .seconds(1))
        #expect(!logger.isRecording)

        let folder = try #require(logger.lastFolder)
        #expect(DriveLogger.latestFolder(in: root)?.standardizedFileURL == folder.standardizedFileURL)

        let rows = try String(contentsOf: folder.appending(path: "samples.csv"), encoding: .utf8)
            .split(separator: "\n").dropFirst()
        #expect((2...4).contains(rows.count))
        let errorIndex = SampleCSV.columns.firstIndex { $0.key == "error" }!
        #expect(rows.allSatisfy { $0.components(separatedBy: ",")[errorIndex] == "notConnected" })

        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appending(path: "meta.json"))) as? [String: Any]
        #expect(meta?["sample_count"] as? Int == rows.count)
        #expect(meta?["error_count"] as? Int == rows.count)
        let settings = meta?["settings"] as? [String: Any]
        #expect(settings?["poll_interval_ms"] as? Int == 1000)
        #expect(settings?["gps_coordinates_logged"] as? Bool == false)

        let events = try String(contentsOf: folder.appending(path: "events.jsonl"), encoding: .utf8)
        #expect(events.contains("\"recording_started\""))
        #expect(events.contains("\"recording_stopped\""))
    }
}
