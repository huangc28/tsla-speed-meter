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
        #expect(state.layout == .drive, sourceLocation: sourceLocation)
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
        #expect(state.layout == .drive)
    }

    @Test func mphChangesOnlyTheNumeralAndUnitNotTheDial() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        let state = engine.state(at: t0, unit: .milesPerHour)
        #expect(state.numeral == "45")
        #expect(state.unit.symbol == "mph")
        #expect(state.gauge == .live(kilometersPerHour: 72))
    }

    @Test func numeralUpdatesOnEverySampleWithoutHoldingTheOldValue() {
        var engine = HUDEngine(processor: GPSSpeedProcessor(smoothing: 1))
        engine.handle(.authorization(.authorized), now: t0)
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(25, at: 1)), now: t0 + 1)
        #expect(engine.state(at: t0 + 1, unit: .kilometersPerHour).numeral == "90")
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

    @Test func futureOrBackwardsTimestampsOnTheirOwnShowDash() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 10)), now: t0)
        expectNoSpeed(engine.state(at: t0, unit: .kilometersPerHour))

        engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(30, at: -1)), now: t0 + 2.5)
        expectNoSpeed(engine.state(at: t0 + 2.5, unit: .kilometersPerHour))
    }

    @Test func validSpeedReturnsAfterExpiry() {
        var engine = authorized()
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        engine.handle(.sample(fix(10, at: 5)), now: t0 + 5)
        let state = engine.state(at: t0 + 5, unit: .kilometersPerHour)
        #expect(state.numeral == "36")
        #expect(state.source == .valid(.gps))
    }

    // MARK: #23 — GPS low speed never switches to parked

    @Test func gpsZeroForSixtySecondsStaysOnDriveAndShowsARealZero() {
        var engine = authorized()
        for second in 0...60 {
            let now = t0 + TimeInterval(second)
            engine.handle(.sample(fix(0, at: TimeInterval(second))), now: now)
            let state = engine.state(at: now, unit: .kilometersPerHour)
            #expect(state.layout == .drive)
            #expect(state.numeral == "0")
            #expect(state.gauge == .live(kilometersPerHour: 0))
            #expect(state.source == .valid(.gps))
        }
    }

    @Test func noFixStartsOnDrive() {
        #expect(HUDEngine().state(at: t0, unit: .kilometersPerHour).layout == .drive)
        #expect(authorized().state(at: t0 + 60, unit: .kilometersPerHour).layout == .drive)
    }

    @Test func slowingDownThroughZeroAndBackStaysOnDrive() {
        var engine = authorized()
        let speeds: [Double] = [10, 3, 1, 0.4, 0, 0, 0.3, 2, 8]
        for (i, speed) in speeds.enumerated() {
            let now = t0 + TimeInterval(i)
            engine.handle(.sample(fix(speed, at: TimeInterval(i))), now: now)
            #expect(engine.state(at: now, unit: .kilometersPerHour).layout == .drive)
        }
    }

    // MARK: GPS-only screen content

    @Test func gearRowAndBatteryAreHiddenOnGPS() {
        var engine = authorized()
        let searching = engine.state(at: t0, unit: .kilometersPerHour)
        #expect(!searching.showsGearRow)
        #expect(!searching.showsBattery)
        engine.handle(.sample(fix(20, at: 0)), now: t0)
        let driving = engine.state(at: t0, unit: .kilometersPerHour)
        #expect(!driving.showsGearRow)
        #expect(!driving.showsBattery)
    }
}
