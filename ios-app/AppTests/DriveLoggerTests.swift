import CoreLocation
import Foundation
import SwiftProtobuf
import Testing
import TeslaBLE
@testable import SpeedHUD

private func cells(_ line: String) -> [String] {
    // Test rows hold no quoted cells.
    line.trimmingCharacters(in: .newlines).components(separatedBy: ",")
}

private func cell(_ key: String, in row: String) -> String {
    let index = SampleCSV.columns.firstIndex { $0.key == key }!
    return cells(row)[index]
}

/// Reversing at 3.5 mph: speed sign kept, gear R, front-left tire only.
private func reversingReading() -> VehicleReading {
    var data = CarServer_VehicleData()
    data.driveState.speedFloat = -3.5
    data.driveState.shiftState.r = CarServer_Void()
    data.driveState.power = 4
    data.chargeState.batteryLevel = 80
    data.chargeState.chargingState.disconnected = CarServer_Void()
    data.tirePressureState.tpmsPressureFl = 2.9
    data.tirePressureState.tpmsLastSeenPressureTimeFl = Google_Protobuf_Timestamp(seconds: 1_790_000_000)
    return VehicleReading(vehicleData: data)
}

@Suite("Drive log formatting")
struct LogFormatTests {
    @Test("missing values are empty cells, never 0")
    func nilIsEmpty() {
        #expect(LogFormat.raw(nil) == "")
        #expect(LogFormat.int(Int32?.none) == "")
        #expect(LogFormat.decimal(nil, places: 2) == "")
        #expect(LogFormat.bool(nil) == "")
        #expect(LogFormat.iso(nil) == "")
        #expect(LogFormat.raw(0) == "0.0")
        #expect(LogFormat.raw(-3.5) == "-3.5")
    }

    @Test("CSV cells with commas, quotes or line breaks are quoted")
    func quoting() {
        #expect(LogFormat.csvCell("plain") == "plain")
        #expect(LogFormat.csvCell("a,b") == "\"a,b\"")
        #expect(LogFormat.csvCell("say \"hi\"") == "\"say \"\"hi\"\"\"")
        #expect(LogFormat.csvLine(["1", "", "x\ny"]) == "1,,\"x\ny\"\n")
    }

    @Test("ISO time has milliseconds and an offset")
    func isoTime() {
        let text = LogFormat.iso(Date(timeIntervalSince1970: 1_790_000_000.5))
        #expect(text.contains(".500"))
        #expect(text.wholeMatch(of: /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[+-]\d{2}:?\d{2})/) != nil)
    }

    @Test("the VIN is masked except its last six characters")
    func maskedVIN() {
        #expect(LogFormat.maskedVIN("5YJ3E1EA0KF123456") == "***********123456")
        #expect(LogFormat.maskedVIN("ABC") == "ABC")
    }
}

@Suite("samples.csv")
struct SampleCSVTests {
    @Test("header and rows have the same number of cells")
    func columnCount() {
        let sample = Sample(phoneTime: Date(), monotonicMs: 5, response: nil, error: "timeout(getVehicleData)", gps: nil)
        #expect(cells(SampleCSV.header).count == SampleCSV.columns.count)
        #expect(cells(SampleCSV.row(sample)).count == SampleCSV.columns.count)
        #expect(Set(SampleCSV.columns.map(\.key)).count == SampleCSV.columns.count)
    }

    @Test("an error row has only the time, error and GPS cells filled")
    func errorRow() {
        let fix = GPSFix(timestamp: Date(timeIntervalSince1970: 100), speed: 1.5, speedAccuracy: 0.4, horizontalAccuracy: 6)
        let sample = Sample(phoneTime: Date(timeIntervalSince1970: 100.25), monotonicMs: 1234, response: nil, error: "timeout(getVehicleData)", gps: fix)
        let row = SampleCSV.row(sample)
        let filled = Set(zip(SampleCSV.columns.map(\.key), cells(row)).filter { !$0.1.isEmpty }.map(\.0))
        #expect(filled == [
            "phone_time", "monotonic_ms", "error",
            "gps_speed_mps", "gps_speed_kmh", "gps_speed_accuracy_mps", "gps_horizontal_accuracy_m", "gps_fix_age_ms",
        ])
        #expect(cell("gps_fix_age_ms", in: row) == "250")
        #expect(cell("gps_speed_kmh", in: row) == "5.40")
        #expect(!cells(row).contains("0"))
    }

    @Test("a reading keeps raw values next to converted ones, absent fields empty")
    func readingRow() {
        let response = VehicleDataResponse(reading: reversingReading(), isEncrypted: true, roundTripMs: 87, retried: false)
        let row = SampleCSV.row(Sample(phoneTime: Date(), monotonicMs: 10, response: response, error: nil, gps: nil))
        #expect(cell("response_ms", in: row) == "87")
        #expect(cell("encrypted", in: row) == "true")
        #expect(cell("error", in: row) == "")
        #expect(cell("speed_float_raw", in: row) == "-3.5")
        #expect(cell("speed_raw", in: row) == "")
        #expect(cell("speed_mps", in: row) == "-1.565")
        #expect(cell("shift_state_raw", in: row) == "R")
        #expect(cell("gear", in: row) == "R")
        #expect(cell("drive_power_kw", in: row) == "4")
        #expect(cell("battery_level_pct", in: row) == "80")
        #expect(cell("battery_range_mi", in: row) == "")
        #expect(cell("battery_range_km", in: row) == "")
        #expect(cell("charging_state_raw", in: row) == "Disconnected")
        #expect(cell("charging_state", in: row) == "disconnected")
        #expect(cell("charger_power_kw", in: row) == "")
        #expect(cell("tpms_fl_bar", in: row) == "2.9")
        #expect(cell("tpms_fl_psi", in: row) == "42.06")
        #expect(!cell("tpms_fl_last_seen", in: row).isEmpty)
        #expect(cell("tpms_fr_bar", in: row) == "")
        #expect(cell("tpms_fr_psi", in: row) == "")
        #expect(cell("gps_speed_mps", in: row) == "")
    }

    @Test("an absent shift state is empty; a present one without a value is unset")
    func shiftRaw() {
        #expect(SampleCSV.shiftRaw(nil) == "")
        #expect(SampleCSV.shiftRaw(CarServer_ShiftState()) == "unset")
        #expect(SampleCSV.gear(.unknown, present: false) == "")
    }
}

