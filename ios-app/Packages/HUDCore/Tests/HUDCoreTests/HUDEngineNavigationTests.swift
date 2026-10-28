import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

private let taipei = CarRoute(destination: "台北車站", minutesToArrival: 17.6, kilometersToArrival: 12.3, energyAtArrival: 64.3)
private let airport = CarRoute(destination: "桃園機場", minutesToArrival: 41, kilometersToArrival: 38.6, energyAtArrival: 51)

/// A drive reply that reached the phone at `t0 + seconds`, stamped with the car's own time, with the
/// car's navigation (`.noRoute` when none is set).
private func drive(_ navigation: CarNavigation = .noRoute, kmh: Double = 60, gear: CarGear = .drive,
                   at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, speedMetersPerSecond: kmh / 3.6,
                        gear: gear, navigation: navigation))
}

/// #77: the drive screen's right panel (M12-04, L73 Q11, L84-4), fed car events, GPS events and an
/// injected clock.
struct HUDEngineNavigationTests {
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

    private func panel(_ engine: HUDEngine, at seconds: TimeInterval) -> NavigationPanel? {
        state(engine, at: seconds).navigation
    }

    /// Two P readings 0.2 s apart, the last at `seconds`: the auto-parked layout.
    private func park(_ engine: inout HUDEngine, _ navigation: CarNavigation = .noRoute, at seconds: TimeInterval) {
        handle(&engine, drive(navigation, kmh: 0, gear: .park, at: seconds - 0.2), at: seconds - 0.2)
        handle(&engine, drive(navigation, kmh: 0, gear: .park, at: seconds), at: seconds)
        #expect(state(engine, at: seconds).layout == .parked)
    }

    private static let shownTaipei = NavigationPanel.route(
        NavigationRoute(destination: "台北車站", minutes: 18, distance: 12, arrivalPercent: 64))

    // MARK: Chosen once, on entering drive

    @Test func enteringDriveWithAFreshRouteShowsNavigation() {
        var engine = authorized()
        // Opening the app in a parked car with a route set: the first P reading is not parked yet, and
        // a fresh P does not use the Q11 switch.
        handle(&engine, drive(.route(taipei), kmh: 0, gear: .park, at: 0.5), at: 0.5)
        #expect(state(engine, at: 0.5).layout == .drive)
        #expect(panel(engine, at: 0.5) == nil)
        park(&engine, .route(taipei), at: 1)
        // Parked, the right panel is the tire panel (#50); navigation as a parked card is #79.
        #expect(panel(engine, at: 1) == nil)
        handle(&engine, drive(.route(taipei), at: 1.4), at: 1.4)
        #expect(state(engine, at: 1.4).layout == .drive)
        #expect(panel(engine, at: 1.4) == Self.shownTaipei)
        // Chosen, not switched: nothing fades.
        #expect(state(engine, at: 1.4).navigationSwitches == 0)
    }

    @Test func valuesUpdateInPlace() {
        var engine = authorized()
        park(&engine, .route(taipei), at: 1)
        handle(&engine, drive(.route(taipei), at: 1.4), at: 1.4)
        var nearer = taipei
        nearer.minutesToArrival = 3.4
        nearer.kilometersToArrival = 1.04
        nearer.energyAtArrival = 66.7
        handle(&engine, drive(.route(nearer), at: 1.6), at: 1.6)
        #expect(panel(engine, at: 1.6) == .route(NavigationRoute(destination: "台北車站", minutes: 3, distance: 1, arrivalPercent: 67)))
        #expect(state(engine, at: 1.6).navigationSwitches == 0)
    }

    @Test func enteringDriveWithoutARouteLeavesThePanelEmpty() {
        var engine = authorized()
        #expect(panel(engine, at: 0) == nil)
        handle(&engine, drive(at: 1), at: 1)
        #expect(panel(engine, at: 1) == nil)
        park(&engine, at: 2)
        handle(&engine, drive(at: 2.2), at: 2.2)
        #expect(panel(engine, at: 2.2) == nil)
    }

    // MARK: Q11: one switch per trip, re-armed only by a valid park

