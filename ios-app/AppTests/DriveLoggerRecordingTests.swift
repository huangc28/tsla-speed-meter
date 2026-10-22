import Foundation
import Testing
import TeslaBLE
@testable import SpeedHUD

/// A link with no real car: connect succeeds after `failuresBeforeConnect`
/// failed attempts (never, when nil), writes fail.
private final class StubLink: BLELink, @unchecked Sendable {
    let events: AsyncStream<BLELinkEvent>
    private let continuation: AsyncStream<BLELinkEvent>.Continuation
    private let lock = NSLock()
    private var failuresLeft: Int?
    private var attempts = 0

    init(failuresBeforeConnect: Int? = nil) {
        failuresLeft = failuresBeforeConnect
        (events, continuation) = AsyncStream.makeStream(of: BLELinkEvent.self)
    }

    deinit { continuation.finish() }

    var connectAttempts: Int { lock.withLock { attempts } }

    func setFailuresBeforeConnect(_ count: Int?) { lock.withLock { failuresLeft = count } }

    func emit(_ event: BLELinkEvent) { continuation.yield(event) }

    func connect(localName: String, timeout: Duration) async throws -> Int {
        let succeeds: Bool = lock.withLock {
            attempts += 1
            guard let left = failuresLeft else { return false }
            if left == 0 { return true }
            failuresLeft = left - 1
            return false
        }
        if succeeds { return 20 }
        throw BLELinkError.scanTimedOut
    }

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

/// Temporary folders and defaults for one logger.
@MainActor
private final class Harness {
    let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
    let suite = "DriveLoggerRecordingTests.\(UUID().uuidString)"
    let link: StubLink
    let logger: DriveLogger

    var logsRoot: URL { root.appending(path: "Logs", directoryHint: .isDirectory) }
    var diagnosticsRoot: URL { root.appending(path: "Diagnostics", directoryHint: .isDirectory) }

    init(link: StubLink = StubLink(), vin: String = "5YJ3E1EA0KF123456") {
        self.link = link
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(vin, forKey: "driveLogger.vin")
        let client = TeslaVehicleClient(link: link, keyStore: MemoryKeyStore(), configuration: DriveLogger.configuration)
        logger = DriveLogger(
            client: client, defaults: defaults, logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory),
            reconnectInterval: .milliseconds(50)
        )
    }

    func cleanUp() {
        try? FileManager.default.removeItem(at: root)
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    }

    func lines(_ name: String, in folder: URL) throws -> [String] {
        try String(contentsOf: folder.appending(path: name), encoding: .utf8).split(separator: "\n").map(String.init)
    }
}

