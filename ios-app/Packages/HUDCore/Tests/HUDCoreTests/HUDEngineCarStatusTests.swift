import Foundation
import Testing
@testable import HUDCore

private let carEpoch = Date(timeIntervalSinceReferenceDate: 700_000_000)

/// Closures with every door closed unless given.
private func closures(frunk: Bool? = false, trunk: Bool? = false, doors: [Bool?] = [false, false, false, false],
                      carTime: TimeInterval? = nil) -> CarClosures {
    CarClosures(frontTrunk: frunk, rearTrunk: trunk, doors: doors, carTime: carTime.map { carEpoch + $0 })
}

/// A drive reply (D, 40 km/h) that reached the phone at `t0 + seconds`, stamped `carTime` (default
/// `seconds`), with the closures asked in its slot, if any; `closuresTime` nil means the closures
/// carry the same car time as the reply.
private func reply(_ closures: CarClosures? = nil, kmh: Double? = 40, gear: CarGear? = .drive, at seconds: TimeInterval,
                   carTime: TimeInterval? = nil) -> CarEvent {
    .reading(CarReading(receivedAt: t0 + seconds, carTimestamp: carEpoch + (carTime ?? seconds),
                        speedMetersPerSecond: kmh.map { $0 / 3.6 }, gear: gear, closures: closures))
}

/// #78: the car-status icons inside the ring (L71, DESIGN.md "Car-status icons", 07 §4 closures).
struct HUDEngineCarStatusTests {
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

    private func status(_ engine: HUDEngine, at seconds: TimeInterval) -> CarStatus? {
        engine.state(at: t0 + seconds, unit: .kilometersPerHour).carStatus
    }

    // MARK: Open, closed and unknown, slot by slot

    @Test func eachSlotIsOpenClosedOrUnknownOnItsOwn() {
        var engine = authorized()
        handle(&engine, reply(closures(frunk: true, trunk: false, doors: [false, nil, false, false]), at: 0), at: 0)
        #expect(status(engine, at: 0) == CarStatus(frontTrunk: .open, rearTrunk: .closed, door: .unknown))
        handle(&engine, reply(closures(frunk: nil, trunk: true, doors: [false, false, false, false]), at: 0.2), at: 0.2)
        #expect(status(engine, at: 0.2) == CarStatus(frontTrunk: .unknown, rearTrunk: .open, door: .closed))
        handle(&engine, reply(closures(), at: 0.4), at: 0.4)
        #expect(status(engine, at: 0.4) == CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .closed))
    }

    // Connected, but no closures reply yet: all three are unknown, never closed.
    @Test func unknownBeforeTheFirstClosuresReply() {
        var engine = authorized()
        handle(&engine, .link(.connected), at: 0)
        #expect(status(engine, at: 0) == .unknown)
        handle(&engine, reply(at: 0.2), at: 0.2)
        #expect(status(engine, at: 0.2) == .unknown)
    }

    @Test func anyDoorOpenOpensTheDoorSlot() {
        for open in 0..<4 {
            var doors: [Bool?] = [false, false, false, false]
            doors[open] = true
            var engine = authorized()
            handle(&engine, reply(closures(doors: doors), at: 0), at: 0)
            #expect(status(engine, at: 0)?.door == .open, "door \(open)")
        }
        // One open beats one unknown; with none open, one unknown is unknown.
        var engine = authorized()
        handle(&engine, reply(closures(doors: [nil, nil, true, nil]), at: 0), at: 0)
        #expect(status(engine, at: 0)?.door == .open)
        handle(&engine, reply(closures(doors: [false, false, false, nil]), at: 0.2), at: 0.2)
        #expect(status(engine, at: 0.2)?.door == .unknown)
        handle(&engine, reply(closures(doors: []), at: 0.4), at: 0.4)
        #expect(status(engine, at: 0.4)?.door == .unknown)
    }

    // MARK: The 30 s age