    @Test func aRouteSetAfterEnteringDriveSwitchesOnce() {
        var engine = authorized()
        handle(&engine, drive(at: 1), at: 1)
        #expect(panel(engine, at: 1) == nil)
        handle(&engine, drive(.route(taipei), at: 1.2), at: 1.2)
        #expect(panel(engine, at: 1.2) == Self.shownTaipei)
        #expect(state(engine, at: 1.2).navigationSwitches == 1)

        // Cancelling empties the panel (L84-4); a new destination shows in place, with no second switch.
        handle(&engine, drive(at: 1.4), at: 1.4)
        #expect(panel(engine, at: 1.4) == .ended)
        handle(&engine, drive(.route(airport), at: 1.6), at: 1.6)
        #expect(panel(engine, at: 1.6) == .route(NavigationRoute(destination: "桃園機場", minutes: 41, distance: 39, arrivalPercent: 51)))
        #expect(state(engine, at: 1.6).navigationSwitches == 1)

        // A reconnect and a trip to the background bring the route back in place, not as a switch.
        handle(&engine, .link(.lost), at: 2)
        handle(&engine, .link(.connected), at: 4)
        handle(&engine, drive(.route(airport), at: 4.2), at: 4.2)
        engine.suspend()
        engine.resume(now: t0 + 10)
        handle(&engine, .link(.connected), at: 10.5)
        handle(&engine, drive(.route(airport), at: 11), at: 11)
        #expect(panel(engine, at: 11) == .route(NavigationRoute(destination: "桃園機場", minutes: 41, distance: 39, arrivalPercent: 51)))
        #expect(state(engine, at: 11).navigationSwitches == 1)
    }

