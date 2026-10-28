import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A drive reply that reached the phone at `t0 + seconds`, stamped `carTime` (default `seconds`);
/// `kmh` nil sends no speed.
private func drive(_ gear: CarGear?, kmh: Double? = 0, at seconds: TimeInterval, carTime: TimeInterval? = nil,
                   tires: CarTires? = nil) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + (carTime ?? seconds),
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }, gear: gear, tires: tires))
}

/// A tire measured `minutesAgo` before the car time `carTime`, or at an unknown time.
private func tire(_ psi: Double, minutesAgo: Double?, carTime: TimeInterval) -> CarTire {
    CarTire(psi: psi, lastSeen: minutesAgo.map { carEpoch + carTime - $0 * 60 })
}

/// #50: the parked screen (L6, L42, DESIGN.md "Parked screen" and hardened states).
struct HUDEngineParkedTests {
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

    private func state(_ engine: HUDEngine, at seconds: TimeInterval) -> HUDState {
        engine.state(at: t0 + seconds, unit: .kilometersPerHour)
    }

    private func layout(_ engine: HUDEngine, at seconds: TimeInterval) -> ScreenLayout {
        state(engine, at: seconds).layout
    }

    /// Two fresh P readings, the second at `t0 + seconds`.
    private func parked(kmh: Double? = 0, at seconds: TimeInterval = 0.2, tires: CarTires? = nil) -> HUDEngine {
        var engine = authorized()
        handle(&engine, drive(.park, kmh: kmh, at: seconds - 0.2), at: seconds - 0.2)
        handle(&engine, drive(.park, kmh: kmh, at: seconds, tires: tires), at: seconds)
        return engine
    }

    private func tireWheels(_ engine: HUDEngine, at seconds: TimeInterval) -> TireWheels? {
        guard case .wheels(let wheels) = state(engine, at: seconds).tires else { return nil }
        return wheels
    }

    // MARK: Entering

    @Test func entersAfterTwoDistinctInOrderPReadings() {
        var engine = authorized()
        handle(&engine, drive(.drive, kmh: 3, at: 0), at: 0)
        handle(&engine, drive(.park, at: 0.2), at: 0.2)
        #expect(layout(engine, at: 0.2) == .drive)
        // The same car timestamp again, and an older one: not a second reading.
        handle(&engine, drive(.park, at: 0.3, carTime: 0.2), at: 0.3)
        handle(&engine, drive(.park, at: 0.35, carTime: 0.1), at: 0.35)
        #expect(layout(engine, at: 0.35) == .drive)
        handle(&engine, drive(.park, at: 0.4), at: 0.4)
        let parked = state(engine, at: 0.4)
        #expect(parked.layout == .parked)
        #expect(parked.numeral == "0")
        #expect(parked.gearRow == .park)
        #expect(parked.tires == .wheels(.noReadings))
    }

    @Test func entersOnColdStartToo() {
        let engine = parked()
        #expect(layout(engine, at: 0.2) == .parked)
    }

    @Test func theTwoReadingsMustComeInARow() {
        var engine = authorized()
        handle(&engine, drive(.park, at: 0), at: 0)
        // The first expired before the second came.
        handle(&engine, drive(.park, at: 2.5), at: 2.5)
        #expect(layout(engine, at: 2.5) == .drive)
        handle(&engine, drive(.park, at: 2.7), at: 2.7)
        #expect(layout(engine, at: 2.7) == .parked)
    }

    // The drive screen keeps no tire panel.
    @Test func noTirePanelWhileDriving() {
        var engine = authorized()
        let tires = CarTires(frontLeft: tire(42, minutesAgo: 1, carTime: 0), frontRight: nil, rearLeft: nil, rearRight: nil)
        handle(&engine, drive(.drive, kmh: 40, at: 0, tires: tires), at: 0)
        handle(&engine, drive(.drive, kmh: 40, at: 0.2), at: 0.2)
        #expect(state(engine, at: 0.2).layout == .drive)
        #expect(state(engine, at: 0.2).tires == nil)
    }

    // MARK: Returning to drive

    @Test func returnsAsSoonAsPIsNoLongerFresh() {
        let engine = parked()
        #expect(layout(engine, at: 2.2) == .parked)
        #expect(layout(engine, at: 2.3) == .drive)
    }

    // A frozen drive state (the same car timestamp over and over) does not keep P fresh.
    @Test func aRepeatedCarTimestampDoesNotKeepPFresh() {
        var engine = parked()
        handle(&engine, drive(.park, at: 1.5, carTime: 0.2), at: 1.5)
        #expect(layout(engine, at: 2.3) == .drive)
    }

