import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// A drive reply that reached the phone at `t0 + seconds`, with the tires and closures asked in its slot, if any.
private func reply(_ gear: CarGear? = .drive, kmh: Double? = 40, tires: CarTires? = nil, closures: CarClosures? = nil,
                   at seconds: TimeInterval) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + seconds,
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }, gear: gear, tires: tires, closures: closures))
}

private let tire = CarTire(psi: 42, lastSeen: nil)

/// Four wheels with a pressure each, the given ones warned about by the car.
private func tires(frontLeftLow: Bool = false, frontRightLow: Bool = false, rearLeftLow: Bool = false,
                   rearRightLow: Bool = false) -> CarTires {
    CarTires(frontLeft: tire, frontRight: tire, rearLeft: tire, rearRight: tire, frontLeftLow: frontLeftLow,
             frontRightLow: frontRightLow, rearLeftLow: rearLeftLow, rearRightLow: rearRightLow)
}

/// #97: low tire from the car's own TPMS warning (CONTEXT.md "Low tire"), the gauge's tire slot (L108).
struct HUDEngineLowTireTests {
    private func authorized() -> HUDEngine {
        var engine = HUDEngine()
        engine.handle(.authorization(.authorized), now: t0)
        return engine
    }

    private func handle(_ engine: inout HUDEngine, _ event: CarEvent, at seconds: TimeInterval) {
        engine.handle(event, now: t0 + seconds)
    }

    private func state(_ engine: HUDEngine, at seconds: TimeInterval) -> HUDState {
        engine.state(at: t0 + seconds, unit: .kilometersPerHour)
    }

    private func tireStatus(_ engine: HUDEngine, at seconds: TimeInterval) -> TireStatus? {
        state(engine, at: seconds).carStatus?.tire
    }

    /// Two fresh P readings, the second at `t0 + 0.2` with `tires`.
    private func parked(tires: CarTires?) -> HUDEngine {
        var engine = authorized()
        handle(&engine, reply(.park, kmh: 0, at: 0), at: 0)
        handle(&engine, reply(.park, kmh: 0, tires: tires, at: 0.2), at: 0.2)
        return engine
    }

    private func wheels(_ engine: HUDEngine, at seconds: TimeInterval) -> TireWheels? {
        guard case .wheels(let wheels) = state(engine, at: seconds).tires else { return nil }
        return wheels
    }

    // MARK: Low, normal, no reading

    @Test func aWarnedWheelIsLowAndTheSlotIsLow() throws {
        let engine = parked(tires: tires(frontLeftLow: true))
        let wheels = try #require(self.wheels(engine, at: 0.2))
        #expect(wheels.frontLeft.isLow)
        #expect(!wheels.frontRight.isLow && !wheels.rearLeft.isLow && !wheels.rearRight.isLow)
        #expect(wheels.frontLeft.psi == 42)
        #expect(tireStatus(engine, at: 0.2) == .low)
    }

    @Test func anyWheelMakesTheSlotLowOnTheDriveScreen() {
        var engine = authorized()
        handle(&engine, reply(tires: tires(rearRightLow: true), at: 0), at: 0)
        #expect(state(engine, at: 0).layout != .parked)
        #expect(tireStatus(engine, at: 0) == .low)
    }

    @Test func noWarningIsNormal() throws {
        let engine = parked(tires: tires())
        let wheels = try #require(self.wheels(engine, at: 0.2))
        #expect(!wheels.all.contains { $0.isLow })
        #expect(tireStatus(engine, at: 0.2) == .normal)
    }

    // A tire reply with no wheels and no flags is still a reading with no warning.
    @Test func anEmptyTireReplyIsNormal() {
        var engine = authorized()
        handle(&engine, reply(tires: CarTires(frontLeft: nil, frontRight: nil, rearLeft: nil, rearRight: nil), at: 0), at: 0)
        #expect(tireStatus(engine, at: 0) == .normal)
    }

    // The warning is the car's, whether or not that wheel's pressure came back.
    @Test func aWarnedWheelWithoutAPressureIsStillLow() throws {
        let engine = parked(tires: CarTires(frontLeft: tire, frontRight: nil, rearLeft: tire, rearRight: tire, frontRightLow: true))
        let wheels = try #require(self.wheels(engine, at: 0.2))
        #expect(wheels.frontRight.psi == nil)
        #expect(wheels.frontRight.freshness == .missing)
        #expect(wheels.frontRight.isLow)
        #expect(tireStatus(engine, at: 0.2) == .low)
    }

