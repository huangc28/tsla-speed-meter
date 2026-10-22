import Foundation
import Testing
@testable import HUDCore

/// The acceptance criteria of #23, #24 and #25, now pinned in HUDCore (ADR 0001).
struct HUDEngineTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func expectNoSpeed(_ state: HUDState, reason: NoSpeedReason = .speedUnavailable,
                               sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(state.numeral == "—", sourceLocation: sourceLocation)
        #expect(state.reason == reason, sourceLocation: sourceLocation)
        #expect(state.gauge == .noData, sourceLocation: sourceLocation)
        #expect(state.source.marker != .valid, sourceLocation: sourceLocation)
    }

    // MARK: Showing a valid speed

    @Test func validGPSSpeedShowsNumeralUnitAndGPSSource() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        let state = engine.state(at: t0, unit: .kilometersPerHour)
        #expect(state.numeral == "72")
        #expect(state.reason == nil)
        #expect(state.unit.symbol == "km/h")
        #expect(state.source == .valid(.gps))
        #expect(state.source.marker == .valid)
        #expect(state.gauge == .live(kilometersPerHour: 72))
    }

    @Test func mphChangesOnlyTheNumeralAndUnitNotTheDial() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        let state = engine.state(at: t0, unit: .milesPerHour)
        #expect(state.numeral == "45")
        #expect(state.unit.symbol == "mph")
        #expect(state.gauge == .live(kilometersPerHour: 72))
    }

    // L32: values change instantly; every sample shows as it is.
    @Test func numeralUpdatesOnEverySampleWithoutLag() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(25, at: 1)), now: t0 + 1)
        #expect(engine.state(at: t0 + 1, unit: .kilometersPerHour).numeral == "90")
    }

    // A stop shows 0 on the first fix at or below 0.5 m/s, and moving off shows at once.
    @Test func stopShowsZeroOnTheFirstSlowFixAndMovingOffShowsAtOnce() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(0.5, at: 1)), now: t0 + 1)
        let stopped = engine.state(at: t0 + 1, unit: .kilometersPerHour)
        #expect(stopped.numeral == "0")
        #expect(stopped.gauge == .live(kilometersPerHour: 0))
        engine.handle(.sample(fix(0.6, at: 2)), now: t0 + 2)
        #expect(engine.state(at: t0 + 2, unit: .kilometersPerHour).numeral == "2")
    }

    // #23: a valid real 0 shows on the drive screen as a 0 with the dial, never as "—".
    @Test func gpsZeroForSixtySecondsShowsARealZero() {
        var engine = authorized()
        for second in 0...60 {
            let now = t0 + TimeInterval(second)
            engine.handle(.sample(fix(0, at: TimeInterval(second))), now: now)
            let state = engine.state(at: now, unit: .kilometersPerHour)
            #expect(state.numeral == "0")
            #expect(state.gauge == .live(kilometersPerHour: 0))
            #expect(state.source == .valid(.gps))
        }
    }

    // MARK: #24 — no valid speed shows "—" with a reason, never 0

    @Test func coldStartWithoutPermissionDecisionShowsDashAndWaiting() {
        let state = HUDEngine().state(at: t0, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .waiting)
        #expect(state.source.marker == .waiting)
    }

    @Test func authorizedWithoutAFixShowsDashAndSearching() {
        let state = authorized().state(at: t0 + 30, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .searchingGPS)
        #expect(state.numeral != "0")
    }

    @Test func permissionDeniedShowsDashAndGPSUnavailable() {
        var engine = HUDEngine()
        engine.handle(.authorization(.denied), now: t0)
        let state = engine.state(at: t0, unit: .kilometersPerHour)
        expectNoSpeed(state, reason: .gpsUnavailable)
        #expect(state.source == .gpsUnavailable)
    }

    @Test func permissionRevokedWhileDrivingDropsTheSpeedAtOnce() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.authorization(.denied), now: t0 + 0.5)
        expectNoSpeed(engine.state(at: t0 + 0.5, unit: .kilometersPerHour), reason: .gpsUnavailable)
    }

    // MARK: #25 — values expire and are never frozen

    @Test func rejectedLowAccuracySampleIsNotAFixAndSpeedExpires() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(20, at: 1, accuracy: 120)), now: t0 + 1)
        #expect(engine.state(at: t0 + 1, unit: .kilometersPerHour).numeral == "72")
        let later = engine.state(at: t0 + 2.5, unit: .kilometersPerHour)
        expectNoSpeed(later)
        #expect(later.source == .speedUnavailable)
    }

    @Test func noNewReadingExpiresWithoutAnotherEvent() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        #expect(engine.state(at: t0 + 1.9, unit: .kilometersPerHour).numeral == "72")
        expectNoSpeed(engine.state(at: t0 + 2.1, unit: .kilometersPerHour))
    }

    @Test func streamEndShowsDashAndLostChipImmediately() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.ended, now: t0 + 0.1)
        let state = engine.state(at: t0 + 0.1, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .speedUnavailable)
    }

    @Test func streamEndBeforeAnyFixShowsDashAndSearching() {
        var engine = authorized()
        engine.handle(.ended, now: t0)
        let state = engine.state(at: t0, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .searchingGPS)
    }

    @Test func locationErrorShowsDashImmediately() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.failed, now: t0 + 0.1)
        expectNoSpeed(engine.state(at: t0 + 0.1, unit: .kilometersPerHour))
    }

    @Test(arguments: [Double.nan, -1])
    func invalidSpeedValueOnItsOwnShowsDash(_ value: Double) {
        var engine = authorized()
        engine.handle(.sample(fix(value, at: 0)), now: t0)
        expectNoSpeed(engine.state(at: t0, unit: .kilometersPerHour))
    }

    @Test func futureTimestampOnItsOwnShowsDash() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 10)), now: t0)
        expectNoSpeed(engine.state(at: t0, unit: .kilometersPerHour))
    }

    // The backwards sample is still young enough to pass the age rule: only the order rule stops it.
    @Test func backwardsTimestampIsNotShown() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(30, at: -0.5)), now: t0 + 0.1)
        #expect(engine.state(at: t0 + 0.1, unit: .kilometersPerHour).numeral == "72")
        expectNoSpeed(engine.state(at: t0 + 2.05, unit: .kilometersPerHour))
    }

    @Test func validSpeedReturnsAfterExpiry() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(10, at: 5)), now: t0 + 5)
        let state = engine.state(at: t0 + 5, unit: .kilometersPerHour)
        #expect(state.numeral == "36")
        #expect(state.source == .valid(.gps))
    }

    // MARK: Background and foreground (01 §3.2, S04-g)

    @Test func suspendDropsTheSpeedAtOnce() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.suspend()
        expectNoSpeed(engine.state(at: t0 + 0.1, unit: .kilometersPerHour))
    }

    @Test func resumeWaitsForTheFirstNewValidReading() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.suspend()
        engine.resume(now: t0 + 29)
        let waiting = engine.state(at: t0 + 30, unit: .kilometersPerHour)
        expectNoSpeed(waiting)
        #expect(waiting.source == .waiting)

        engine.handle(.sample(fix(20, at: 30, accuracy: 90)), now: t0 + 30)
        #expect(engine.state(at: t0 + 30, unit: .kilometersPerHour).source == .waiting)

        engine.handle(.sample(fix(10, at: 31)), now: t0 + 31)
        let back = engine.state(at: t0 + 31, unit: .kilometersPerHour)
        #expect(back.numeral == "36")
        #expect(back.source == .valid(.gps))
    }

    // After the first new reading, waiting is over: its expiry reads "Speed unavailable".
    @Test func resumeThenValidReadingThenExpiryEndsOnSpeedUnavailable() {
        var engine = authorized()
        engine.suspend()
        engine.resume(now: t0)
        engine.handle(.sample(fix(20, at: 0.5)), now: t0 + 0.5)
        #expect(engine.state(at: t0 + 0.5, unit: .kilometersPerHour).numeral == "72")
        let expired = engine.state(at: t0 + 3, unit: .kilometersPerHour)
        expectNoSpeed(expired)
        #expect(expired.source == .speedUnavailable)
    }

    // 01 §3.2: a fix taken before the resume is a background reading, however young it is.
    @Test func fixStampedBeforeResumeIsRejected() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.suspend()
        engine.resume(now: t0 + 1.5)
        engine.handle(.sample(fix(25, at: 1.0)), now: t0 + 1.6)
        let state = engine.state(at: t0 + 1.6, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .waiting)
        #expect(engine.processor.speed(at: t0 + 1.6) == nil)
    }

    // 01 §3.2: samples while suspended are ignored, so nothing shows just before the resume.
    @Test func sampleWhileSuspendedIsIgnored() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.suspend()
        engine.handle(.sample(fix(25, at: 0.5)), now: t0 + 0.6)
        let state = engine.state(at: t0 + 0.6, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .waiting)
    }

    @Test func readingFromBeforeTheResumeIsNotShown() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.suspend()
        engine.handle(.sample(fix(25, at: 0.5)), now: t0 + 0.6)
        engine.resume(now: t0 + 0.65)
        expectNoSpeed(engine.state(at: t0 + 0.7, unit: .kilometersPerHour))
    }

    // A failure after the resume wins over waiting.
    @Test(arguments: [LocationEvent.failed, .ended])
    func failureAfterResumeShowsSpeedUnavailable(_ failure: LocationEvent) {
        var engine = authorized()
        engine.suspend()
        engine.resume(now: t0)
        engine.handle(failure, now: t0 + 0.5)
        let state = engine.state(at: t0 + 0.5, unit: .kilometersPerHour)
        expectNoSpeed(state)
        #expect(state.source == .speedUnavailable)
    }

    @Test func deniedWinsOverWaitingAfterResume() {
        var engine = authorized()
        engine.resume(now: t0)
        engine.handle(.authorization(.denied), now: t0)
        #expect(engine.state(at: t0, unit: .kilometersPerHour).source == .gpsUnavailable)
    }
}