    @Test func returnsAtOnceOnAnotherGear() {
        var engine = parked()
        handle(&engine, drive(.drive, kmh: 1, at: 0.4), at: 0.4)
        let driving = state(engine, at: 0.4)
        #expect(driving.layout == .drive)
        #expect(driving.tires == nil)
        #expect(driving.gearRow == .drive)
        // Back in P: two new readings.
        handle(&engine, drive(.park, at: 0.6), at: 0.6)
        #expect(layout(engine, at: 0.6) == .drive)
        handle(&engine, drive(.park, at: 0.8), at: 0.8)
        #expect(layout(engine, at: 0.8) == .parked)
    }

    @Test func returnsOnAnUnknownGear() {
        var engine = parked()
        handle(&engine, drive(nil, at: 0.4), at: 0.4)
        #expect(layout(engine, at: 0.4) == .drive)
    }

    // L43: P at 5 km/h or more contradicts the speed; it is not parked, and two more P readings
    // that do not move are needed.
    @Test func pWhileMovingReturnsToDrive() {
        var engine = parked()
        handle(&engine, drive(.park, kmh: 5, at: 0.4), at: 0.4)
        #expect(layout(engine, at: 0.4) == .drive)
        handle(&engine, drive(.park, kmh: 4, at: 0.6), at: 0.6)
        #expect(layout(engine, at: 0.6) == .drive)
        handle(&engine, drive(.park, kmh: 4, at: 0.8), at: 0.8)
        #expect(layout(engine, at: 0.8) == .parked)
    }

    // A P with no speed is judged against the speed on screen: the car's own speed, still valid
    // from the D readings, says the car moves (DESIGN.md: "a fresh P with any valid speed ≥ 5 km/h").
    @Test func aSpeedlessPWhileTheCarSpeedShowsMovingIsNotParked() {
        var engine = authorized()
        handle(&engine, drive(.drive, kmh: 30, at: 0), at: 0)
        handle(&engine, drive(.drive, kmh: 30, at: 0.2), at: 0.2)
        handle(&engine, drive(.park, kmh: nil, at: 0.4), at: 0.4)
        handle(&engine, drive(.park, kmh: nil, at: 0.6), at: 0.6)
        let moving = state(engine, at: 0.6)
        #expect(moving.numeral == "30")
        #expect(moving.layout == .drive)
        #expect(moving.gearRow == nil)
        #expect(moving.tires == nil)
    }

    @Test func returnsWhenTheLinkIsLostOrIdleOrNotPaired() {
        for status in [CarLinkStatus.lost, .idle, .notPaired] {
            var engine = parked()
            handle(&engine, .link(status), at: 0.3)
            #expect(layout(engine, at: 0.3) == .drive, "\(status)")
            // A reply in flight that arrives after: one reading is not enough.
            handle(&engine, drive(.park, at: 0.4), at: 0.4)
            #expect(layout(engine, at: 0.4) == .drive, "\(status)")
        }
    }

    @Test func lateReadingsAfterIdleNeverPark() {
        var engine = parked()
        handle(&engine, .link(.idle), at: 0.3)
        handle(&engine, drive(.park, at: 0.4), at: 0.4)
        handle(&engine, drive(.park, at: 0.6), at: 0.6)
        #expect(layout(engine, at: 0.6) == .drive)
    }

    // Parked entry needs readings only: a link status that came before resume (and was wiped by
    // it) is not needed.
    @Test func startsOverAfterResumeWithNoLinkStatus() {
        var engine = parked()
        engine.suspend()
        #expect(layout(engine, at: 0.3) == .drive)
        engine.resume(now: t0 + 10)
        handle(&engine, drive(.park, at: 10.1), at: 10.1)
        #expect(layout(engine, at: 10.1) == .drive)
        handle(&engine, drive(.park, at: 10.3), at: 10.3)
        #expect(layout(engine, at: 10.3) == .parked)
    }

    // MARK: GPS never parks

    @Test func gpsNeverParks() {
        var engine = authorized()
        for step in 0...600 {
            let seconds = Double(step) * 0.5
            gps(&engine, kmh: 0, at: seconds)
            #expect(layout(engine, at: seconds) == .drive)
        }
        #expect(state(engine, at: 300).tires == nil)
    }

