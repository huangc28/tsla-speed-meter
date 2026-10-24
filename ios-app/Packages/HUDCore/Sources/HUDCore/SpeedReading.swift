import Foundation

/// Where a speed value comes from.
public enum SpeedSource: Equatable, Sendable {
    case gps
    case carBluetooth
}

/// A speed value the HUD may show: from one source, stamped with the source's own
/// time (L7), and valid only while that time is within `maxAge` of now.
public struct SpeedReading: Equatable, Sendable {
    public var metersPerSecond: Double
    public var source: SpeedSource
    public var timestamp: Date

    public init(metersPerSecond: Double, source: SpeedSource, timestamp: Date) {
        self.metersPerSecond = metersPerSecond
        self.source = source
        self.timestamp = timestamp
    }

    /// Valid at `now` when no older than `maxAge` and not from the future.
    public func isValid(at now: Date, maxAge: TimeInterval) -> Bool {
        let age = now.timeIntervalSince(timestamp)
        return age >= -GPSSpeedProcessor.futureTolerance && age <= maxAge
    }
}

/// Display unit. Thresholds and the dial stay in km/h; only the numeral and unit change (02 §9.2).
public enum SpeedUnit: String, CaseIterable, Sendable {
    case kilometersPerHour = "kmh"
    case milesPerHour = "mph"

    public var symbol: String {
        switch self {
        case .kilometersPerHour: "km/h"
        case .milesPerHour: "mph"
        }
    }

    public func value(fromMetersPerSecond ms: Double) -> Double {
        switch self {
        case .kilometersPerHour: ms * 3.6
        case .milesPerHour: ms * 3600 / 1609.344
        }
    }
}