@Suite("GPS logging")
struct GPSLoggingTests {
    private static let location = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: 25.033964, longitude: 121.564468),
        altitude: 12.5, horizontalAccuracy: 4.2, verticalAccuracy: 3,
        course: 87, courseAccuracy: 5, speed: 13.9, speedAccuracy: 0.6,
        timestamp: Date(timeIntervalSince1970: 1_790_000_000)
    )

    @Test("a fix keeps speed and accuracy, and no coordinates reach either CSV")
    func noCoordinates() {
        let fix = GPSFix(Self.location)
        #expect(fix.speed == 13.9)
        #expect(fix.speedAccuracy == 0.6)
        #expect(fix.horizontalAccuracy == 4.2)

        let receivedAt = Self.location.timestamp.addingTimeInterval(0.3)
        let gpsRow = GPSCSV.row(fix, receivedAt: receivedAt, monotonicMs: 42)
        let sampleRow = SampleCSV.row(Sample(phoneTime: receivedAt, monotonicMs: 42, response: nil, error: "x", gps: fix))
        for text in [GPSCSV.header, gpsRow, SampleCSV.header, sampleRow] {
            #expect(!text.contains("25.03"))
            #expect(!text.contains("121.5"))
            #expect(!text.lowercased().contains("lat"))
            #expect(!text.lowercased().contains("lon"))
        }
        #expect(cells(gpsRow)[3] == "300")
        #expect(cells(gpsRow)[4] == "13.900")
    }

    @Test("invalid speed and accuracy (negative in CoreLocation) are empty")
    func invalidSpeed() {
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2),
            altitude: 0, horizontalAccuracy: 10, verticalAccuracy: -1,
            course: -1, courseAccuracy: -1, speed: -1, speedAccuracy: -1,
            timestamp: Date()
        )
        let fix = GPSFix(location)
        #expect(fix.speed == nil)
        #expect(fix.speedAccuracy == nil)
        let row = cells(GPSCSV.row(fix, receivedAt: Date(), monotonicMs: 0))
        #expect(row[4] == "" && row[5] == "" && row[6] == "")
    }
}

@Suite("Log session files", .serialized)
struct LogSessionTests {
    private static func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "logs-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    @Test("creates Logs/<time>/ with the five files, headers first")
    func layout() throws {
        let root = Self.temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        let session = try LogSession(root: root, startedAt: start, meta: ["vin_masked": "***********123456"])

        #expect(session.directory.deletingLastPathComponent().standardizedFileURL == root.standardizedFileURL)
        #expect(session.directory.lastPathComponent == LogSession.folderName(for: start))
        #expect(session.directory.lastPathComponent.wholeMatch(of: /\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}/) != nil)
        let names = try FileManager.default.contentsOfDirectory(atPath: session.directory.path()).sorted()
        #expect(names == LogSession.fileNames.sorted())
        #expect(try String(contentsOf: session.directory.appending(path: "samples.csv"), encoding: .utf8) == SampleCSV.header)
        #expect(try String(contentsOf: session.directory.appending(path: "gps.csv"), encoding: .utf8) == GPSCSV.header)
    }

