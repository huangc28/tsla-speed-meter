import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A car reply that reached the phone at `t0 + seconds`: drive state (speed, gear D) unless
/// `kmh` is nil, and charge state when `percent` or `rangeKm` is given.
private func reply(kmh: Double? = 40, percent: Int? = nil, rangeKm: Double? = nil, at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds,
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }, gear: kmh == nil ? nil : .drive,
                        batteryPercent: percent, rangeKilometers: rangeKm))
}

/// #49: battery / range in the bottom-left block (L33, L50, DESIGN.md hardened states).
struct HUDEngineBatteryTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func gps(_ engine: inout HUDEngine, kmh value: Double, at seconds: TimeInterval) {
        engine.handle(.sample(fix(value / 3.6, at: seconds)), now: t0 + seconds)
    }

    private func battery(_ engine: HUDEngine, at seconds: TimeInterval, unit: SpeedUnit = .kilometersPerHour) -> BatteryBlock? {
        engine.state(at: t0 + seconds, unit: unit).battery
    }

    // MARK: Hidden without a car

    @Test func hiddenWithNoCar() {
        var engine = authorized()
        #expect(battery(engine, at: 0) == nil)
        gps(&engine, kmh: 72, at: 0)
        #expect(battery(engine, at: 0) == nil)
    }

    // Disconnected on request (the test page's 斷線, a cancelled or failed pairing): the feed
    // is not trying, so the block hides at once, value or waiting.
    @Test func hiddenAtOnceWhenTheLinkGoesIdle() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        handle(&engine, .link(.idle), at: 0.5)
        #expect(battery(engine, at: 0.5) == nil)
        #expect(battery(engine, at: 15) == nil)
        #expect(battery(engine, at: 120) == nil)
        // Connecting again brings it back.
        handle(&engine, .link(.connecting), at: 20)
        #expect(battery(engine, at: 20) == .value(percent: 72, range: 315))
    }

    @Test func waitingHidesWhenTheLinkGoesIdle() {
        var engine = authorized()
        handle(&engine, .link(.connected), at: 0)
        #expect(battery(engine, at: 0) == .waiting)
        handle(&engine, .link(.idle), at: 1)
        #expect(battery(engine, at: 1) == nil)
    }

    @Test func idleEndsALostLink() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        handle(&engine, .link(.lost), at: 1)
        handle(&engine, .link(.idle), at: 2)
        // A new attempt starts a new 10 s count only if it is lost again.
        handle(&engine, .link(.connecting), at: 30)
        #expect(battery(engine, at: 30) == .value(percent: 72, range: 315))
    }

    @Test func hiddenWhenNotPaired() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        handle(&engine, .link(.notPaired), at: 0.5)
        #expect(battery(engine, at: 0.5) == nil)
    }

    // MARK: Waiting

    @Test func waitingWhileConnecting() {
        var engine = authorized()
        handle(&engine, .link(.connecting), at: 0)
        #expect(battery(engine, at: 0) == .waiting)
    }

    @Test func waitingUntilTheFirstBatteryReading() {
        var engine = authorized()
        handle(&engine, reply(at: 0), at: 0)
        #expect(engine.state(at: t0, unit: .kilometersPerHour).source == .valid(.carBluetooth))
        #expect(battery(engine, at: 0) == .waiting)
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0.2), at: 0.2)
        #expect(battery(engine, at: 0.2) == .value(percent: 72, range: 315))
    }

    // MARK: Value

    @Test func showsTheValue() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315.4, at: 0), at: 0)
        #expect(battery(engine, at: 0) == .value(percent: 72, range: 315))
    }

    // A charge reply without drive state (its drive request was skipped) still counts.
    @Test func aChargeOnlyReplyCounts() {
        var engine = authorized()
        handle(&engine, reply(at: 0), at: 0)
        handle(&engine, reply(kmh: nil, percent: 100, rangeKm: 520, at: 0.1), at: 0.1)
        #expect(battery(engine, at: 0.2) == .value(percent: 100, range: 520))
    }

    @Test func aMissingHalfShowsAsDash() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, at: 0), at: 0)
        #expect(battery(engine, at: 0) == .value(percent: 72, range: nil))
    }

    // The car sends rated range in miles; the app maps it to km (`CarReading`), shown in whole km.
    @Test func carMilesShowAsKilometers() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 195.7 * 1.609344, at: 0), at: 0)
        #expect(battery(engine, at: 0) == .value(percent: 72, range: 315))
    }

    @Test func mphShowsMiles() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 195.7 * 1.609344, at: 0), at: 0)
        #expect(battery(engine, at: 0, unit: .milesPerHour) == .value(percent: 72, range: 196))
    }

    // MARK: Stale after 60 s

    @Test func staleOnceTheBatteryValueIsMoreThanSixtySecondsOld() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        // Drive replies keep coming, so the car stays the speed source.
        for step in 1...310 {
            let seconds = Double(step) * 0.2
            handle(&engine, reply(at: seconds), at: seconds)
        }
        #expect(engine.state(at: t0 + 62, unit: .kilometersPerHour).source == .valid(.carBluetooth))
        #expect(battery(engine, at: 60) == .value(percent: 72, range: 315))
        #expect(battery(engine, at: 60.1) == .stale)
        // A new value ends it.
        handle(&engine, reply(percent: 71, rangeKm: 310, at: 62), at: 62)
        #expect(battery(engine, at: 62) == .value(percent: 71, range: 310))
    }

    // MARK: Hidden after 10 s lost, and on GPS

    @Test func hiddenOnceTheLinkHasBeenLostForMoreThanTenSeconds() {
        // No GPS, so only the lost link can hide it.
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        handle(&engine, .link(.lost), at: 1)
        let gap = engine.state(at: t0 + 5, unit: .kilometersPerHour)
        #expect(gap.numeral == "—")
        #expect(gap.battery == .value(percent: 72, range: 315))
        #expect(battery(engine, at: 11) == .value(percent: 72, range: 315))
        #expect(battery(engine, at: 11.1) == nil)
        // Back: the block returns with the link.
        handle(&engine, .link(.connected), at: 20)
        #expect(battery(engine, at: 20) == .value(percent: 72, range: 315))
    }

    @Test func aLaterLostDoesNotRestartTheTenSeconds() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        handle(&engine, .link(.lost), at: 1)
        handle(&engine, .link(.lost), at: 8)
        #expect(battery(engine, at: 11.1) == nil)
    }

    @Test func hiddenOnGPSFallback() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        gps(&engine, kmh: 70, at: 2.5)
        let fallback = engine.state(at: t0 + 2.5, unit: .kilometersPerHour)
        #expect(fallback.source == .gpsFallback)
        // The battery value is only 2.5 s old, but GPS supplies the speed.
        #expect(fallback.battery == nil)
    }

    @Test func hiddenWhileGPSShowsBeforeTheCarAnswers() {
        var engine = authorized()
        handle(&engine, .link(.connecting), at: 0)
        gps(&engine, kmh: 70, at: 0)
        #expect(engine.state(at: t0, unit: .kilometersPerHour).source == .valid(.gps))
        #expect(battery(engine, at: 0) == nil)
    }

    // MARK: Background

    @Test func hiddenInTheBackgroundAndWaitingAgainAfterResume() {
        var engine = authorized()
        handle(&engine, reply(percent: 72, rangeKm: 315, at: 0), at: 0)
        engine.suspend()
        #expect(battery(engine, at: 0.1) == nil)
        engine.resume(now: t0 + 5)
        handle(&engine, reply(at: 5.1), at: 5.1)
        #expect(battery(engine, at: 5.1) == .waiting)
    }
}
