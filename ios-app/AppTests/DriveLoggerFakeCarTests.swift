import Foundation
import HUDCore
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

    // #97: the fake car's low-tire switch (`FakeVehicle.lowTire`), so later tests can show a low tire.
    @Test("with the fake car warning about a tire, the recorded tire reply carries the warning")
    @MainActor func fakeCarSendsALowTire() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
        let suite = "DriveLoggerFakeCarTests.\(UUID().uuidString)"
        defer {
            try? FileManager.default.removeItem(at: root)
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(ProtocolDoc.vin, forKey: "driveLogger.vin")
        var vehicle = FakeVehicle()
        vehicle.lowTire = true
        let client = TeslaVehicleClient(link: MockLink(vehicle: vehicle), keyStore: InMemoryKeyStore(), configuration: .app)
        let logger = DriveLogger(
            feed: CarFeed(client: client, cadence: CarFeed.Cadence(slowInterval: .milliseconds(200))), defaults: defaults,
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory)
        )

        await logger.connect()
        logger.startRecording()
        for _ in 0..<500 where logger.lastSample?.poll?.response(for: .tirePressure) == nil {
            try await Task.sleep(for: .milliseconds(10))
        }
        await logger.stopRecording()

        let poll = try #require(logger.lastSample?.poll)
        let reply = try #require(poll.response(for: .tirePressure)?.reading)
        #expect(reply.tpmsHardWarningFrontLeft == true)
        let tires = try #require(CarReading(poll, receivedAt: Date())?.tires)
        #expect(tires.frontLeftLow)
        #expect(!tires.frontRightLow && !tires.rearLeftLow && !tires.rearRightLow)
    }

    @Test("the page shows the paired car; with its VIN field empty, 連線 connects to it and pairs nothing new")
    @MainActor func connectsToThePairedCar() async throws {
        let suite = "DriveLoggerFakeCarTests.\(UUID().uuidString)"
        let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer {
            try? FileManager.default.removeItem(at: root)
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        let defaults = try #require(UserDefaults(suiteName: suite))
        let keyStore = InMemoryKeyStore()
        try keyStore.setPairedVIN(ProtocolDoc.vin)
        let link = MockLink()
        let logger = DriveLogger(
            feed: CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: .app)), defaults: defaults,
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory)
        )
        #expect(logger.vin.isEmpty)
        await logger.refreshPairedVIN()
        #expect(logger.pairedVIN == ProtocolDoc.vin)
        #expect(logger.isVINValid)

        await logger.connect()
        #expect(logger.linkStatus == .connected)
        #expect(logger.vin.isEmpty)
        await logger.enrollKey()
        #expect(logger.enrollmentOutcome == .alreadyEnrolled)
        #expect(try keyStore.pairedVIN() == ProtocolDoc.vin)
    }
}
