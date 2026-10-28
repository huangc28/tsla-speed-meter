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

    // #77: the route is drive state; a drive reply without a destination says no route is set, and
    // a poll without drive state says nothing about it.
    @Test func theRouteComesWithDriveState() throws {
        var drive = CarServer_VehicleData()
        drive.driveState.speedFloat = 43.5
        drive.driveState.shiftState.d = CarServer_Void()
        drive.driveState.timestamp = .init(date: carTime)
        drive.driveState.activeRouteDestination = "台北車站"
        drive.driveState.activeRouteMinutesToArrival = 17.6
        drive.driveState.activeRouteMilesToArrival = 7.5
        drive.driveState.activeRouteEnergyAtArrival = 64
        let reading = try #require(CarReading(VehicleDataPoll(entries: [.init(category: .drive, result: ok(drive))]), receivedAt: received))
        guard case .route(let route)? = reading.navigation else {
            Issue.record("no route: \(String(describing: reading.navigation))")
            return
        }
        #expect(route.destination == "台北車站")
        #expect(abs(try #require(route.minutesToArrival) - 17.6) < 0.001)
        #expect(abs(try #require(route.kilometersToArrival) - 7.5 * 1.609344) < 0.001)
        #expect(route.energyAtArrival == 64)

        drive.driveState.optionalActiveRouteDestination = nil
        let ended = try #require(CarReading(VehicleDataPoll(entries: [.init(category: .drive, result: ok(drive))]), receivedAt: received))
        #expect(ended.navigation == .noRoute)

        var charge = CarServer_VehicleData()
        charge.chargeState.batteryLevel = 72
        let chargeOnly = try #require(CarReading(VehicleDataPoll(entries: [.init(category: .charge, result: ok(charge))]), receivedAt: received))
        #expect(chargeOnly.navigation == nil)
    }

    // #78: the doors and trunks keep presence, with the closures' own car time; a slot whose drive
    // request failed takes the closures' time as the reading's.
    @Test func closuresKeepPresenceAndTheirTime() throws {
        var data = CarServer_VehicleData()
        data.closuresState.doorOpenDriverFront = false
        data.closuresState.doorOpenPassengerRear = true
        data.closuresState.doorOpenTrunkRear = false
        data.closuresState.timestamp = .init(date: carTime)
        let poll = VehicleDataPoll(entries: [.init(category: .closures, result: ok(data)),
                                             .init(category: .drive, result: .failure(.timeout(.getVehicleData)))])
        let reading = try #require(CarReading(poll, receivedAt: received))
        #expect(reading.carTimestamp == carTime)
        let closures = try #require(reading.closures)
        #expect(closures.frontTrunk == nil)
        #expect(closures.rearTrunk == false)
        #expect(closures.doors == [false, nil, nil, true])
        #expect(closures.carTime == carTime)
        #expect(reading.tires == nil && reading.speedMetersPerSecond == nil)
    }

    // #79: the windows keep presence like the doors; climate comes as °C, and the odometer from drive
    // state in km.
    @Test func windowsClimateAndOdometer() throws {
        var closures = CarServer_VehicleData()
        closures.closuresState.windowOpenDriverRear = true
        closures.closuresState.windowOpenPassengerFront = false
        var climate = CarServer_VehicleData()
        climate.climateState.outsideTempCelsius = 23.5
        climate.climateState.timestamp = .init(date: carTime)
        var drive = CarServer_VehicleData()
        drive.driveState.odometerInHundredthsOfAMile = 767_100
        drive.driveState.timestamp = .init(date: carTime)
        let poll = VehicleDataPoll(entries: [.init(category: .closures, result: ok(closures)),
                                             .init(category: .drive, result: ok(drive))])
        let reading = try #require(CarReading(poll, receivedAt: received))
        #expect(reading.closures?.windows == [nil, true, false, nil])
        #expect(abs((reading.odometerKilometers ?? 0) - 12_345.27) < 0.01)
        #expect(reading.climate == nil)

        // A climate slot whose drive request failed takes the climate's time as the reading's.
        let climatePoll = VehicleDataPoll(entries: [.init(category: .climate, result: ok(climate)),
                                                    .init(category: .drive, result: .failure(.timeout(.getVehicleData)))])
        let climateReading = try #require(CarReading(climatePoll, receivedAt: received))
        #expect(climateReading.climate == CarClimate(outsideCelsius: 23.5, insideCelsius: nil))
        #expect(climateReading.carTimestamp == carTime)
        #expect(climateReading.odometerKilometers == nil)
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

    // The fake car's replies all carry one drive-state time, so its gear row never shows here;
    // the engine tests cover the row going idle.
    @Test("a requested disconnect (斷線, a cancelled pairing): the battery block hides at once")
    @MainActor func aRequestedDisconnectHidesTheBatteryBlock() async throws {
        let keyStore = InMemoryKeyStore()
        try keyStore.setPairedVIN(ProtocolDoc.vin)
        let link = MockLink()
        // Charge state at once, not 10 s in.
        let feed = CarFeed(client: TeslaVehicleClient(link: link, keyStore: keyStore, configuration: .app),
                           cadence: CarFeed.Cadence(slowInterval: .milliseconds(200)))
        let model = HUDViewModel()
        model.handle(.authorization(.authorized))
        let run = Task { await model.run(car: feed.carEvents()) }
        defer { run.cancel() }
        try await eventually {
            if case .value = model.state.battery { true } else { false }
        }

        await feed.disconnect()
        try await eventually { model.state.battery == nil }
        #expect(await feed.linkStatus == .idle)
        // A reply of the slot that was in flight never brings it back.
        try await Task.sleep(for: .milliseconds(600))
        #expect(model.state.battery == nil)
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
