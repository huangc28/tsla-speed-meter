import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A reply that reached the phone at `t0 + seconds`, stamped with the car's own time: drive state in
/// `gear` with the odometer, and whatever else is given.
private func reply(_ gear: CarGear = .park, odometer: Int? = 767_100, closures: CarClosures? = nil,
                   climate: CarClimate? = nil, at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds, speedMetersPerSecond: 0, gear: gear,
                        closures: closures, odometerHundredthsOfAMile: odometer, climate: climate))
}

/// Closures at the car time `seconds` with these windows (driver front, driver rear, passenger front,
/// passenger rear).
private func windows(_ windows: [Bool?], at seconds: TimeInterval) -> CarClosures {
    CarClosures(frontTrunk: false, rearTrunk: false, doors: [false, false, false, false], windows: windows,
                carTime: carEpoch + seconds)
}

/// #79: the 車況 card (07 §2.3, §4, §5): odometer, outside and inside temperature, windows; a row whose
/// value is missing is not drawn.
struct HUDEngineVehicleTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func vehicle(_ engine: HUDEngine, at seconds: TimeInterval, unit: SpeedUnit = .kilometersPerHour) -> VehicleCard? {
        engine.state(at: t0 + seconds, unit: unit).vehicle
    }

    /// Parked at `t0 + 0.2`, the second P reading carrying `closures` and `climate`.
    private func parked(closures: CarClosures? = nil, climate: CarClimate? = nil, odometer: Int? = 767_100) -> HUDEngine {
        var engine = authorized()
        handle(&engine, reply(odometer: odometer, at: 0), at: 0)
        handle(&engine, reply(odometer: odometer, closures: closures, climate: climate, at: 0.2), at: 0.2)
        #expect(engine.state(at: t0 + 0.2, unit: .kilometersPerHour).layout == .parked)
        return engine
    }

    @Test func everyRowFromTheCar() {
        let engine = parked(closures: windows([false, false, false, false], at: 0.2),
                            climate: CarClimate(outsideCelsius: 23.4, insideCelsius: 26))
        #expect(vehicle(engine, at: 0.2) == VehicleCard(odometer: 12_345, outsideCelsius: 23.4, insideCelsius: 26, windows: .allClosed))
        // 7,671 mi = 12,345.27 km; miles in mph mode.
        #expect(vehicle(engine, at: 0.2, unit: .milesPerHour)?.odometer == 7_671)
    }

    // Miles come straight from the car's hundredths, rounded down; no round trip through km loses one.
    @Test func odometerInMilesAndKilometers() {
        #expect(HUDEngine.odometer(1_234_500, unit: .milesPerHour) == 12_345)
        #expect(HUDEngine.odometer(1_500_000, unit: .milesPerHour) == 15_000)
        #expect(HUDEngine.odometer(4_100, unit: .milesPerHour) == 41)
        #expect(HUDEngine.odometer(1_234_599, unit: .milesPerHour) == 12_345)
        #expect(HUDEngine.odometer(767_100, unit: .kilometersPerHour) == 12_345)
        #expect(HUDEngine.odometer(1_500_000, unit: .kilometersPerHour) == 24_140)
        let engine = parked(odometer: 1_234_500)
        #expect(vehicle(engine, at: 0.2, unit: .milesPerHour)?.odometer == 12_345)
    }

    @Test func aRowTheCarDidNotSendIsNotDrawn() {
        // No climate reply yet, no closures, no odometer: every row is nil.
        let empty = parked(odometer: nil)
        #expect(vehicle(empty, at: 0.2) == VehicleCard(odometer: nil, outsideCelsius: nil, insideCelsius: nil, windows: nil))
        // A climate reply with the outside temperature only.
        let outside = parked(climate: CarClimate(outsideCelsius: -3, insideCelsius: nil))
        #expect(vehicle(outside, at: 0.2)?.outsideCelsius == -3)
        #expect(vehicle(outside, at: 0.2)?.insideCelsius == nil)
    }

    @Test func windowsRow() {
        // A window the car did not send, none open: nothing sure to say.
        #expect(vehicle(parked(closures: windows([false, nil, false, false], at: 0.2)), at: 0.2)?.windows == nil)
        #expect(vehicle(parked(closures: windows([], at: 0.2)), at: 0.2)?.windows == nil)
        // An open one is named even beside an unknown one; the driver sits on the left.
        #expect(vehicle(parked(closures: windows([false, true, nil, false], at: 0.2)), at: 0.2)?.windows == .open([.rearLeft]))
        #expect(vehicle(parked(closures: windows([true, false, false, true], at: 0.2)), at: 0.2)?.windows
            == .open([.frontLeft, .rearRight]))
        #expect(vehicle(parked(closures: windows([false, false, true, false], at: 0.2)), at: 0.2)?.windows == .open([.frontRight]))
    }

    @Test func oldValuesAreNotDrawn() {
        var engine = parked(closures: windows([false, false, false, false], at: 0.2),
                            climate: CarClimate(outsideCelsius: 23, insideCelsius: 26))
        // Keep the car parked with fresh drive replies (no closures, no climate) for 100 s.
        var at = 0.4
        while at <= 100 {
            handle(&engine, reply(at: at), at: at)
            if at > 30.5 && at < 31.5 {
                // The closures are more than 30 s old: no windows row; the temperatures stay (≤ 90 s).
                #expect(vehicle(engine, at: at)?.windows == nil)
                #expect(vehicle(engine, at: at)?.outsideCelsius == 23)
            }
            at += 0.4
        }
        #expect(vehicle(engine, at: 100)?.outsideCelsius == nil)
        #expect(vehicle(engine, at: 100)?.insideCelsius == nil)
        #expect(vehicle(engine, at: 100)?.odometer == 12_345)
        // A new climate reply brings them back.
        handle(&engine, .reading(CarReading(receivedAt: t0 + 100.1, carTimestamp: carEpoch + 100.1,
                                            climate: CarClimate(outsideCelsius: 22, insideCelsius: 25))), at: 100.1)
        #expect(vehicle(engine, at: 100.1)?.outsideCelsius == 22)
    }

    @Test func parkedOnly() {
        var engine = authorized()
        handle(&engine, reply(.drive, closures: windows([false, false, false, false], at: 0),
                              climate: CarClimate(outsideCelsius: 23, insideCelsius: 26), at: 0), at: 0)
        #expect(vehicle(engine, at: 0) == nil)
        // The background forgets the car's values.
        var parked = parked(climate: CarClimate(outsideCelsius: 23, insideCelsius: 26))
        parked.suspend()
        parked.resume(now: t0 + 1)
        handle(&parked, reply(at: 1.2), at: 1.2)
        handle(&parked, reply(odometer: nil, at: 1.4), at: 1.4)
        #expect(vehicle(parked, at: 1.4)?.outsideCelsius == nil)
        #expect(vehicle(parked, at: 1.4)?.odometer == 12_345)
    }
}
