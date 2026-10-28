import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A Car Bluetooth reply that reached the phone at `t0 + seconds`, stamped with the car's own time.
private func car(_ kmh: Double?, gear: CarGear? = .drive, battery: Int? = nil, at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds,
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }, gear: gear, batteryPercent: battery))
}

/// A charge-state-only reply (no drive state), as the car feed's slow slots send.
private func charge(_ percent: Int, at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, batteryPercent: percent))
}

/// #76: the trip (L89), fed GPS events, car events and an injected clock.
struct HUDEngineTripTests {
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

    /// Car readings every `step` seconds from `from` through `to`.
    private func drive(_ engine: inout HUDEngine, kmh: Double, from: TimeInterval, to: TimeInterval,
                       step: TimeInterval = 1, gear: CarGear = .drive) {
        for s in stride(from: from, through: to, by: step) { handle(&engine, car(kmh, gear: gear, at: s), at: s) }
    }

    /// Two P readings 0.2 s apart, the last at `seconds`: the auto-parked layout.
    private func park(_ engine: inout HUDEngine, at seconds: TimeInterval, battery: Int? = nil) {
        handle(&engine, car(0, gear: .park, at: seconds - 0.2), at: seconds - 0.2)
        handle(&engine, car(0, gear: .park, battery: battery, at: seconds), at: seconds)
    }

    private func trip(_ engine: HUDEngine, at seconds: TimeInterval, unit: SpeedUnit = .kilometersPerHour) -> TripSummary? {
        engine.state(at: t0 + seconds, unit: unit).trip
    }

    // MARK: Start

    @Test func noTripBeforeTheFirstValidSpeed() {
        var engine = authorized()
        #expect(trip(engine, at: 0) == nil)
        engine.handle(.sample(fix(20, at: 1, accuracy: 80)), now: t0 + 1) // poor accuracy: no speed
        #expect(trip(engine, at: 5) == nil)
    }

    @Test func startsAtTheFirstValidSpeedEvenAtZero() {
        var engine = authorized()
        gps(&engine, kmh: 0, at: 30)
        #expect(trip(engine, at: 30) == TripSummary(distance: 0, driveMinutes: 0, averageSpeed: 0, maxSpeed: 0, batteryChange: nil))
        // Drive time counts from the first valid speed, not from the app opening.
        #expect(trip(engine, at: 30 + 59)?.driveMinutes == 0)
        gps(&engine, kmh: 0, at: 90)
        #expect(trip(engine, at: 90)?.driveMinutes == 1)
    }

    // MARK: End at the auto-parked P, and the next drive