    // A parked screen chosen by a fresh car P shows P, also while GPS supplies the speed (the car
    // sends none); battery / range stays.
    @Test func speedlessPWithGPSAtRestIsParkedWithPLit() {
        var engine = authorized()
        gps(&engine, kmh: 0, at: 0)
        handle(&engine, .reading(CarReading(receivedAt: t0, carTimestamp: carEpoch, speedMetersPerSecond: nil, gear: .park,
                                            batteryPercent: 72, rangeKilometers: 315)), at: 0)
        handle(&engine, drive(.park, kmh: nil, at: 0.2), at: 0.2)
        let parked = state(engine, at: 0.2)
        #expect(parked.layout == .parked)
        #expect(parked.numeral == "0")
        #expect(parked.source == .valid(.gps))
        #expect(parked.gearRow == .park)
        #expect(!parked.showsParkedGear)
        #expect(parked.battery == .value(percent: 72, range: 315))
    }

    // GPS says the car moves: a speedless P is not parked and P is not lit, whichever came first.
    @Test(arguments: [true, false])
    func speedlessPWithGPSMovingIsNotParked(gpsFirst: Bool) {
        var engine = authorized()
        if gpsFirst { gps(&engine, kmh: 30, at: 0) }
        handle(&engine, drive(.park, kmh: nil, at: 0), at: 0)
        handle(&engine, drive(.park, kmh: nil, at: 0.2), at: 0.2)
        if !gpsFirst { gps(&engine, kmh: 30, at: 0.2) }
        let moving = state(engine, at: 0.2)
        #expect(moving.numeral == "30")
        #expect(moving.layout == .drive)
        #expect(moving.gearRow == nil)
        #expect(moving.battery == nil)
    }

    // MARK: 「P 檔」

    // S06-f: a fresh P with no speed: 「P 檔」 with 車速暫不可用, and no gear row.
    @Test func pGearWhenThereIsNoSpeed() {
        let engine = parked(kmh: nil)
        let parked = state(engine, at: 0.2)
        #expect(parked.layout == .parked)
        #expect(parked.showsParkedGear)
        #expect(parked.numeral == "—")
        #expect(parked.reason == .speedUnavailable)
        #expect(parked.gearRow == nil)
    }

    @Test func noPGearWhileTheSpeedShows() {
        let parked = state(parked(), at: 0.2)
        #expect(!parked.showsParkedGear)
        #expect(parked.gearRow == .park)
    }

    // MARK: Tires

    @Test func tiresShowDashesAndNoReadingsBeforeTheFirstReading() throws {
        let engine = parked()
        let wheels = try #require(tireWheels(engine, at: 0.2))
        #expect(wheels.all.allSatisfy { $0 == .missing })
        #expect(wheels.summary == .noReadings)
    }

    // The car reports bar; the app shows whole psi, rounded only after converting
    // (`TirePressure.psiPerBar` in TeslaBLE, mapped by the app).
    @Test func psiIsRoundedToAWholeNumber() throws {
        let psiPerBar = 14.5037738
        let tires = CarTires(frontLeft: tire(2.9 * psiPerBar, minutesAgo: 1, carTime: 0.2),   // 42.06
                             frontRight: tire(2.94 * psiPerBar, minutesAgo: 1, carTime: 0.2), // 42.64
                             rearLeft: tire(2.83 * psiPerBar, minutesAgo: 1, carTime: 0.2),   // 41.05
                             rearRight: tire(2.88 * psiPerBar, minutesAgo: 1, carTime: 0.2))  // 41.77
        let wheels = try #require(tireWheels(parked(tires: tires), at: 0.2))
        #expect(wheels.all.map(\.psi) == [42, 43, 41, 42])
    }

    @Test func freshReadingsShowTheOldestAge() throws {
        let tires = CarTires(frontLeft: tire(42, minutesAgo: 3, carTime: 0.2), frontRight: tire(42, minutesAgo: 1, carTime: 0.2),
                             rearLeft: tire(41, minutesAgo: 2, carTime: 0.2), rearRight: tire(42, minutesAgo: 3.5, carTime: 0.2))
        let wheels = try #require(tireWheels(parked(tires: tires), at: 0.2))
        #expect(wheels.all.allSatisfy { $0.freshness == .fresh && !$0.isDimmed })
        #expect(wheels.summary == .age(minutes: 3, partial: false))
    }

    // DESIGN.md: old readings dim wheel by wheel; the shared line names the oldest. Ages follow
    // the car's clock: a phone clock that is off changes nothing.
    @Test func staleTiresDimPerWheel() throws {
        let tires = CarTires(frontLeft: tire(42, minutesAgo: 1, carTime: 0.2), frontRight: tire(42, minutesAgo: 18, carTime: 0.2),
                             rearLeft: tire(41, minutesAgo: 15, carTime: 0.2), rearRight: tire(42, minutesAgo: 1, carTime: 0.2))
        let engine = parked(tires: tires)
        let wheels = try #require(tireWheels(engine, at: 0.2))
        #expect(wheels.frontLeft == TireWheel(psi: 42, ageMinutes: 1, freshness: .fresh))
        #expect(wheels.frontRight == TireWheel(psi: 42, ageMinutes: 18, freshness: .old))
        #expect(wheels.rearLeft.freshness == .fresh)
        #expect(wheels.all.map(\.isDimmed) == [false, true, false, false])
        #expect(wheels.summary == .age(minutes: 18, partial: true))
    }

