import Foundation
import HUDCore
import TeslaBLE

extension CarReading {
    /// The categories that came back in `poll`, as HUDCore sees them; nil when none came back.
    init?(_ poll: VehicleDataPoll, receivedAt: Date) {
        guard poll.reading != nil else { return nil }
        let drive = poll.response(for: .drive)?.reading
        let charge = poll.response(for: .charge)?.reading
        let tires = poll.response(for: .tirePressure)?.reading
        self.init(
            receivedAt: receivedAt,
            carTimestamp: drive?.driveStateTimestamp ?? charge?.chargeStateTimestamp ?? tires?.tirePressureStateTimestamp,
            speedMetersPerSecond: drive?.speedMetersPerSecond,
            gear: drive.flatMap { CarGear($0.gear) },
            batteryPercent: charge?.batteryLevel.map(Int.init),
            rangeKilometers: charge?.batteryRangeKilometers,
            tires: tires.map { tires in
                CarTires(frontLeft: CarTire(tires.tirePressureFrontLeft), frontRight: CarTire(tires.tirePressureFrontRight),
                         rearLeft: CarTire(tires.tirePressureRearLeft), rearRight: CarTire(tires.tirePressureRearRight))
            }
        )
    }
}

extension CarGear {
    init?(_ gear: Gear) {
        switch gear {
        case .park: self = .park
        case .reverse: self = .reverse
        case .neutral: self = .neutral
        case .drive: self = .drive
        case .unknown: return nil
        }
    }
}

extension CarTire {
    init?(_ tire: TirePressure?) {
        guard let tire else { return nil }
        self.init(psi: tire.psi, lastSeen: tire.lastSeen)
    }
}

extension CarLinkStatus {
    /// Nil while the feed is idle: that alone does not say whether a car is paired.
    init?(_ status: CarFeed.LinkStatus) {
        switch status {
        case .idle: return nil
        case .connecting: self = .connecting
        case .connected: self = .connected
        case .lost: self = .lost
        }
    }
}

extension CarFeed {
    /// Car events for the HUD engine while the stream is alive. Listening is what makes the
    /// feed keep the link up and poll (it connects only to a paired car, or to the car the
    /// test page connected). `.notPaired` comes first when no car is paired, and whenever
    /// the car says it does not know the key.
    nonisolated func carEvents(now: @escaping @Sendable () -> Date = Date.init) -> AsyncStream<CarEvent> {
        AsyncStream { continuation in
            let polls = polls()
            let statuses = linkStatusUpdates()
            let tasks = [
                Task {
                    if await pairedVIN == nil { continuation.yield(.link(.notPaired)) }
                    for await status in statuses {
                        if let status = CarLinkStatus(status) { continuation.yield(.link(status)) }
                    }
                },
                Task {
                    for await poll in polls {
                        if poll.error(for: .drive) == .keyNotPaired { continuation.yield(.link(.notPaired)) }
                        if let reading = CarReading(poll, receivedAt: now()) { continuation.yield(.reading(reading)) }
                    }
                },
            ]
            continuation.onTermination = { _ in tasks.forEach { $0.cancel() } }
        }
    }
}
