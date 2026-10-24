import Foundation
import HUDCore
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

private struct LockedKeyStore: TeslaKeyStore {
    struct Locked: Error {}
    func clientKey() throws -> any KeyAgreementKey { throw Locked() }
    func pairedVIN() throws -> String? { throw Locked() }
    func setPairedVIN(_ vin: String) throws { throw Locked() }
    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? { throw Locked() }
    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws { throw Locked() }
}

private func ok(_ data: CarServer_VehicleData) -> Result<VehicleDataResponse, TeslaClientError> {
    .success(VehicleDataResponse(reading: VehicleReading(vehicleData: data), isEncrypted: true, roundTripMs: 150, retried: false))
}

private func timestamp(_ date: Date) -> Google_Protobuf_Timestamp {
    Google_Protobuf_Timestamp(date: date)
}

/// Waits up to about two seconds for `condition`.
@MainActor
private func eventually(_ condition: () -> Bool) async throws {
    for _ in 0..<200 where !condition() {
        try await Task.sleep(for: .milliseconds(10))
    }
    #expect(condition())
}

@Suite("Car events for the HUD", .serialized)
struct CarEventsTests {
    let received = Date(timeIntervalSinceReferenceDate: 800_000_000)
    let carTime = Date(timeIntervalSinceReferenceDate: 790_000_000)

    // MARK: Mapping TeslaBLE readings to HUDCore

    @Test func aPollMapsToACarReadingWithOnlyTheCategoriesThatCameBack() throws {
        var drive = CarServer_VehicleData()
        drive.driveState.speedFloat = 2.5
        drive.driveState.shiftState.r = CarServer_Void()
        drive.driveState.timestamp = timestamp(carTime)
        var charge = CarServer_VehicleData()
        charge.chargeState.batteryLevel = 72
        charge.chargeState.batteryRange = 195.7
        charge.chargeState.timestamp = timestamp(carTime - 1)
        let poll = VehicleDataPoll(entries: [.init(category: .charge, result: ok(charge)), .init(category: .drive, result: ok(drive))])

        let reading = try #require(CarReading(poll, receivedAt: received))
        #expect(reading.receivedAt == received)
        #expect(reading.carTimestamp == carTime)
        #expect(reading.speedMetersPerSecond == 2.5 * 0.44704)
        #expect(reading.gear == .reverse)
        #expect(reading.batteryPercent == 72)
        #expect(abs(try #require(reading.rangeKilometers) - 195.7 * 1.609344) < 0.001)
        #expect(reading.tires == nil)
    }

    @Test func tiresKeepPsiAndLastSeenPerWheel() throws {
        var data = CarServer_VehicleData()
        data.tirePressureState.tpmsPressureFl = 2.8
        data.tirePressureState.tpmsLastSeenPressureTimeFl = timestamp(carTime)
        data.tirePressureState.tpmsPressureRr = 2.85
        let poll = VehicleDataPoll(entries: [.init(category: .tirePressure, result: ok(data)),
                                             .init(category: .drive, result: .failure(.timeout(.getVehicleData)))])
        let reading = try #require(CarReading(poll, receivedAt: received))
        #expect(reading.speedMetersPerSecond == nil)
        #expect(reading.gear == nil)
        let tires = try #require(reading.tires)
        #expect(tires.frontLeft?.lastSeen == carTime)
        #expect(abs(try #require(tires.frontLeft?.psi) - 2.8 * TirePressure.psiPerBar) < 0.001)
        #expect(tires.frontRight == nil)
        #expect(tires.rearLeft == nil)
        #expect(tires.rearRight?.lastSeen == nil)
    }

    @Test func aPollWithNothingBackIsNoReading() {
        let poll = VehicleDataPoll(entries: [.init(category: .drive, result: .failure(.keyNotPaired))])
        #expect(CarReading(poll, receivedAt: received) == nil)
    }

