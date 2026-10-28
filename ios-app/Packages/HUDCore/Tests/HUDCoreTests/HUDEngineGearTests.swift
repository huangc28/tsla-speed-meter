import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A drive reply that reached the phone at `t0 + seconds`, stamped `carTime` (default `seconds`).
private func drive(_ gear: CarGear?, kmh: Double = 40, at seconds: TimeInterval, carTime: TimeInterval? = nil) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + (carTime ?? seconds),
                        speedMetersPerSecond: kmh / 3.6, gear: gear))
}

/// #48: the gear row `P R N D` (L43): shown only for a fresh Car Bluetooth gear, after 2
/// distinct, in-order readings, and hidden as a whole otherwise.
struct HUDEngineGearTests {
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

    private func gearRow(_ engine: HUDEngine, at seconds: TimeInterval) -> CarGear? {
        engine.state(at: t0 + seconds, unit: .kilometersPerHour).gearRow
    }

    /// Two fresh readings in D, the second at `t0 + seconds`.
    private func showingD(at seconds: TimeInterval = 0.2) -> HUDEngine {
        var engine = authorized()
        handle(&engine, drive(.drive, at: seconds - 0.2), at: seconds - 0.2)
        handle(&engine, drive(.drive, at: seconds), at: seconds)
        return engine
    }

    // MARK: Showing

    @Test func showsOnlyAfterTwoDistinctInOrderReadings() {
        var engine = authorized()
        handle(&engine, drive(.drive, at: 0), at: 0)
        // The speed shows at once (cold start); the gear row does not.
        #expect(engine.state(at: t0, unit: .kilometersPerHour).numeral == "40")
        #expect(gearRow(engine, at: 0) == nil)
        // The same car timestamp again, and an older one: not a second reading.
        handle(&engine, drive(.drive, at: 0.2, carTime: 0), at: 0.2)
        #expect(gearRow(engine, at: 0.2) == nil)
        handle(&engine, drive(.drive, at: 0.3, carTime: -1), at: 0.3)
        #expect(gearRow(engine, at: 0.3) == nil)
        handle(&engine, drive(.drive, at: 0.4), at: 0.4)
        #expect(gearRow(engine, at: 0.4) == .drive)
    }

    @Test func theTwoReadingsMustComeInARow() {
        var engine = authorized()
        handle(&engine, drive(.drive, at: 0), at: 0)
        // The first expired before the second came.
        handle(&engine, drive(.drive, at: 3), at: 3)
        #expect(gearRow(engine, at: 3) == nil)
        handle(&engine, drive(.drive, at: 3.2), at: 3.2)
        #expect(gearRow(engine, at: 3.2) == .drive)
    }

    @Test func followsTheLatestGear() {
        var engine = showingD()
        handle(&engine, drive(.neutral, kmh: 3, at: 0.4), at: 0.4)
        #expect(gearRow(engine, at: 0.4) == .neutral)
    }

    // MARK: Hiding

    @Test func hidesOnGPSFallback() {
        var engine = showingD()
        gps(&engine, kmh: 38, at: 2.1)
        let fallback = engine.state(at: t0 + 2.3, unit: .kilometersPerHour)
        #expect(fallback.source == .gpsFallback)
        #expect(fallback.gearRow == nil)
    }

    @Test func hidesOnStaleCarData() {
        let engine = showingD()
        #expect(gearRow(engine, at: 2.2) == .drive)
        #expect(gearRow(engine, at: 2.3) == nil)
    }

    @Test func hidesAtOnceWhenTheLinkIsLostAndNeedsTwoReadingsAfterReconnecting() {
        var engine = showingD()
        handle(&engine, .link(.lost), at: 0.5)
        #expect(gearRow(engine, at: 0.5) == nil)
        handle(&engine, .link(.connected), at: 1)
        handle(&engine, drive(.drive, at: 1.1), at: 1.1)
        #expect(gearRow(engine, at: 1.1) == nil)
        handle(&engine, drive(.drive, at: 1.3), at: 1.3)
        #expect(gearRow(engine, at: 1.3) == .drive)
    }

    @Test func hidesOnAnUnknownGearAndNeedsTwoReadingsToReturn() {
        var engine = showingD()
        handle(&engine, drive(nil, at: 0.4), at: 0.4)
        #expect(gearRow(engine, at: 0.4) == nil)
        // The speed still shows.
        #expect(engine.state(at: t0 + 0.4, unit: .kilometersPerHour).numeral == "40")
        handle(&engine, drive(.drive, at: 0.6), at: 0.6)
        #expect(gearRow(engine, at: 0.6) == nil)
        handle(&engine, drive(.drive, at: 0.8), at: 0.8)
        #expect(gearRow(engine, at: 0.8) == .drive)
    }

    @Test func hidesWithNoSpeed() {
        var engine = authorized()
        handle(&engine, drive(.drive, at: 0), at: 0)
        handle(&engine, drive(.drive, at: 3), at: 3)
        handle(&engine, drive(.drive, at: 3.2), at: 3.2)
        #expect(gearRow(engine, at: 3.2) == .drive)
        // A reading with a gear but no speed does not keep the row on screen.
        engine.handle(.reading(CarReading(receivedAt: t0 + 3.4, carTimestamp: carEpoch + 3.4, gear: .drive)), now: t0 + 3.4)
        #expect(engine.state(at: t0 + 5.3, unit: .kilometersPerHour).numeral == "—")
        #expect(gearRow(engine, at: 5.3) == nil)
    }

