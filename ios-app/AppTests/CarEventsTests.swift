import Foundation
import HUDCore
import Security
import Testing
import TeslaBLE
import TeslaBLETestSupport
@testable import SpeedHUD

/// A key store whose every call throws `error`.
private struct FailingKeyStore: TeslaKeyStore {
    struct Other: Error {}
    let error: any Error
    func clientKey() throws -> any KeyAgreementKey { throw error }
    func pairedVIN() throws -> String? { throw error }
    func setPairedVIN(_ vin: String) throws { throw error }
    func vehiclePublicKey(vin: String, domain: UniversalMessage_Domain) throws -> Data? { throw error }
    func setVehiclePublicKey(_ key: Data, vin: String, domain: UniversalMessage_Domain) throws { throw error }
}

/// Records the order in which the feed is suspended and resumed; suspending takes a while.
private actor PhaseRecorder: CarFeedPhaseTarget {
    private(set) var calls: [String] = []
    func suspend() async {
        try? await Task.sleep(for: .milliseconds(100))
        calls.append("suspend")
    }
    func resume() {
        calls.append("resume")
    }
}

private func ok(_ data: CarServer_VehicleData) -> Result<VehicleDataResponse, TeslaClientError> {
    .success(VehicleDataResponse(reading: VehicleReading(vehicleData: data), isEncrypted: true, roundTripMs: 150, retried: false))
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
        drive.driveState.timestamp = .init(date: carTime)
        var charge = CarServer_VehicleData()
        charge.chargeState.batteryLevel = 72
        charge.chargeState.batteryRange = 195.7
        charge.chargeState.timestamp = .init(date: carTime - 1)
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

    // L7: a speed is shown only with the car's own time for it.
    @Test func aDriveReplyWithoutItsTimeNeverBorrowsTheChargeTime() throws {
        var drive = CarServer_VehicleData()
        drive.driveState.speedFloat = 20
        var charge = CarServer_VehicleData()
        charge.chargeState.batteryLevel = 72
        charge.chargeState.timestamp = .init(date: carTime)
        let poll = VehicleDataPoll(entries: [.init(category: .charge, result: ok(charge)), .init(category: .drive, result: ok(drive))])
        let reading = try #require(CarReading(poll, receivedAt: received))
        #expect(reading.carTimestamp == nil)
        #expect(reading.batteryPercent == 72)
    }

    @Test func tiresKeepPsiAndLastSeenPerWheel() throws {
        var data = CarServer_VehicleData()
        data.tirePressureState.tpmsPressureFl = 2.8
        data.tirePressureState.tpmsLastSeenPressureTimeFl = .init(date: carTime)
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

    // MARK: The view model

    @Test("a car speed turns into — once it is 2 s old, with no location stream running")
    @MainActor func carSpeedExpiresOnTheCarRunsTick() async throws {
        let clock = TestClock()
        let model = HUDViewModel(now: { clock.now })
        let (events, continuation) = AsyncStream.makeStream(of: CarEvent.self)
        let run = Task { await model.run(car: events, tick: .milliseconds(20)) }
        defer { run.cancel() }
        continuation.yield(.reading(CarReading(receivedAt: clock.now, carTimestamp: carTime, speedMetersPerSecond: 20)))
        try await eventually { model.state.numeral == "72" }
        #expect(model.state.source == .valid(.carBluetooth))

        clock.advance(2.5)
        try await eventually { model.state.numeral == "—" }
        #expect(model.state.source == .speedUnavailable)
    }

    // MARK: No paired car: no Bluetooth prompt

    @Test func bluetoothStartsAtLaunchOnlyWithAPairedCar() throws {
        let unpaired = InMemoryKeyStore()
        #expect(!TeslaVehicleClient.activatesBluetoothAtLaunch(unpaired))
        let paired = InMemoryKeyStore()
        try paired.setPairedVIN(ProtocolDoc.vin)
        #expect(TeslaVehicleClient.activatesBluetoothAtLaunch(paired))
        // The Keychain cannot tell while the phone is locked: keep state restoration working.
        let locked = FailingKeyStore(error: KeychainTeslaKeyStore.Error.unexpectedStatus(errSecInteractionNotAllowed))
        #expect(TeslaVehicleClient.activatesBluetoothAtLaunch(locked))
        // Any other error: a never-paired phone must not get a Bluetooth prompt.
        let broken = FailingKeyStore(error: KeychainTeslaKeyStore.Error.unexpectedStatus(errSecMissingEntitlement))
        #expect(!TeslaVehicleClient.activatesBluetoothAtLaunch(broken))
        #expect(!TeslaVehicleClient.activatesBluetoothAtLaunch(FailingKeyStore(error: FailingKeyStore.Other())))
    }

    @Test("phase changes reach the feed in order, even when suspending takes a while")
    @MainActor func phaseChangesStayInOrder() async throws {
        let recorder = PhaseRecorder()
        let phase = CarFeedPhase(feed: recorder)
        phase.apply(.background)
        phase.apply(.active)
        phase.apply(.background)
        phase.apply(.active)
        for _ in 0..<100 where await recorder.calls.count < 4 {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(await recorder.calls == ["suspend", "resume", "suspend", "resume"])
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

    @Test("background then front again at once: the feed ends up resumed, connected and polling")
    @MainActor func quickBackgroundAndBack() async throws {
        let keyStore = InMemoryKeyStore()
        try keyStore.setPairedVIN(ProtocolDoc.vin)
        let link = MockLink()
        let feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: .app))
        let model = HUDViewModel()
        let run = Task { await model.run(car: feed.carEvents()) }
        defer { run.cancel() }
        try await eventually { model.state.source == .valid(.carBluetooth) }

        let phase = CarFeedPhase(feed: feed)
        phase.apply(.background)
        phase.apply(.active)
        let writes = await link.writes.count
        var polling = false
        for _ in 0..<200 where !polling {
            try await Task.sleep(for: .milliseconds(10))
            let (disconnects, connected, sent) = await (link.disconnectCalls, link.isConnected, link.writes.count)
            polling = disconnects == 1 && connected && sent > writes + 10
        }
        #expect(polling)
        #expect(await feed.linkStatus == .connected)
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