    @Test func endsWhenParkedAndTheNextDriveStartsANewTrip() throws {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 180)                // 10 m/s for 180 s: 1.8 km
        handle(&engine, car(0, at: 181), at: 181)
        park(&engine, at: 182)
        #expect(engine.state(at: t0 + 182, unit: .kilometersPerHour).layout == .parked)
        let ended = try #require(trip(engine, at: 182))
        #expect(ended.distance == 1.8 && ended.driveMinutes == 3)
        // Frozen while parked: drive time stops at the end.
        drive(&engine, kmh: 0, from: 183, to: 600, step: 0.5, gear: .park)
        #expect(trip(engine, at: 600) == ended)
        // Shifting to D at 0 km/h still shows the ended trip; moving starts a new one.
        drive(&engine, kmh: 0, from: 601, to: 602, step: 0.2)
        #expect(trip(engine, at: 602) == ended)
        handle(&engine, car(18, at: 603), at: 603)
        #expect(trip(engine, at: 603) == TripSummary(distance: 0, driveMinutes: 0, averageSpeed: 0, maxSpeed: 18, batteryChange: nil))
        drive(&engine, kmh: 18, from: 604, to: 723)              // 5 m/s for 120 s: 0.6 km
        #expect(trip(engine, at: 723)?.distance == 0.6)
        #expect(trip(engine, at: 723)?.driveMinutes == 2)
    }

    @Test func aLinkBlipWhileParkedKeepsTheEndedTrip() throws {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        handle(&engine, car(0, at: 61), at: 61)
        park(&engine, at: 62)
        let ended = try #require(trip(engine, at: 62))
        // The link drops: no longer parked, GPS shows 0 (≤ 0.5 m/s), then the car parks again.
        handle(&engine, .link(.lost), at: 63)
        gps(&engine, kmh: 1, at: 64)
        #expect(engine.state(at: t0 + 64, unit: .kilometersPerHour).layout == .drive)
        #expect(trip(engine, at: 64) == ended)
        handle(&engine, .link(.connected), at: 70)
        park(&engine, at: 71)
        #expect(trip(engine, at: 71) == ended)
    }

    @Test func gpsJitterAfterALinkBlipKeepsTheEndedTrip() throws {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        handle(&engine, car(0, at: 61), at: 61)
        park(&engine, at: 62)
        let ended = try #require(trip(engine, at: 62))
        // The link drops, so the layout leaves parked; once the car's 0 lapses, GPS jitters to 3 km/h:
        // below 5, no new trip.
        handle(&engine, .link(.lost), at: 63)
        gps(&engine, kmh: 3, at: 64.5)
        let state = engine.state(at: t0 + 64.5, unit: .kilometersPerHour)
        #expect(state.layout == .drive && state.numeral == "3")
        #expect(trip(engine, at: 64.5) == ended)
        // 5 km/h or more is a new trip.
        gps(&engine, kmh: 5, at: 65.5)
        #expect(trip(engine, at: 65.5)?.driveMinutes == 0 && trip(engine, at: 65.5)?.distance == 0)
    }

    @Test func gpsJitterBesideASpeedlessPKeepsTheEndedTrip() throws {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        handle(&engine, car(0, at: 61), at: 61)
        for s in stride(from: 61.2, through: 70, by: 0.2) { handle(&engine, car(nil, gear: .park, at: s), at: s) }
        let ended = try #require(trip(engine, at: 70))
        #expect(engine.state(at: t0 + 70, unit: .kilometersPerHour).layout == .parked)
        // GPS jitters to 6 km/h while the car keeps sending P: the shown 6 ends the parked layout,
        // but the car's fresh P still starts no trip.
        gps(&engine, kmh: 6, at: 70.1)
        for s in stride(from: 70.2, through: 72, by: 0.2) { handle(&engine, car(nil, gear: .park, at: s), at: s) }
        let state = engine.state(at: t0 + 72, unit: .kilometersPerHour)
        #expect(state.layout == .drive && state.numeral == "6")
        #expect(trip(engine, at: 72) == ended)
    }

    @Test func anEndedTripKeepsItsDistanceWithNoSpeed() throws {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        handle(&engine, car(0, at: 61), at: 61)
        // P with no speed of its own (「P 檔」): parked, nothing valid on screen.
        handle(&engine, car(nil, gear: .park, at: 61.2), at: 61.2)
        handle(&engine, car(nil, gear: .park, at: 61.4), at: 61.4)
        handle(&engine, car(nil, gear: .park, at: 64), at: 64)
        handle(&engine, car(nil, gear: .park, at: 64.2), at: 64.2)
        let state = engine.state(at: t0 + 64.2, unit: .kilometersPerHour)
        #expect(state.layout == .parked && !state.hasSpeed)
        #expect(state.trip?.distance == 0.6)
    }

    @Test func aGPSZeroOnTheParkedScreenStartsNoTrip() {
        var engine = authorized()
        // P with no speed of its own parks with nothing on screen; GPS 0 then shows, still parked.
        handle(&engine, car(nil, gear: .park, at: 0), at: 0)
        handle(&engine, car(nil, gear: .park, at: 0.2), at: 0.2)
        gps(&engine, kmh: 0, at: 0.5)
        #expect(engine.state(at: t0 + 0.5, unit: .kilometersPerHour).layout == .parked)
        #expect(trip(engine, at: 0.5) == nil)
    }

    @Test func pReadingsAtZeroStartNoTrip() {
        var engine = authorized()
        // The first P reading shows 0 km/h but is not parked yet: a fresh P still starts nothing.
        handle(&engine, car(0, gear: .park, at: 0), at: 0)
        #expect(engine.state(at: t0, unit: .kilometersPerHour).layout == .drive)
        #expect(trip(engine, at: 0) == nil)
        handle(&engine, car(0, gear: .park, battery: 72, at: 0.2), at: 0.2)
        #expect(engine.state(at: t0 + 0.2, unit: .kilometersPerHour).layout == .parked)
        drive(&engine, kmh: 0, from: 0.4, to: 60, step: 0.2, gear: .park)
        #expect(trip(engine, at: 60) == nil)
    }

    @Test func aGPSZeroBeforeTheCarParksLeavesNoTrip() {
        var engine = authorized()
        // GPS 0 before the car connects starts a trip; the car then parks it, and it never moved.
        gps(&engine, kmh: 0, at: 0)
        #expect(trip(engine, at: 0) != nil)
        park(&engine, at: 1.2, battery: 72)
        #expect(engine.state(at: t0 + 1.2, unit: .kilometersPerHour).layout == .parked)
        #expect(trip(engine, at: 1.2) == nil)
        #expect(trip(engine, at: 60) == nil)
    }

    @Test func aTripThatMovedIsKeptWhenItParks() {
        var engine = authorized()
        gps(&engine, kmh: 0, at: 0)
        for s in stride(from: 1.0, through: 10, by: 1) { gps(&engine, kmh: 36, at: s) }   // 10 m/s from 1 to 11
        handle(&engine, car(0, at: 11), at: 11)
        park(&engine, at: 12, battery: 72)
        #expect(engine.state(at: t0 + 12, unit: .kilometersPerHour).layout == .parked)
        #expect(trip(engine, at: 12)?.distance == 0.1)
        #expect(trip(engine, at: 12)?.maxSpeed == 36)
    }

    // MARK: GPS only: 10 minutes without a speed above 0

    @Test func gpsOnlyStartsANewTripAfterTenMinutesStopped() throws {
        var engine = authorized()
        for s in stride(from: 0.0, through: 60, by: 1) { gps(&engine, kmh: 36, at: s) }   // 0.6 km
        // Stopped: GPS 0 for 10 minutes, the trip and its drive time keep going.
        for s in stride(from: 61.0, through: 660, by: 1) { gps(&engine, kmh: 0, at: s) }
        #expect(trip(engine, at: 660)?.distance == 0.6)
        #expect(trip(engine, at: 660)?.driveMinutes == 11)
        gps(&engine, kmh: 36, at: 661)
        #expect(trip(engine, at: 661) == TripSummary(distance: 0, driveMinutes: 0, averageSpeed: 0, maxSpeed: 36, batteryChange: nil))
    }

    @Test func gpsOnlyKeepsTheTripAfterAShorterStop() {
        var engine = authorized()
        for s in stride(from: 0.0, through: 60, by: 1) { gps(&engine, kmh: 36, at: s) }
        // The last speed above 0 held until 61; moving again at 660 is 599 s later.
        for s in stride(from: 61.0, through: 659, by: 1) { gps(&engine, kmh: 0, at: s) }
        gps(&engine, kmh: 36, at: 660)
        #expect(trip(engine, at: 660)?.distance == 0.6)
        #expect(trip(engine, at: 660)?.driveMinutes == 11)
    }

    @Test func aCarStoppedInDriveKeepsItsTrip() {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        // Twenty minutes at 0 in D (a jam), the car answering throughout: only P ends a trip.
        drive(&engine, kmh: 0, from: 61, to: 1260)
        handle(&engine, car(36, at: 1261), at: 1261)
        #expect(trip(engine, at: 1261)?.distance == 0.6)
        #expect(trip(engine, at: 1261)?.driveMinutes == 21)
    }

    // MARK: Distance

    @Test func distanceIntegratesTheCarThenTheGPSSpeed() {
        var engine = authorized()
        // GPS says 72 km/h throughout, but the car's 90 km/h shows while valid: 0–12 s, 300 m.
        for s in stride(from: 0.0, through: 22, by: 1) {
            if s <= 10 { handle(&engine, car(90, at: s), at: s) }
            gps(&engine, kmh: 72, at: s)
            if s == 12 { #expect(engine.state(at: t0 + s, unit: .kilometersPerHour).source == .valid(.carBluetooth)) }
            if s == 13 { #expect(engine.state(at: t0 + s, unit: .kilometersPerHour).source == .gpsFallback) }
            // Then GPS from 12 s: 20 m/s.
            if s == 17 { #expect(trip(engine, at: s)?.distance == 0.4) }
        }
        #expect(trip(engine, at: 22)?.distance == 0.5)
    }

    @Test func aSpeedCountsOnlyUntilItExpires() {
        var engine = authorized()
        handle(&engine, car(180, at: 0), at: 0)                  // 50 m/s, valid for 2 s: 100 m
        #expect(trip(engine, at: 100)?.distance == nil)
        gps(&engine, kmh: 0, at: 100)
        #expect(trip(engine, at: 100)?.distance == 0.1)
    }

    @Test func aGPSSpeedCountsOnlyUntilItExpires() {
        var engine = authorized()
        gps(&engine, kmh: 180, at: 0)                            // 50 m/s, valid for 2 s: 100 m
        gps(&engine, kmh: 0, at: 100)
        // 100 m in 100 s: 3.6 km/h. Counting the fix 1 s longer would make it 5.
        #expect(trip(engine, at: 100)?.distance == 0.1)
        #expect(trip(engine, at: 100)?.averageSpeed == 4)
    }

    @Test func noSpeedShowsDashAndDriveTimeKeepsCounting() {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)                 // 10 m/s until 62: 0.62 km
        #expect(trip(engine, at: 62)?.distance == 0.6)
        #expect(trip(engine, at: 63)?.distance == nil)
        #expect(trip(engine, at: 63)?.averageSpeed == nil)
        #expect(trip(engine, at: 185)?.driveMinutes == 3)
        // The speed returns (the car shows again at its second reading, 186): the accumulated
        // distance shows again, the gap is not counted.
        drive(&engine, kmh: 36, from: 185, to: 222)              // 0.98 km at 222
        #expect(trip(engine, at: 222)?.distance == 0.9)
        #expect(trip(engine, at: 223)?.distance == 0.9)
        #expect(trip(engine, at: 224)?.distance == 1.0)
    }

    @Test func gpsDeadBandAddsNoDistance() {
        var engine = authorized()
        for s in stride(from: 0.0, through: 600, by: 1) { engine.handle(.sample(fix(0.5, at: s)), now: t0 + s) }
        #expect(trip(engine, at: 600)?.distance == 0)
        #expect(trip(engine, at: 600)?.maxSpeed == 0)
    }

    // MARK: Average and max

    @Test func averageAndMax() {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 59)                 // 10 m/s for 60 s
        drive(&engine, kmh: 72, from: 60, to: 119)               // 20 m/s for 60 s
        drive(&engine, kmh: 0, from: 120, to: 300)               // three minutes stopped in D
        park(&engine, at: 301)
        // 1.8 km over the drive time, 301 s, stops included: 21.5 km/h (54 over the 120 s moving).
        let summary = trip(engine, at: 301)
        #expect(summary?.distance == 1.8)
        #expect(summary?.averageSpeed == 22)
        #expect(summary?.maxSpeed == 72)
        #expect(summary?.driveMinutes == 5)
    }

    // MARK: Battery change

    @Test func batteryChangeIsNowMinusTheStart() {
        var engine = authorized()
        handle(&engine, car(30, battery: 80, at: 0), at: 0)
        drive(&engine, kmh: 30, from: 1, to: 60)
        handle(&engine, charge(78, at: 61), at: 61)
        #expect(trip(engine, at: 61)?.batteryChange == -2)
        handle(&engine, car(0, at: 62), at: 62)
        park(&engine, at: 63, battery: 76)
        #expect(trip(engine, at: 63)?.batteryChange == -4)
        // Charging while parked: up is positive.
        handle(&engine, charge(83, at: 70), at: 70)
        #expect(trip(engine, at: 70)?.batteryChange == 3)
    }

    @Test func batteryAFewSecondsAfterTheStartCountsAsTheStart() {
        var engine = authorized()
        // The car feed asks drive state first and charge state a slot later.
        handle(&engine, car(30, at: 0), at: 0)
        handle(&engine, car(30, battery: 72, at: 0.4), at: 0.4)
        drive(&engine, kmh: 30, from: 1, to: 60)
        handle(&engine, charge(70, at: 61), at: 61)
        #expect(trip(engine, at: 61)?.batteryChange == -2)
    }

    @Test func theStartBatteryMustBeFresh() {
        var engine = authorized()
        // An 80% from 30 minutes earlier is not the start's; a fresh 79% inside the grace is.
        handle(&engine, charge(80, at: 0), at: 0)
        handle(&engine, car(30, at: 1800), at: 1800)
        handle(&engine, car(30, battery: 79, at: 1800.4), at: 1800.4)
        drive(&engine, kmh: 30, from: 1801, to: 1860)
        handle(&engine, charge(77, at: 1861), at: 1861)
        #expect(trip(engine, at: 1861)?.batteryChange == -2)
    }

    @Test func batteryChangeHiddenWithoutAStartValue() {
        var engine = authorized()
        // The car joins a GPS trip later: its first battery reading is not the start's.
        for s in stride(from: 0.0, through: 30, by: 1) { gps(&engine, kmh: 30, at: s) }
        handle(&engine, car(30, battery: 72, at: 31), at: 31)
        drive(&engine, kmh: 30, from: 32, to: 60)
        handle(&engine, charge(70, at: 61), at: 61)
        #expect(trip(engine, at: 61) != nil)
        #expect(trip(engine, at: 61)?.batteryChange == nil)
    }

    @Test func batteryChangeHiddenOnGPSOnly() {
        var engine = authorized()
        for s in stride(from: 0.0, through: 60, by: 1) { gps(&engine, kmh: 30, at: s) }
        #expect(trip(engine, at: 60) != nil)
        #expect(trip(engine, at: 60)?.batteryChange == nil)
    }

    // MARK: Units

    @Test func milesInMphMode() {
        var engine = authorized()
        drive(&engine, kmh: 72, from: 0, to: 99)                 // 20 m/s for 100 s: 2 km = 1.24 mi
        handle(&engine, car(0, at: 100), at: 100)
        park(&engine, at: 101)
        #expect(trip(engine, at: 101, unit: .kilometersPerHour)?.distance == 2.0)
        let mph = trip(engine, at: 101, unit: .milesPerHour)
        #expect(mph?.distance == 1.2)
        #expect(mph?.maxSpeed == 45)                            // 72 km/h
        #expect(mph?.averageSpeed == 44)                        // 2 km in 101 s
    }

    // MARK: Background

    @Test func theTripOutlivesTheBackground() {
        var engine = authorized()
        drive(&engine, kmh: 36, from: 0, to: 60)
        engine.suspend()
        engine.resume(now: t0 + 300)
        #expect(trip(engine, at: 300)?.distance == nil)
        #expect(trip(engine, at: 300)?.driveMinutes == 5)
        // Nothing was added in the background: 0.6 km before it, 0.19 km after.
        drive(&engine, kmh: 36, from: 301, to: 320)
        #expect(trip(engine, at: 320)?.distance == 0.7)
    }
}