    @Test("writes one line per sample, fix, event and frame; meta gets the counts")
    func writes() throws {
        let root = Self.temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let session = try LogSession(root: root, meta: ["vin_masked": "***********123456"])
        session.write(sample: Sample(phoneTime: Date(), monotonicMs: 1, response: nil, error: "timeout(getVehicleData)", gps: nil))
        session.write(gps: GPSFix(timestamp: Date(), speed: 2, speedAccuracy: 0.5, horizontalAccuracy: 5), receivedAt: Date())
        session.write(event: EventJSON.fields(.handshakeSucceeded(.infotainment, durationMs: 120))!, phoneTime: Date())
        session.write(frame: Data([0x0a, 0xff]), sent: true, phoneTime: Date())
        session.write(frame: Data([0x01]), sent: false, phoneTime: Date())
        session.finish()

        func lines(_ name: String) throws -> [String] {
            try String(contentsOf: session.directory.appending(path: name), encoding: .utf8)
                .split(separator: "\n").map(String.init)
        }
        #expect(try lines("samples.csv").count == 2)
        #expect(try lines("gps.csv").count == 2)
        let events = try lines("events.jsonl")
        #expect(events.count == 1)
        let event = try JSONSerialization.jsonObject(with: Data(events[0].utf8)) as? [String: Any]
        #expect(event?["type"] as? String == "handshake_succeeded")
        #expect(event?["domain"] as? String == "infotainment")
        #expect(event?["duration_ms"] as? Int == 120)
        #expect(event?["phone_time"] is String)
        #expect(event?["monotonic_ms"] is Int)
        let frames = try lines("frames.txt")
        #expect(frames.count == 3)
        #expect(frames[1].hasSuffix(" TX 0aff"))
        #expect(frames[2].hasSuffix(" RX 01"))

        let meta = try JSONSerialization.jsonObject(with: Data(contentsOf: session.directory.appending(path: "meta.json"))) as? [String: Any]
        #expect(meta?["vin_masked"] as? String == "***********123456")
        #expect(meta?["sample_count"] as? Int == 1)
        #expect(meta?["error_count"] as? Int == 1)
        #expect(meta?["frame_count"] as? Int == 2)
        #expect(meta?["started_at"] is String)
        #expect(meta?["stopped_at"] is String)
    }

    @Test("two sessions started in the same second get separate folders")
    func sameSecond() throws {
        let root = Self.temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let start = Date()
        let first = try LogSession(root: root, startedAt: start, meta: [:])
        let second = try LogSession(root: root, startedAt: start, meta: [:])
        #expect(first.directory != second.directory)
        #expect(second.directory.lastPathComponent.hasSuffix("-2"))
    }

    @Test("raw frames are not written to events.jsonl")
    func framesNotEvents() {
        #expect(EventJSON.fields(.frameSent(Data([1]))) == nil)
        #expect(EventJSON.fields(.frameReceived(Data([1]))) == nil)
        #expect(EventJSON.fields(.disconnected(reconnecting: true, reason: nil))?["reconnecting"] as? Bool == true)
    }

    @Test("the folder zips for export")
    @MainActor func zips() throws {
        let root = Self.temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let session = try LogSession(root: root, meta: [:])
        session.finish()
        let zip = try #require(DriveLogger.zip(session.directory))
        defer { try? FileManager.default.removeItem(at: zip) }
        let bytes = try Data(contentsOf: zip)
        #expect(bytes.prefix(2) == Data("PK".utf8))
    }
}

@Suite("Polling loop")
struct PollerTests {
    @MainActor private final class Probe {
        var active = 0
        var maxActive = 0
        var calls = 0
        var starts: [ContinuousClock.Instant] = []

        func tick(work: Duration) async {
            calls += 1
            starts.append(.now)
            active += 1
            maxActive = max(maxActive, active)
            try? await Task.sleep(for: work)
            active -= 1
        }
    }

    @Test("calls never overlap, even when a call takes longer than the interval")
    @MainActor func neverOverlaps() async throws {
        let probe = Probe()
        let task = Task { @MainActor in
            await Poller.run(every: .milliseconds(10)) {
                await probe.tick(work: .milliseconds(probe.calls.isMultiple(of: 2) ? 25 : 2))
            }
        }
        try await Task.sleep(for: .milliseconds(250))
        task.cancel()
        await task.value
        #expect(probe.calls >= 5)
        #expect(probe.maxActive == 1)
        #expect(probe.active == 0)
    }

    @Test("waits the interval between call starts")
    @MainActor func keepsInterval() async throws {
        let probe = Probe()
        let task = Task { @MainActor in
            await Poller.run(every: .milliseconds(40)) { await probe.tick(work: .zero) }
        }
        try await Task.sleep(for: .milliseconds(230))
        task.cancel()
        await task.value
        let gaps = zip(probe.starts, probe.starts.dropFirst()).map { $1 - $0 }
        #expect(!gaps.isEmpty)
        #expect(gaps.allSatisfy { $0 >= .milliseconds(38) })
    }

    @Test("stopping lets the call in progress finish, and no call starts afterwards")
    @MainActor func stopsCleanly() async throws {
        let probe = Probe()
        let task = Task { @MainActor in
            await Poller.run(every: .milliseconds(5)) { await probe.tick(work: .milliseconds(30)) }
        }
        try await Task.sleep(for: .milliseconds(10))
        task.cancel()
        await task.value
        let callsAtStop = probe.calls
        #expect(probe.active == 0)
        try await Task.sleep(for: .milliseconds(60))
        #expect(probe.calls == callsAtStop)
    }
}
