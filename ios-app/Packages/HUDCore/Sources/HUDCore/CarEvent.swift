import Foundation

/// Everything the car feed can tell the HUD. The app maps Car Bluetooth replies to these,
/// so HUDCore never depends on the Bluetooth package.
public enum CarEvent: Equatable, Sendable {
    case reading(CarReading)
    case link(CarLinkStatus)
}

/// The state of the Car Bluetooth link, as the car feed reports it.
public enum CarLinkStatus: Equatable, Sendable {
    /// No paired car, or the car does not know this phone's key.
    case notPaired
    case connecting
    case connected
    /// The link was up and dropped; the feed is reconnecting.
    case lost
    /// No link and the feed is not trying: disconnected on request (the test page's 斷線, a
    /// cancelled or failed pairing), suspended, or nothing to connect to.
    case idle
}

/// Gear from the car's shift state; an unknown gear is nil.
public enum CarGear: Equatable, Sendable {
    case park, reverse, neutral, drive
}

/// One tire's last reported pressure.
public struct CarTire: Equatable, Sendable {
    public var psi: Double
    /// The car's time of the sensor's last report, if given.
    public var lastSeen: Date?

    public init(psi: Double, lastSeen: Date?) {
        self.psi = psi
        self.lastSeen = lastSeen
    }
}

/// The four tires; a wheel the car did not report is nil.
public struct CarTires: Equatable, Sendable {
    public var frontLeft: CarTire?
    public var frontRight: CarTire?
    public var rearLeft: CarTire?
    public var rearRight: CarTire?

    public init(frontLeft: CarTire?, frontRight: CarTire?, rearLeft: CarTire?, rearRight: CarTire?) {
        self.frontLeft = frontLeft
        self.frontRight = frontRight
        self.rearLeft = rearLeft
        self.rearRight = rearRight
    }
}

/// One reply from the car: when it reached the phone, the car's own time, and only the
/// categories that came back. Nothing missing defaults to 0.
public struct CarReading: Equatable, Sendable {
    /// Phone time the reply arrived; car data freshness is judged from it.
    public var receivedAt: Date
    /// The car's time of the reading (its drive state's time when drive state came back).
    /// Readings are put in order by it; a speed without it is never shown (L7).
    public var carTimestamp: Date?
    /// As reported, sign kept (the car reports reverse as positive, but nothing relies on it).
    public var speedMetersPerSecond: Double?
    public var gear: CarGear?
    public var batteryPercent: Int?
    public var rangeKilometers: Double?
    public var tires: CarTires?

    public init(
        receivedAt: Date,
        carTimestamp: Date?,
        speedMetersPerSecond: Double? = nil,
        gear: CarGear? = nil,
        batteryPercent: Int? = nil,
        rangeKilometers: Double? = nil,
        tires: CarTires? = nil
    ) {
        self.receivedAt = receivedAt
        self.carTimestamp = carTimestamp
        self.speedMetersPerSecond = speedMetersPerSecond
        self.gear = gear
        self.batteryPercent = batteryPercent
        self.rangeKilometers = rangeKilometers
        self.tires = tires
    }
}