    @Test func aPThatDoesNotParkChoosesNothingAnew() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        #expect(state(engine, at: 1).navigationSwitches == 1)
        handle(&engine, drive(at: 1.2), at: 1.2)
        // One P reading is not a valid park, and neither is a P while moving.
        handle(&engine, drive(kmh: 0, gear: .park, at: 1.4), at: 1.4)
        handle(&engine, drive(kmh: 20, gear: .park, at: 1.6), at: 1.6)
        handle(&engine, drive(kmh: 20, gear: .park, at: 1.8), at: 1.8)
        #expect(state(engine, at: 1.8).layout == .drive)
        #expect(panel(engine, at: 1.8) == .ended)
        handle(&engine, drive(.route(taipei), at: 2), at: 2)
        #expect(panel(engine, at: 2) == Self.shownTaipei)
        #expect(state(engine, at: 2).navigationSwitches == 1)
    }

    @Test func aValidParkReArmsTheSwitch() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        #expect(state(engine, at: 1).navigationSwitches == 1)
        handle(&engine, drive(at: 2), at: 2)
        park(&engine, at: 3)
        // The next drive starts empty, and a route set while driving switches once more.
        handle(&engine, drive(at: 3.2), at: 3.2)
        #expect(panel(engine, at: 3.2) == nil)
        handle(&engine, drive(.route(airport), at: 3.4), at: 3.4)
        #expect(panel(engine, at: 3.4) == .route(NavigationRoute(destination: "桃園機場", minutes: 41, distance: 39, arrivalPercent: 51)))
        #expect(state(engine, at: 3.4).navigationSwitches == 2)
    }

    @Test func aParkThatEndsByTimeEntersDriveWithNoRoute() {
        var engine = authorized()
        park(&engine, .route(taipei), at: 1)
        // The P expires with no event; the drive layout entered then had no fresh route.
        #expect(state(engine, at: 3.5).layout == .drive)
        #expect(panel(engine, at: 3.5) == nil)
        handle(&engine, .link(.connected), at: 3.5)
        handle(&engine, drive(.route(taipei), at: 4), at: 4)
        #expect(panel(engine, at: 4) == Self.shownTaipei)
        #expect(state(engine, at: 4).navigationSwitches == 1)
    }

    // MARK: Ended, stale, GPS

    @Test func aRouteKnownToHaveEndedEmptiesThePanel() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        handle(&engine, drive(.noRoute, at: 1.2), at: 1.2)
        #expect(panel(engine, at: 1.2) == .ended)
    }

    @Test func staleCarDataShowsThePin() {
        var engine = authorized()
        handle(&engine, .link(.connected), at: 0)
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        #expect(panel(engine, at: 3) == Self.shownTaipei)
        // No fresh drive reply within 2 s, and no GPS: speed unavailable, the pin in place.
        #expect(state(engine, at: 3.1).source == .speedUnavailable)
        #expect(panel(engine, at: 3.1) == .stale)
        // Lost on Car Bluetooth: still the pin.
        handle(&engine, .link(.lost), at: 4)
        #expect(panel(engine, at: 30) == .stale)
        // Fresh again: back in place, not a switch.
        handle(&engine, .link(.connected), at: 31)
        handle(&engine, drive(.route(taipei), at: 31.5), at: 31.5)
        #expect(panel(engine, at: 31.5) == Self.shownTaipei)
        #expect(state(engine, at: 31.5).navigationSwitches == 1)
        // A stale ended route is stale too: nothing says whether a route is set.
        handle(&engine, drive(.noRoute, at: 32), at: 32)
        #expect(panel(engine, at: 34.1) == .stale)
    }

    @Test func gpsFallbackRemovesTheWholeGroup() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        engine.handle(.sample(fix(100 / 3.6, at: 2.5)), now: t0 + 2.5)
        #expect(state(engine, at: 3.1).source == .gpsFallback)
        #expect(panel(engine, at: 3.1) == nil)
        // Back on Car Bluetooth (two readings in a row), the route comes back in place.
        handle(&engine, drive(.route(taipei), at: 3.2), at: 3.2)
        handle(&engine, drive(.route(taipei), at: 3.4), at: 3.4)
        #expect(state(engine, at: 3.4).source == .valid(.carBluetooth))
        #expect(panel(engine, at: 3.4) == Self.shownTaipei)
        #expect(state(engine, at: 3.4).navigationSwitches == 1)
    }

    @Test func noPinWithoutACarLink() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        // The feed stopped trying (斷線): nothing about the car is current, and a late reply stores nothing.
        handle(&engine, .link(.idle), at: 1.5)
        #expect(panel(engine, at: 1.5) == nil)
        handle(&engine, drive(.route(airport), at: 1.6), at: 1.6)
        #expect(panel(engine, at: 1.6) == nil)
        // In the background the car is forgotten: back in front, no pin until the link reports again.
        handle(&engine, .link(.connected), at: 2)
        engine.suspend()
        engine.resume(now: t0 + 10)
        #expect(panel(engine, at: 10) == nil)
        handle(&engine, .link(.connecting), at: 10.5)
        #expect(panel(engine, at: 10.5) == .stale)
    }

    @Test func noNavigationWithoutDriveState() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        // A charge-only reply says nothing about the route: it neither ends nor refreshes it.
        handle(&engine, .reading(CarReading(receivedAt: t0 + 1.5, carTimestamp: carEpoch + 1.5, batteryPercent: 72)), at: 1.5)
        #expect(panel(engine, at: 1.5) == Self.shownTaipei)
        #expect(panel(engine, at: 3.1) == .stale)
    }

    // MARK: Values

    @Test func mphShowsMiles() {
        var engine = authorized()
        handle(&engine, drive(.route(taipei), at: 1), at: 1)
        // 12.3 km is 7.6 mi: one decimal under 10.
        #expect(state(engine, at: 1, unit: .milesPerHour).navigation
            == .route(NavigationRoute(destination: "台北車站", minutes: 18, distance: 7.6, arrivalPercent: 64)))
    }

    @Test func distanceHasOneDecimalUnderTenAndMinutesAreWhole() {
        func shown(_ km: Double?, minutes: Double? = 17.5, energy: Double? = nil) -> NavigationRoute {
            NavigationRoute(CarRoute(destination: "", minutesToArrival: minutes, kilometersToArrival: km, energyAtArrival: energy),
                            unit: .kilometersPerHour)
        }
        #expect(shown(0.04).distance == 0)
        #expect(shown(9.94).distance == 9.9)
        #expect(shown(9.96).distance == 10)
        #expect(shown(12.4).distance == 12)
        #expect(shown(12.5).distance == 13)
        #expect(shown(nil).distance == nil)
        #expect(shown(1).minutes == 18)
        #expect(shown(1, minutes: nil).minutes == nil)
        // No energy at arrival hides the sentence.
        #expect(shown(1).arrivalPercent == nil)
        #expect(shown(1, energy: 63.5).arrivalPercent == 64)
    }
}
