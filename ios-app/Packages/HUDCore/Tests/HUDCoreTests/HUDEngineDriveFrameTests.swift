import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

private let taipei = CarRoute(destination: "台北車站", minutesToArrival: 17.6, kilometersToArrival: 12.3, energyAtArrival: 64.3)

/// A drive reply that reached the phone at `t0 + seconds`, with the car's navigation, tires and odometer, if any.
private func drive(_ gear: CarGear = .drive, kmh: Double = 60, navigation: CarNavigation? = nil, tires: CarTires? = nil,
                   odometer: Int? = nil, at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, speedMetersPerSecond: kmh / 3.6,
                        gear: gear, tires: tires, navigation: navigation, odometerHundredthsOfAMile: odometer))
}

private let fourTires = CarTires(frontLeft: CarTire(psi: 42, lastSeen: nil), frontRight: CarTire(psi: 41, lastSeen: nil),
                                 rearLeft: CarTire(psi: 31, lastSeen: nil), rearRight: CarTire(psi: 42, lastSeen: nil),
                                 rearLeftLow: true)

/// #100: the drive screen's frame gets the tires (the right column), the odometer (the footer's ODO) and its
/// left card, navigation while it is shown (L73 Q11), otherwise the trip (owner decision 1, #96).
struct HUDEngineDriveFrameTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func state(_ engine: HUDEngine, at seconds: TimeInterval, unit: SpeedUnit = .kilometersPerHour) -> HUDState {
        engine.state(at: t0 + seconds, unit: unit)
    }

    // MARK: Tires

    @Test func theDriveScreenGetsTheWheels() throws {
        var engine = authorized()
        handle(&engine, drive(tires: fourTires, at: 0), at: 0)
        let driving = state(engine, at: 0)
        #expect(driving.layout == .drive)
        guard case .wheels(let wheels) = driving.tires else { Issue.record("no wheels: \(String(describing: driving.tires))"); return }
        #expect(wheels.all.map(\.psi) == [42, 41, 31, 42])
        #expect(wheels.all.map(\.isLow) == [false, false, true, false])
    }

    // Before any tire reply: four dashes.
    @Test func beforeAnyTireReplyFourDashes() {
        var engine = authorized()
        handle(&engine, drive(at: 0), at: 0)
        #expect(state(engine, at: 0).tires == .wheels(.noReadings))
    }

    // With no car data the column hides: GPS only, a link gone idle, a link lost for more than 10 s.
    @Test func noWheelsWithoutCarData() {
        var gpsOnly = authorized()
        gpsOnly.handle(.sample(fix(80 / 3.6, at: 0)), now: t0)
        #expect(state(gpsOnly, at: 0).tires == nil)

        var idle = authorized()
        handle(&idle, drive(tires: fourTires, at: 0), at: 0)
        handle(&idle, .link(.idle), at: 0.1)
        #expect(state(idle, at: 0.1).tires == nil)

        var lost = authorized()
        handle(&lost, drive(tires: fourTires, at: 0), at: 0)
        handle(&lost, .link(.lost), at: 0.1)
        #expect(state(lost, at: 10).tires != nil)
        #expect(state(lost, at: 10.2).tires == nil)
    }

    // MARK: Odometer

    @Test func theOdometerInTheUsersUnit() {
        var engine = authorized()
        handle(&engine, drive(odometer: 2_995_877, at: 0), at: 0)
        // 29,958.77 mi: whole miles straight from the car, or km rounded down, as 車況 does.
        #expect(state(engine, at: 0).odometer == .value(48_213))
        #expect(state(engine, at: 0, unit: .milesPerHour).odometer == .value(29_958))
        #expect(state(engine, at: 0).layout == .drive)
    }

    @Test func aDashBeforeTheFirstOdometer() {
        var engine = authorized()
        handle(&engine, drive(at: 0), at: 0)
        #expect(state(engine, at: 0).odometer == .waiting)
        // A reply without it keeps the last one.
        handle(&engine, drive(odometer: 2_995_877, at: 0.2), at: 0.2)
        handle(&engine, drive(at: 0.4), at: 0.4)
        #expect(state(engine, at: 0.4).odometer == .value(48_213))
    }

    @Test func parkedHasTheOdometerToo() {
        var engine = authorized()
        handle(&engine, drive(.park, kmh: 0, odometer: 2_995_877, at: 0), at: 0)
        handle(&engine, drive(.park, kmh: 0, at: 0.2), at: 0.2)
        #expect(state(engine, at: 0.2).layout == .parked)
        #expect(state(engine, at: 0.2).odometer == .value(48_213))
    }

    @Test func noOdometerOnGPSOnly() {
        var engine = authorized()
        engine.handle(.sample(fix(80 / 3.6, at: 0)), now: t0)
        #expect(state(engine, at: 0).odometer == nil)
    }

    // MARK: Left card

    // A route switches the left card from the trip to navigation once (Q11); a route known to have ended
    // leaves the trip.
    @Test func navigationShowsOnTheLeftOtherwiseTheTrip() throws {
        var engine = authorized()
        handle(&engine, drive(navigation: .noRoute, at: 0), at: 0)
        handle(&engine, drive(navigation: .noRoute, at: 0.2), at: 0.2)
        let tripOnly = state(engine, at: 0.2)
        let trip = try #require(tripOnly.trip)
        #expect(tripOnly.driveLeftCard == .trip(trip))

        handle(&engine, drive(navigation: .route(taipei), at: 0.4), at: 0.4)
        let navigating = state(engine, at: 0.4)
        #expect(navigating.navigationSwitches == 1)
        #expect(navigating.driveLeftCard == .navigation(.route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 12,
                                                                                arrivalPercent: 64))))

        // Ended: the trip again, in the same card.
        handle(&engine, drive(navigation: .noRoute, at: 0.6), at: 0.6)
        let ended = state(engine, at: 0.6)
        #expect(ended.navigation == .ended)
        #expect(ended.driveLeftCard == ended.trip.map(DriveLeftCard.trip))

        // No fresh reply on Car Bluetooth: the stale pin stays on the left.
        let stale = state(engine, at: 3)
        #expect(stale.navigation == .stale)
        #expect(stale.driveLeftCard == .navigation(.stale))
    }

    @Test func parkedHasNoDriveLeftCard() {
        var engine = authorized()
        handle(&engine, drive(.park, kmh: 0, at: 0), at: 0)
        handle(&engine, drive(.park, kmh: 0, at: 0.2), at: 0.2)
        #expect(state(engine, at: 0.2).layout == .parked)
        #expect(state(engine, at: 0.2).driveLeftCard == nil)
    }

    // MARK: GPS fallback mid-drive (#93)

    // About once a minute a drive request times out and GPS supplies the speed for about 3 s. The right
    // column and the footer's car data hide with the battery and the icons (`showsCarData`), with no new hold;
    // navigation hides with them (L84-4: no pin on GPS fallback), so the left card shows the trip; all come back
    // with the car's speed.
    @Test func carDataThenGPSFallbackThenCarData() throws {
        var engine = authorized()
        handle(&engine, drive(navigation: .route(taipei), tires: fourTires, odometer: 2_995_877, at: 0), at: 0)
        handle(&engine, drive(navigation: .route(taipei), at: 0.2), at: 0.2)
        let car = state(engine, at: 0.2)
        #expect(car.source == .valid(.carBluetooth))
        #expect(car.tires != nil && car.odometer == .value(48_213) && car.battery != nil)
        guard case .navigation(.route)? = car.driveLeftCard else { Issue.record("\(String(describing: car.driveLeftCard))"); return }

        engine.handle(.sample(fix(60 / 3.6, at: 2.0)), now: t0 + 2.0)
        let fallback = state(engine, at: 2.3)
        #expect(fallback.source == .gpsFallback)
        #expect(fallback.tires == nil)
        #expect(fallback.odometer == nil)
        #expect(fallback.battery == nil && fallback.carStatus == nil)
        let trip = try #require(fallback.trip)
        #expect(fallback.driveLeftCard == .trip(trip))

        handle(&engine, drive(navigation: .route(taipei), at: 2.4), at: 2.4)
        handle(&engine, drive(navigation: .route(taipei), at: 2.6), at: 2.6)
        let back = state(engine, at: 2.6)
        #expect(back.source == .valid(.carBluetooth))
        #expect(back.tires != nil && back.odometer == .value(48_213))
        guard case .navigation(.route)? = back.driveLeftCard else { Issue.record("\(String(describing: back.driveLeftCard))"); return }
        // Back in place, not a Q11 switch: nothing fades.
        #expect(back.navigationSwitches == car.navigationSwitches)
    }
}