    @Test func tiresAgeWhileParked() throws {
        let tires = CarTires(frontLeft: tire(42, minutesAgo: 14, carTime: 0.2), frontRight: tire(42, minutesAgo: 14, carTime: 0.2),
                             rearLeft: tire(41, minutesAgo: 14, carTime: 0.2), rearRight: tire(42, minutesAgo: 14, carTime: 0.2))
        var engine = parked(tires: tires)
        // Drive replies keep P fresh for two more minutes; no new tire reading.
        for step in 2...600 {
            let seconds = Double(step) * 0.2
            handle(&engine, drive(.park, at: seconds), at: seconds)
        }
        let wheels = try #require(tireWheels(engine, at: 120))
        #expect(wheels.all.allSatisfy { $0.freshness == .old && $0.ageMinutes == 15 })
        #expect(wheels.summary == .age(minutes: 15, partial: false))
    }

    // A missing time, or one ahead of the car's clock, is unknown; unknown wins the shared line.
    @Test func unknownTimesDimAndWinTheSharedLine() throws {
        let some = CarTires(frontLeft: tire(42, minutesAgo: 1, carTime: 0.2), frontRight: tire(42, minutesAgo: 18, carTime: 0.2),
                            rearLeft: tire(41, minutesAgo: nil, carTime: 0.2), rearRight: nil)
        let mixed = try #require(tireWheels(parked(tires: some), at: 0.2))
        #expect(mixed.all.map(\.freshness) == [.fresh, .old, .unknownTime, .missing])
        #expect(mixed.all.map(\.isDimmed) == [false, true, true, false])
        #expect(mixed.rearRight.psi == nil)
        #expect(mixed.summary == .someTimeUnknown)

        let all = CarTires(frontLeft: tire(42, minutesAgo: nil, carTime: 0.2), frontRight: tire(42, minutesAgo: -5, carTime: 0.2),
                           rearLeft: tire(41, minutesAgo: nil, carTime: 0.2), rearRight: tire(42, minutesAgo: nil, carTime: 0.2))
        let unknown = try #require(tireWheels(parked(tires: all), at: 0.2))
        #expect(unknown.all.allSatisfy { $0.freshness == .unknownTime && $0.ageMinutes == nil })
        #expect(unknown.summary == .timeUnknown)
    }

    @Test func aReplyWithNoWheelsShowsNoReadingsYet() throws {
        let none = CarTires(frontLeft: nil, frontRight: nil, rearLeft: nil, rearRight: nil)
        let wheels = try #require(tireWheels(parked(tires: none), at: 0.2))
        #expect(wheels.summary == .noReadings)
    }

    @Test func tiresAreForgottenInTheBackground() throws {
        let tires = CarTires(frontLeft: tire(42, minutesAgo: 1, carTime: 0.2), frontRight: nil, rearLeft: nil, rearRight: nil)
        var engine = parked(tires: tires)
        engine.suspend()
        engine.resume(now: t0 + 10)
        handle(&engine, drive(.park, at: 10.1), at: 10.1)
        handle(&engine, drive(.park, at: 10.3), at: 10.3)
        #expect(try #require(tireWheels(engine, at: 10.3)) == .noReadings)
    }

    // MARK: Battery age line

    // The parked screen keeps the last battery value with its own age (L21); the drive screen
    // shows `—% / — km` for the same state.
    @Test func staleBatteryKeepsItsValueAndAge() {
        var engine = authorized()
        handle(&engine, .reading(CarReading(receivedAt: t0, carTimestamp: carEpoch, batteryPercent: 72,
                                            rangeKilometers: 315)), at: 0)
        func park(through seconds: TimeInterval, from start: Int) {
            for step in start...Int(seconds * 5) {
                handle(&engine, drive(.park, at: Double(step) * 0.2), at: Double(step) * 0.2)
            }
        }
        park(through: 60, from: 1)
        #expect(state(engine, at: 60).battery == .value(percent: 72, range: 315))
        park(through: 61, from: 301)
        let parked = state(engine, at: 61)
        #expect(parked.layout == .parked)
        #expect(parked.battery == .stale(percent: 72, range: 315, ageMinutes: 1))
        park(through: 750, from: 306)
        #expect(state(engine, at: 750).battery == .stale(percent: 72, range: 315, ageMinutes: 12))
    }
}