@Suite("Drive logger recording", .serialized)
struct DriveLoggerRecordingTests {
    @Test("start, poll about once a second, stop: rows, meta and the export folder")
    @MainActor func recordsWithoutACar() async throws {
        let harness = Harness()
        defer { harness.cleanUp() }
        let logger = harness.logger
        #expect(logger.lastFolder == nil)
        #expect(!logger.canExport)

        logger.startRecording()
        #expect(logger.isRecording)
        try await Task.sleep(for: .milliseconds(2500))
        let stopStarted = ContinuousClock.now
        await logger.stopRecording()
        #expect(ContinuousClock.now - stopStarted < .seconds(1))
        #expect(!logger.isRecording)

        let folder = try #require(logger.lastFolder)
        #expect(DriveLogger.latestFolder(in: harness.logsRoot)?.standardizedFileURL == folder.standardizedFileURL)

        let rows = try harness.lines("samples.csv", in: folder).dropFirst()
        #expect((2...4).contains(rows.count))
        let errorIndex = SampleCSV.columns.firstIndex { $0.key == "error" }!
        #expect(rows.allSatisfy { $0.components(separatedBy: ",")[errorIndex] == "notConnected" })

        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appending(path: "meta.json"))) as? [String: Any]
        #expect(meta?["kind"] as? String == "recording")
        #expect(meta?["sample_count"] as? Int == rows.count)
        #expect(meta?["error_count"] as? Int == rows.count)
        let settings = meta?["settings"] as? [String: Any]
        #expect(settings?["poll_interval_ms"] as? Int == 1000)
        #expect(settings?["gps_coordinates_logged"] as? Bool == false)

        let events = try harness.lines("events.jsonl", in: folder).joined(separator: "\n")
        #expect(events.contains("\"recording_started\""))
        #expect(events.contains("\"recording_stopped\""))
    }

    @Test("a failed first connect is kept in diagnostics, and 匯出 works without a recording")
    @MainActor func diagnosticsFromFirstConnect() async throws {
        let harness = Harness()
        defer { harness.cleanUp() }
        let logger = harness.logger

        await logger.connect()
        #expect(logger.linkStatus != .connected)
        let folder = try #require(logger.diagnosticsFolder)
        #expect(folder.deletingLastPathComponent().standardizedFileURL == harness.diagnosticsRoot.standardizedFileURL)
        // Client events reach the logger through its event stream, a moment later.
        var events = ""
        for _ in 0..<100 where !events.contains("\"connect_failed\"") {
            try await Task.sleep(for: .milliseconds(10))
            events = try harness.lines("events.jsonl", in: folder).joined(separator: "\n")
        }
        #expect(events.contains("\"diagnostics_started\""))
        #expect(events.contains("\"connecting\""))
        #expect(events.contains("\"connect_failed\""))
        #expect(!events.contains("local_name"))
        #expect(!events.contains("5YJ3E1EA0KF123456"))
        #expect(!events.contains(TeslaBLEConstants.localName(forVIN: "5YJ3E1EA0KF123456")))

        await logger.readOnce()
        #expect(try harness.lines("samples.csv", in: folder).count == 2)

        #expect(logger.canExport)
        logger.export()
        let zip = try #require(logger.shareItems?.urls.first)
        defer { try? FileManager.default.removeItem(at: zip) }
        #expect(zip.pathExtension == "zip")
        #expect(try Data(contentsOf: zip).prefix(2) == Data("PK".utf8))

        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: folder.appending(path: "meta.json"))) as? [String: Any]
        #expect(meta?["kind"] as? String == "diagnostics")
        #expect(meta?["sample_count"] as? Int == 1)
    }

    @Test("while recording, a dropped link is reconnected with the saved VIN, retried until it works")
    @MainActor func autoReconnectsWhileRecording() async throws {
        let link = StubLink(failuresBeforeConnect: 0)
        let harness = Harness(link: link)
        defer { harness.cleanUp() }
        let logger = harness.logger

        await logger.connect()
        #expect(logger.linkStatus == .connected)
        logger.startRecording()
        link.setFailuresBeforeConnect(2)
        link.emit(.disconnected(reconnecting: false, reason: "test"))

        for _ in 0..<200 where link.connectAttempts < 4 || logger.linkStatus != .connected {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(link.connectAttempts == 4)
        #expect(logger.linkStatus == .connected)
        await logger.stopRecording()

        let folder = try #require(logger.lastFolder)
        let events = try harness.lines("events.jsonl", in: folder).joined(separator: "\n")
        #expect(events.contains("\"auto_reconnect_failed\""))
        let attempts = events.split(separator: "\n").filter { $0.contains("\"type\":\"auto_reconnect\"") }
        #expect(attempts.count == 3)
        let diagnostics = try harness.lines("events.jsonl", in: try #require(logger.diagnosticsFolder)).joined(separator: "\n")
        #expect(diagnostics.contains("\"auto_reconnect\""))
    }

    @Test("a dropped link outside recording is not reconnected automatically")
    @MainActor func noAutoReconnectWhenIdle() async throws {
        let link = StubLink(failuresBeforeConnect: 0)
        let harness = Harness(link: link)
        defer { harness.cleanUp() }
        await harness.logger.connect()
        link.emit(.disconnected(reconnecting: false, reason: "test"))
        try await Task.sleep(for: .milliseconds(200))
        #expect(link.connectAttempts == 1)
    }
}