    @Test func noTireReplyYetIsNoReading() {
        var engine = authorized()
        handle(&engine, .link(.connected), at: 0)
        #expect(tireStatus(engine, at: 0) == .noReading)
        handle(&engine, reply(at: 0.2), at: 0.2)
        #expect(tireStatus(engine, at: 0.2) == .noReading)
        #expect(CarStatus.unknown.tire == .noReading)
    }

    // MARK: Freshness: the tire reply's age, like the closures (CarStatus.maxAge)

    @Test func aReplyOlderThanMaxAgeIsNoReadingNeverLow() {
        var engine = authorized()
        handle(&engine, reply(tires: tires(frontLeftLow: true), at: 0), at: 0)
        // Drive replies without tires keep coming.
        for second in stride(from: 1.0, through: 30, by: 1) {
            handle(&engine, reply(at: second), at: second)
        }
        #expect(tireStatus(engine, at: 30) == .low)
        handle(&engine, reply(at: 30.1), at: 30.1)
        #expect(tireStatus(engine, at: 30.1) == .noReading)
        handle(&engine, reply(at: 31), at: 31)
        #expect(tireStatus(engine, at: 31) == .noReading)

        // A new tire reply brings it back.
        handle(&engine, reply(tires: tires(), at: 31.2), at: 31.2)
        #expect(tireStatus(engine, at: 31.2) == .normal)
    }

    // Parked, the tire panel keeps the last readings, but a stale warning is not drawn as low.
    @Test func aStaleWheelKeepsItsReadingButIsNotLow() throws {
        var engine = parked(tires: tires(frontLeftLow: true))
        for second in stride(from: 1.0, through: 31, by: 1) {
            handle(&engine, reply(.park, kmh: 0, at: second), at: second)
        }
        let wheels = try #require(self.wheels(engine, at: 31))
        #expect(wheels.frontLeft.psi == 42)
        #expect(!wheels.frontLeft.isLow)
        #expect(tireStatus(engine, at: 31) == .noReading)
    }

    // MARK: Apart from the trunks and doors

    @Test func lowWithNoClosuresReplyOrAStaleOne() {
        var engine = authorized()
        handle(&engine, reply(tires: tires(frontLeftLow: true), at: 0), at: 0)
        #expect(state(engine, at: 0).carStatus == CarStatus(frontTrunk: .unknown, rearTrunk: .unknown, door: .unknown, tire: .low))

        var stale = authorized()
        let closed = CarClosures(frontTrunk: false, rearTrunk: true, doors: [false, false, false, false], carTime: nil)
        handle(&stale, reply(closures: closed, at: 0), at: 0)
        handle(&stale, reply(tires: tires(rearLeftLow: true), at: 25), at: 25)
        #expect(state(stale, at: 25).carStatus == CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .closed, tire: .low))
        #expect(state(stale, at: 40).carStatus == CarStatus(frontTrunk: .unknown, rearTrunk: .unknown, door: .unknown, tire: .low))
    }

    // Hidden with the rest of the car data: not connected, or GPS supplying the speed.
    @Test func hiddenWithTheOtherCarStatus() {
        var engine = authorized()
        handle(&engine, reply(tires: tires(frontLeftLow: true), at: 0), at: 0)
        handle(&engine, .link(.idle), at: 1)
        #expect(state(engine, at: 1).carStatus == nil)

        var gps = authorized()
        handle(&gps, reply(kmh: nil, tires: tires(frontLeftLow: true), at: 0), at: 0)
        gps.handle(.sample(fix(40 / 3.6, at: 0.2)), now: t0 + 0.2)
        #expect(state(gps, at: 0.2).carStatus == nil)
    }

    @Test func forgottenInTheBackground() {
        var engine = authorized()
        handle(&engine, reply(tires: tires(frontLeftLow: true), at: 0), at: 0)
        engine.suspend()
        engine.resume(now: t0 + 5)
        handle(&engine, .link(.connected), at: 6)
        #expect(tireStatus(engine, at: 6) == .noReading)
    }
}