    @Test func aReplyMoreThan30SecondsOldIsUnknown() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        handle(&engine, .link(.connected), at: 0)
        #expect(status(engine, at: 30)?.rearTrunk == .open)
        #expect(status(engine, at: 30.1) == .unknown)
        // A fresh reply brings it back.
        handle(&engine, reply(closures(trunk: true), at: 31), at: 31)
        #expect(status(engine, at: 31)?.rearTrunk == .open)
    }

    // Aged by the car's clock, like the tires: the car's time of the reply, plus the phone time
    // since it arrived, minus the closures' own time. A car that re-sends an old closures state
    // ages it, even though the reply itself is new.
    @Test func agedByTheCarsClock() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true, carTime: 0), at: 0), at: 0)
        #expect(status(engine, at: 0)?.rearTrunk == .open)
        // Same closures time, 25 s later by the car: 5 more phone seconds make it 30.
        handle(&engine, reply(closures(trunk: true, carTime: 0), at: 25), at: 25)
        #expect(status(engine, at: 30)?.rearTrunk == .open)
        #expect(status(engine, at: 30.5) == .unknown)
        // No car time on the closures: by the phone time since the reply arrived.
        handle(&engine, reply(closures(trunk: true, carTime: nil), at: 40), at: 40)
        #expect(status(engine, at: 70)?.rearTrunk == .open)
        #expect(status(engine, at: 70.5) == .unknown)
    }

    // MARK: Recovering slot by slot

    @Test func aSlotRecoversOnItsOwnFreshReading() {
        var engine = authorized()
        handle(&engine, reply(closures(frunk: nil, trunk: true, doors: [nil, nil, nil, nil]), at: 0), at: 0)
        #expect(status(engine, at: 0) == CarStatus(frontTrunk: .unknown, rearTrunk: .open, door: .unknown))
        // Only the doors come back: the door slot recovers, the frunk stays unknown.
        handle(&engine, reply(closures(frunk: nil, trunk: true, doors: [false, false, false, false]), at: 10), at: 10)
        #expect(status(engine, at: 10) == CarStatus(frontTrunk: .unknown, rearTrunk: .open, door: .closed))
        handle(&engine, reply(closures(frunk: false, trunk: true, doors: [false, false, false, false]), at: 20), at: 20)
        #expect(status(engine, at: 20) == CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .closed))
    }

    // A slot the car stops sending goes unknown at once, without waiting 30 s.
    @Test func aSlotTheReplyLeavesOutIsUnknownAtOnce() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        handle(&engine, reply(closures(trunk: nil), at: 10), at: 10)
        #expect(status(engine, at: 10)?.rearTrunk == .unknown)
    }

    // Drive replies without closures leave the last closures in place.
    @Test func driveRepliesKeepTheLastClosures() {
        var engine = authorized()
        handle(&engine, reply(closures(frunk: true), at: 0), at: 0)
        for i in 1...20 { handle(&engine, reply(at: Double(i) * 0.2), at: Double(i) * 0.2) }
        #expect(status(engine, at: 4)?.frontTrunk == .open)
    }

    // MARK: Hidden (L71)

    @Test func hiddenOnGPS() {
        var engine = authorized()
        gps(&engine, kmh: 72, at: 0)
        #expect(status(engine, at: 0) == nil)

        // GPS fallback: the car's speed lapsed and GPS supplies it, so the whole group goes.
        handle(&engine, reply(closures(trunk: true), at: 1), at: 1)
        #expect(status(engine, at: 1)?.rearTrunk == .open)
        gps(&engine, kmh: 72, at: 3.5)
        let fallback = engine.state(at: t0 + 3.5, unit: .kilometersPerHour)
        #expect(fallback.source == .gpsFallback)
        #expect(fallback.carStatus == nil)
        // The car's speed returns after 2 readings: the icons come back with the last closures.
        handle(&engine, reply(at: 4), at: 4)
        handle(&engine, reply(at: 4.2), at: 4.2)
        #expect(status(engine, at: 4.2)?.rearTrunk == .open)
    }

    @Test func hiddenWithNoCarLink() {
        var engine = authorized()
        #expect(status(engine, at: 0) == nil)
        handle(&engine, .link(.notPaired), at: 0)
        #expect(status(engine, at: 0) == nil)
    }

    @Test func hiddenAtOnceWhenTheLinkGoesIdleAndALateReplyStoresNothing() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        handle(&engine, .link(.idle), at: 0.2)
        #expect(status(engine, at: 0.2) == nil)
        // A reply that was in flight: not shown, and not stored.
        handle(&engine, reply(closures(frunk: true, trunk: false), at: 0.4), at: 0.4)
        #expect(status(engine, at: 0.4) == nil)
        handle(&engine, .link(.connecting), at: 1)
        #expect(status(engine, at: 1) == CarStatus(frontTrunk: .closed, rearTrunk: .open, door: .closed))
    }

    // Like battery / range: hidden once the link has been lost for more than 10 s.
    @Test func hiddenAfterTheLinkIsLostFor10Seconds() {
        var engine = authorized()
        handle(&engine, .link(.connected), at: 0)
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        handle(&engine, .link(.lost), at: 1)
        #expect(status(engine, at: 11)?.rearTrunk == .open)
        #expect(status(engine, at: 11.1) == nil)
        handle(&engine, .link(.connected), at: 12)
        #expect(status(engine, at: 12)?.rearTrunk == .open)
    }

    @Test func forgottenInTheBackground() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        engine.suspend()
        engine.resume(now: t0 + 5)
        #expect(status(engine, at: 5) == nil)
        handle(&engine, .link(.connected), at: 6)
        #expect(status(engine, at: 6) == .unknown)
    }

    // Shown on the parked screen too, also while GPS supplies the speed (the fresh car P chose it).
    @Test func shownWhenParked() {
        var engine = authorized()
        handle(&engine, reply(kmh: nil, gear: .park, at: 0), at: 0)
        gps(&engine, kmh: 0, at: 0.2)
        handle(&engine, reply(closures(doors: [true, false, false, false]), kmh: nil, gear: .park, at: 0.2), at: 0.2)
        let parked = engine.state(at: t0 + 0.2, unit: .kilometersPerHour)
        #expect(parked.layout == .parked)
        #expect(parked.source == .gpsFallback || parked.source == .valid(.gps))
        #expect(parked.carStatus == CarStatus(frontTrunk: .closed, rearTrunk: .closed, door: .open))
    }

    // Linked but no speed at all: the icons stay with 「—」 and the reason.
    @Test func shownWithNoSpeed() {
        var engine = authorized()
        handle(&engine, reply(closures(trunk: true), at: 0), at: 0)
        let none = engine.state(at: t0 + 5, unit: .kilometersPerHour)
        #expect(!none.hasSpeed)
        #expect(none.carStatus?.rearTrunk == .open)
    }
}
