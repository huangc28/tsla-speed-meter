import Foundation
import Testing
@testable import HUDCore

/// The car's own clock runs on another epoch than the phone's: readings are ordered by it,
/// never compared with phone time.
private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A car reading that reached the phone at `t0 + seconds`, stamped `carTime` (default
/// `seconds`) on the car's clock.
private func car(kmh: Double?, at seconds: TimeInterval, carTime: TimeInterval? = nil) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + (carTime ?? seconds),
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }))
}

/// #46: the drive screen shows the car's speed, car first, GPS fallback (L7, L9).
struct HUDEngineCarTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func kmh(_ value: Double) -> Double { value / 3.6 }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func gps(_ engine: inout HUDEngine, kmh value: Double, at seconds: TimeInterval) {
        engine.handle(.sample(fix(kmh(value), at: seconds)), now: t0 + seconds)
    }

    private func state(_ engine: HUDEngine, at seconds: TimeInterval, unit: SpeedUnit = .kilometersPerHour) -> HUDState {
        engine.state(at: t0 + seconds, unit: unit)
    }

    // MARK: Car first

    @Test func validCarSpeedWinsOverValidGPS() {
        var engine = authorized()
        gps(&engine, kmh: 72, at: 0)
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        let shown = state(engine, at: 0)
        #expect(shown.numeral == "75")
        #expect(shown.reason == nil)
        #expect(shown.source == .valid(.carBluetooth))
        #expect(shown.source.marker == .valid)
    }

    @Test func coldStartShowsTheFirstValidCarReadingAtOnce() {
        // Before any location decision and before any GPS fix.
        var engine = HUDEngine()
        handle(&engine, car(kmh: 30, at: 0), at: 0)
        #expect(state(engine, at: 0).numeral == "30")
        #expect(state(engine, at: 0).source == .valid(.carBluetooth))
    }

    @Test func coldStartShowsTheFirstCarReadingEvenWhileGPSShows() {
        var engine = authorized()
        gps(&engine, kmh: 72, at: 0)
        #expect(state(engine, at: 0).source == .valid(.gps))
        handle(&engine, car(kmh: 75, at: 0.5), at: 0.5)
        #expect(state(engine, at: 0.5).numeral == "75")
        #expect(state(engine, at: 0.5).source == .valid(.carBluetooth))
    }

    // MARK: Fallback after 2 s, by phone receive time

    @Test func fallsBackToGPSOnceTheCarSpeedIsMoreThanTwoSecondsOld() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        gps(&engine, kmh: 72, at: 1)
        gps(&engine, kmh: 72, at: 2)
        #expect(state(engine, at: 1.9).numeral == "75")
        #expect(state(engine, at: 2.0).source == .valid(.carBluetooth))
        let fallback = state(engine, at: 2.1)
        #expect(fallback.numeral == "72")
        #expect(fallback.source == .gpsFallback)
        #expect(fallback.source.marker == .fallback)
    }

    @Test func freshnessIsJudgedByPhoneReceiveTimeNotTheCarClock() {
        var engine = authorized()
        // The car's clock is far behind the phone's; the reading just arrived.
        handle(&engine, car(kmh: 75, at: 10, carTime: -5_000), at: 10)
        #expect(state(engine, at: 11.9).numeral == "75")
        #expect(state(engine, at: 12.1).numeral == "—")
    }

    // MARK: Return after 2 distinct, in-order readings

    @Test func returnFromGPSNeedsTwoDistinctInOrderCarReadings() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        gps(&engine, kmh: 72, at: 3)
        #expect(state(engine, at: 3).source == .gpsFallback)

        gps(&engine, kmh: 72, at: 4)
        handle(&engine, car(kmh: 80, at: 4), at: 4)
        #expect(state(engine, at: 4).numeral == "72")
        #expect(state(engine, at: 4).source == .gpsFallback)
        // The same car timestamp again: not a second reading.
        handle(&engine, car(kmh: 81, at: 4.2, carTime: 4), at: 4.2)
        #expect(state(engine, at: 4.2).source == .gpsFallback)
        // An older car timestamp: not a second reading either.
        handle(&engine, car(kmh: 82, at: 4.4, carTime: 3.5), at: 4.4)
        #expect(state(engine, at: 4.4).source == .gpsFallback)

        handle(&engine, car(kmh: 83, at: 4.6), at: 4.6)
        let back = state(engine, at: 4.6)
        #expect(back.numeral == "83")
        #expect(back.source == .valid(.carBluetooth))
    }

    @Test func theTwoReturnReadingsMustComeInARow() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        handle(&engine, car(kmh: 80, at: 3), at: 3)
        // The first return reading expired before the next one came.
        gps(&engine, kmh: 72, at: 6)
        handle(&engine, car(kmh: 80, at: 6), at: 6)
        #expect(state(engine, at: 6).source == .gpsFallback)
        handle(&engine, car(kmh: 80, at: 6.2), at: 6.2)
        #expect(state(engine, at: 6.2).source == .valid(.carBluetooth))
    }

    // L7: with no valid source in between, the return still needs 2 readings and shows "—" meanwhile.
    @Test func returnWithoutGPSShowsDashUntilTheSecondReading() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        let gap = state(engine, at: 3)
        #expect(gap.numeral == "—")
        #expect(gap.reason == .speedUnavailable)
        #expect(gap.source == .speedUnavailable)

        handle(&engine, car(kmh: 40, at: 5), at: 5)
        #expect(state(engine, at: 5).numeral == "—")
        handle(&engine, car(kmh: 41, at: 5.2), at: 5.2)
        #expect(state(engine, at: 5.2).numeral == "41")
    }

    // 01 §3.2 rule 3: a repeated car timestamp is not a new reading. It may update the shown
    // value, but the 2 s window runs from the first arrival of that timestamp, so a frozen
    // drive state never keeps ● 車輛藍牙 on screen while replies keep coming.
    @Test func aRepeatedCarTimestampNeverExtendsTheTwoSecondWindow() {
        var engine = authorized()
        var dashSeen = false
        for step in 0...15 {
            let seconds = Double(step) * 0.2
            handle(&engine, car(kmh: 30 + Double(step), at: seconds, carTime: 0), at: seconds)
            let shown = state(engine, at: seconds)
            if seconds <= 2 {
                #expect(shown.source == .valid(.carBluetooth))
                #expect(shown.numeral == "\(30 + step)")
            } else {
                #expect(shown.numeral == "—")
                #expect(shown.source == .speedUnavailable)
                dashSeen = true
            }
        }
        #expect(dashSeen)
    }

    @Test func aRepeatedCarTimestampFallsBackToGPSWhenGPSIsValid() {
        var engine = authorized()
        for step in 0...15 {
            let seconds = Double(step) * 0.2
            gps(&engine, kmh: 72, at: seconds)
            handle(&engine, car(kmh: 50, at: seconds, carTime: 0), at: seconds)
            let shown = state(engine, at: seconds)
            #expect(shown.numeral == (seconds <= 2 ? "50" : "72"))
            #expect(shown.source == (seconds <= 2 ? .valid(.carBluetooth) : .gpsFallback))
        }
    }

    @Test func anOlderCarTimestampIsIgnored() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0, carTime: 10), at: 0)
        handle(&engine, car(kmh: 20, at: 0.2, carTime: 9), at: 0.2)
        #expect(state(engine, at: 0.2).numeral == "75")
        // It did not renew the speed either.
        #expect(state(engine, at: 2.1).numeral == "—")
    }

    @Test func aSpeedWithoutACarTimestampIsNotShown() {
        var engine = authorized()
        engine.handle(.reading(CarReading(receivedAt: t0, carTimestamp: nil, speedMetersPerSecond: kmh(75))), now: t0)
        #expect(state(engine, at: 0).numeral == "—")
        #expect(state(engine, at: 0).source == .searchingGPS)
    }

    @Test func aReadingWithoutASpeedNeitherShowsNorRenewsOne() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        engine.handle(.reading(CarReading(receivedAt: t0 + 1.5, carTimestamp: carEpoch + 1.5, batteryPercent: 72)), now: t0 + 1.5)
        #expect(state(engine, at: 2.1).numeral == "—")
    }

    @Test(arguments: [Double.nan, .infinity])
    func anInvalidCarSpeedIsNotShown(_ value: Double) {
        var engine = authorized()
        engine.handle(.reading(CarReading(receivedAt: t0, carTimestamp: carEpoch, speedMetersPerSecond: value)), now: t0)
        #expect(state(engine, at: 0).numeral == "—")
    }

    // MARK: "—" when neither source is valid

    @Test func dashWithAReasonWhenNeitherSourceIsValid() {
        var engine = authorized()
        gps(&engine, kmh: 72, at: 0)
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        let none = state(engine, at: 2.5)
        #expect(none.numeral == "—")
        #expect(none.numeral != "0")
        #expect(none.reason == .speedUnavailable)
        #expect(none.source == .speedUnavailable)
        #expect(none.source.marker == .noSpeed)
    }

    // MARK: Whole km/h, no dead-band, magnitude, mph

    @Test func carSpeedIsWholeKilometersPerHourWithNoDeadBand() {
        var engine = authorized()
        handle(&engine, car(kmh: 1, at: 0), at: 0)
        #expect(state(engine, at: 0).numeral == "1")
        // 0.5 m/s (1.8 km/h) is "0" on GPS, but the car's own speed shows as is.
        engine.handle(.reading(CarReading(receivedAt: t0 + 0.2, carTimestamp: carEpoch + 0.2, speedMetersPerSecond: 0.5)), now: t0 + 0.2)
        #expect(state(engine, at: 0.2).numeral == "2")
        handle(&engine, car(kmh: 0, at: 0.4), at: 0.4)
        #expect(state(engine, at: 0.4).numeral == "0")
    }

    // The car reports mph converted from whole km/h: rounding to the nearest gets the km/h back.
    @Test(arguments: [23, 39, 97, 130])
    func carSpeedRoundsToTheNearestWholeKilometerPerHour(_ dashboard: Int) {
        let mph = Float(Double(dashboard) / 1.609344)
        var engine = authorized()
        engine.handle(.reading(CarReading(receivedAt: t0, carTimestamp: carEpoch, speedMetersPerSecond: Double(mph) * 0.44704)), now: t0)
        #expect(state(engine, at: 0).numeral == "\(dashboard)")
    }

    @Test func reverseShowsTheSpeedWithoutAMinus() {
        var engine = authorized()
        handle(&engine, car(kmh: -3, at: 0), at: 0)
        let reversing = state(engine, at: 0)
        #expect(reversing.numeral == "3")
    }

    @Test func mphConvertsTheCarSpeed() {
        var engine = authorized()
        handle(&engine, car(kmh: 100, at: 0), at: 0)
        let shown = state(engine, at: 0, unit: .milesPerHour)
        #expect(shown.numeral == "62")
        #expect(shown.unit == .milesPerHour)
    }

    // MARK: Source chip

    @Test func gpsChipIsPlainBeforeAnyCarReading() {
        var engine = authorized()
        handle(&engine, .link(.connecting), at: 0)
        gps(&engine, kmh: 72, at: 0)
        #expect(state(engine, at: 0).source == .valid(.gps))
        handle(&engine, .link(.connected), at: 0.5)
        #expect(state(engine, at: 0.5).source == .valid(.gps))
    }

    @Test func gpsChipIsPlainWhenNotPaired() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        gps(&engine, kmh: 72, at: 2.5)
        #expect(state(engine, at: 2.5).source == .gpsFallback)
        handle(&engine, .link(.notPaired), at: 2.6)
        #expect(state(engine, at: 2.6).source == .valid(.gps))
        #expect(state(engine, at: 2.6).numeral == "72")
    }

    // L9: no location permission takes away GPS only, never a valid car speed.
    @Test func deniedLocationKeepsAValidCarSpeed() {
        var engine = HUDEngine()
        engine.handle(.authorization(.denied), now: t0)
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        let shown = state(engine, at: 0)
        #expect(shown.numeral == "75")
        #expect(shown.source == .valid(.carBluetooth))
        #expect(state(engine, at: 2.5).numeral == "—")
    }

    // MARK: Background and foreground

    @Test func suspendDropsTheCarSpeedAndIgnoresReadingsUntilResume() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        engine.suspend()
        #expect(state(engine, at: 0.1).numeral == "—")
        handle(&engine, car(kmh: 75, at: 0.2), at: 0.2)
        #expect(state(engine, at: 0.2).numeral == "—")
    }

    @Test func resumeStartsAFreshForegroundSession() {
        var engine = authorized()
        handle(&engine, car(kmh: 75, at: 0), at: 0)
        engine.suspend()
        engine.resume(now: t0 + 30)
        // Not seen this session: plain GPS chip.
        gps(&engine, kmh: 72, at: 31)
        #expect(state(engine, at: 31).source == .valid(.gps))
        // Cold start again: the first reading shows at once, even with an older car clock.
        handle(&engine, car(kmh: 50, at: 31.5, carTime: -100), at: 31.5)
        #expect(state(engine, at: 31.5).numeral == "50")
        #expect(state(engine, at: 31.5).source == .valid(.carBluetooth))
    }
}