    // The feed disconnected on request and is not trying (the test page's 斷線, pairing cancelled).
    @Test func hidesAtOnceWhenTheLinkGoesIdleAndNeedsTwoReadingsAfterReconnecting() {
        var engine = showingD()
        handle(&engine, .link(.idle), at: 0.3)
        #expect(gearRow(engine, at: 0.3) == nil)
        handle(&engine, .link(.connected), at: 1)
        handle(&engine, drive(.drive, at: 1.1), at: 1.1)
        #expect(gearRow(engine, at: 1.1) == nil)
        handle(&engine, drive(.drive, at: 1.3), at: 1.3)
        #expect(gearRow(engine, at: 1.3) == .drive)
    }

    @Test func lateReadingsAfterIdleDoNotBringTheRowBack() {
        var engine = showingD()
        handle(&engine, .link(.idle), at: 0.3)
        handle(&engine, drive(.drive, at: 0.4), at: 0.4)
        handle(&engine, drive(.drive, at: 0.6), at: 0.6)
        #expect(gearRow(engine, at: 0.6) == nil)
        // The speed rules (#46) are unchanged: a fresh car speed still shows.
        #expect(engine.state(at: t0 + 0.6, unit: .kilometersPerHour).numeral == "40")
    }

    @Test func hidesWhenNotPaired() {
        var engine = showingD()
        handle(&engine, .link(.notPaired), at: 0.3)
        #expect(gearRow(engine, at: 0.3) == nil)
    }

    @Test func hidesInTheBackgroundAndStartsOverAfterResume() {
        var engine = showingD()
        engine.suspend()
        #expect(gearRow(engine, at: 0.3) == nil)
        engine.resume(now: t0 + 10)
        handle(&engine, drive(.drive, at: 10.1), at: 10.1)
        #expect(gearRow(engine, at: 10.1) == nil)
        handle(&engine, drive(.drive, at: 10.3), at: 10.3)
        #expect(gearRow(engine, at: 10.3) == .drive)
    }

    // A fresh P while a valid speed of 5 km/h or more says the car is moving (L43). Like any
    // other hide, the row returns only after 2 more readings that may show it.
    @Test func parkWhileMovingHides() {
        var engine = authorized()
        handle(&engine, drive(.park, kmh: 4, at: 0), at: 0)
        handle(&engine, drive(.park, kmh: 4, at: 0.2), at: 0.2)
        #expect(gearRow(engine, at: 0.2) == .park)
        handle(&engine, drive(.park, kmh: 5, at: 0.4), at: 0.4)
        #expect(gearRow(engine, at: 0.4) == nil)
        handle(&engine, drive(.park, kmh: 30, at: 0.6), at: 0.6)
        #expect(gearRow(engine, at: 0.6) == nil)
        handle(&engine, drive(.park, kmh: 0, at: 0.8), at: 0.8)
        #expect(gearRow(engine, at: 0.8) == nil)
        handle(&engine, drive(.park, kmh: 0, at: 1), at: 1)
        #expect(gearRow(engine, at: 1) == .park)
    }

    // #43 story 24: a P that flickers around 5 km/h never makes the row blink.
    @Test func parkAroundFiveKilometersPerHourNeverBlinks() {
        var engine = authorized()
        for (step, kmh) in [5.0, 5, 4, 5, 4, 5, 4].enumerated() {
            let seconds = Double(step) * 0.2
            handle(&engine, drive(.park, kmh: kmh, at: seconds), at: seconds)
            #expect(gearRow(engine, at: seconds) == nil, "P at \(kmh) km/h, reading \(step + 1)")
        }
    }

    @Test func aDriveReadingAfterParkWhileMovingNeedsASecondOne() {
        var engine = authorized()
        handle(&engine, drive(.park, kmh: 30, at: 0), at: 0)
        handle(&engine, drive(.park, kmh: 30, at: 0.2), at: 0.2)
        handle(&engine, drive(.drive, kmh: 30, at: 0.4), at: 0.4)
        #expect(gearRow(engine, at: 0.4) == nil)
        handle(&engine, drive(.drive, kmh: 30, at: 0.6), at: 0.6)
        #expect(gearRow(engine, at: 0.6) == .drive)
    }

    @Test func otherGearsShowAtAnySpeed() {
        var engine = authorized()
        handle(&engine, drive(.drive, kmh: 130, at: 0), at: 0)
        handle(&engine, drive(.drive, kmh: 130, at: 0.2), at: 0.2)
        #expect(gearRow(engine, at: 0.2) == .drive)
    }

    // MARK: Reverse

    @Test func reverseLightsRAndShowsTheSpeedWithoutAMinus() {
        var engine = authorized()
        handle(&engine, drive(.reverse, kmh: -6, at: 0), at: 0)
        handle(&engine, drive(.reverse, kmh: -7, at: 0.2), at: 0.2)
        let reversing = engine.state(at: t0 + 0.2, unit: .kilometersPerHour)
        #expect(reversing.gearRow == .reverse)
        #expect(reversing.numeral == "7")
    }
}