    @Test func anUnknownGearIsNil() throws {
        var drive = CarServer_VehicleData()
        drive.driveState.speedFloat = 0
        let reading = try #require(CarReading(VehicleDataPoll(entries: [.init(category: .drive, result: ok(drive))]), receivedAt: received))
        #expect(reading.gear == nil)
        #expect(reading.carTimestamp == nil)
    }

    // MARK: No paired car: no Bluetooth prompt

    @Test func bluetoothStartsAtLaunchOnlyWithAPairedCar() throws {
        let unpaired = InMemoryKeyStore()
        #expect(!TeslaVehicleClient.activatesBluetoothAtLaunch(unpaired))
        let paired = InMemoryKeyStore()
        try paired.setPairedVIN(ProtocolDoc.vin)
        #expect(TeslaVehicleClient.activatesBluetoothAtLaunch(paired))
        // The Keychain cannot tell while locked: keep state restoration working.
        #expect(TeslaVehicleClient.activatesBluetoothAtLaunch(LockedKeyStore()))
    }

    // MARK: Through the car feed and the fake car

    @Test("a paired car: the drive screen connects by itself and shows the car's speed with ● 車輛藍牙")
    @MainActor func drivingScreenShowsTheCarSpeed() async throws {
        let keyStore = InMemoryKeyStore()
        try keyStore.setPairedVIN(ProtocolDoc.vin)
        let link = MockLink()
        let feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: .app))
        let model = HUDViewModel()
        model.handle(.authorization(.authorized))
        let run = Task { await model.run(car: feed.carEvents()) }
        defer { run.cancel() }

        try await eventually { model.state.source == .valid(.carBluetooth) }
        // The fake car reports 60.5 mph: 97.4 km/h.
        #expect(model.state.numeral == "97")
        #expect(model.state.gauge == .live(kilometersPerHour: 60.5 * 0.44704 * 3.6))
        #expect(await link.isConnected)
    }

    @Test("no paired car: GPS only, the feed never connects, and the chip stays ● GPS")
    @MainActor func notPairedIsGPSOnly() async throws {
        let link = MockLink()
        let feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: InMemoryKeyStore(), configuration: .app))
        let model = HUDViewModel()
        let run = Task { await model.run(car: feed.carEvents()) }
        defer { run.cancel() }
        model.handle(.authorization(.authorized))
        model.handle(.sample(GPSSample(speedMetersPerSecond: 20, horizontalAccuracyMeters: 5, timestamp: Date())))
        try await Task.sleep(for: .milliseconds(150))
        #expect(model.state.numeral == "72")
        #expect(model.state.source == .valid(.gps))
        #expect(await !link.isConnected)
        #expect(await link.writes.isEmpty)
    }

    @Test("the drive logger records from the same feed, while the drive screen shows its readings")
    @MainActor func loggerAndDriveScreenShareTheFeed() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "logger-\(UUID().uuidString)", directoryHint: .isDirectory)
        let suite = "CarEventsTests.\(UUID().uuidString)"
        defer {
            try? FileManager.default.removeItem(at: root)
            UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        }
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(ProtocolDoc.vin, forKey: "driveLogger.vin")
        let keyStore = InMemoryKeyStore()
        try keyStore.setPairedVIN(ProtocolDoc.vin)
        let link = MockLink()
        let feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: .app))
        let logger = DriveLogger(
            feed: feed, defaults: defaults,
            logsRoot: root.appending(path: "Logs", directoryHint: .isDirectory),
            diagnosticsRoot: root.appending(path: "Diagnostics", directoryHint: .isDirectory)
        )
        let model = HUDViewModel()
        let run = Task { await model.run(car: feed.carEvents()) }
        defer { run.cancel() }
        try await eventually { model.state.source == .valid(.carBluetooth) }

        logger.startRecording()
        try await eventually { logger.sampleCount >= 5 }
        await logger.stopRecording()
        // The screen kept its car speed, and polling goes on for it after the recording stops.
        #expect(model.state.source == .valid(.carBluetooth))
        let writes = await link.writes.count
        try await Task.sleep(for: .milliseconds(500))
        #expect(await link.writes.count > writes)
    }
}
