import Foundation
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

@Suite("Drive logger on the fake car", .serialized)
struct DriveLoggerFakeCarTests {
    @Test("through the car feed and the fake car, a charge reply and the drive reply after it land on one samples.csv row")
    @MainActor func chargeThenDriveIsOneRow() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
        let suite = "DriveLoggerFakeCarTests.\(UUID().uuidString)"
        defer {
            try? FileManager.default.removeItem(at: root)
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(ProtocolDoc.vin, forKey: "driveLogger.vin")
        let client = TeslaVehicleClient(link: MockLink(), keyStore: InMemoryKeyStore(), configuration: .app)
        let logger = DriveLogger(
            feed: CarFeed(client: client), defaults: defaults,
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory)
        )

        await logger.connect()
        #expect(logger.linkStatus == .connected)
        logger.startRecording()
        // Slots: drive; charge state, drive; tire pressure, drive; …
        for _ in 0..<500 where logger.sampleCount < 3 {
            try await Task.sleep(for: .milliseconds(10))
        }
        await logger.stopRecording()

        let folder = try #require(logger.lastFolder)
        let lines = try String(contentsOf: folder.appending(path: "samples.csv"), encoding: .utf8)
            .split(separator: "\n").map(String.init)
        let rows = lines.dropFirst().map { $0.components(separatedBy: ",") }
        try #require(rows.count >= 3)
        let column = { (key: String) in SampleCSV.columns.firstIndex { $0.key == key }! }

        // The first slot asks drive state only.
        let first = rows[0]
        #expect(first[column("charge_response_ms")].isEmpty)
        #expect(first[column("battery_level_pct")].isEmpty)
        #expect(first[column("speed_float_raw")] == "60.5")

        // The next slot's charge reply and drive reply share one row.
        let rowsWithCharge = rows.filter { !$0[column("charge_response_ms")].isEmpty }
        #expect(rowsWithCharge.count == 1)
        let row = try #require(rowsWithCharge.first)
        #expect(!row[column("drive_response_ms")].isEmpty)
        #expect(row[column("error")].isEmpty)
        #expect(row[column("charge_error")].isEmpty)
        #expect(row[column("drive_error")].isEmpty)
        #expect(row[column("battery_level_pct")] == "72")
        #expect(row[column("speed_float_raw")] == "60.5")
        #expect(row[column("encrypted")] == LogFormat.bool(true))
    }
}
