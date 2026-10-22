import Foundation

/// One fix from the phone's location provider, in CoreLocation's terms:
/// negative `speedMetersPerSecond` or `horizontalAccuracyMeters` mean "invalid".
public struct GPSSample: Equatable, Sendable {
    public var speedMetersPerSecond: Double
    public var horizontalAccuracyMeters: Double
    public var timestamp: Date

    public init(speedMetersPerSecond: Double, horizontalAccuracyMeters: Double, timestamp: Date) {
        self.speedMetersPerSecond = speedMetersPerSecond
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.timestamp = timestamp
    }
}

/// Why a sample was not accepted as a speed.
public enum GPSRejection: Equatable, Sendable {
    case invalidSpeed       // NaN, infinite or negative (L7)
    case poorAccuracy       // horizontal accuracy invalid or worse than the threshold
    case notNewer           // same time as, or earlier than, the last accepted sample (L7)
    case fromFuture         // time ahead of now (L7)
    case tooOld             // already older than `maxAge` when it arrived
}

/// Turns GPS samples into a smoothed speed with GPS validity rules (01 §3.1):
/// accuracy ≤ 50 m, fix time within 2 s, speed finite and non-negative.
///
/// A rejected sample is never a speed and never extends the last valid one; the last
/// valid speed expires `maxAge` after its own fix time, judged against the `now` the
/// caller passes in (the injectable clock).
public struct GPSSpeedProcessor: Sendable {
    /// Fix times this far ahead of now are tolerated as clock jitter.
    public static let futureTolerance: TimeInterval = 0.5

    public var smoothing: Double
    public var stationaryMetersPerSecond: Double
    public var accuracyThresholdMeters: Double
    public var maxAge: TimeInterval

    private var latest: SpeedReading?
    private var lastAcceptedTime: Date?

    public init(
        smoothing: Double = 0.3,
        stationaryMetersPerSecond: Double = 0.5,
        accuracyThresholdMeters: Double = 50,
        maxAge: TimeInterval = 2
    ) {
        self.smoothing = smoothing
        self.stationaryMetersPerSecond = stationaryMetersPerSecond
        self.accuracyThresholdMeters = accuracyThresholdMeters
        self.maxAge = maxAge
    }

    /// The speed valid at `now`, or nil.
    public func speed(at now: Date) -> SpeedReading? {
        guard let latest, latest.isValid(at: now, maxAge: maxAge) else { return nil }
        return latest
    }

    /// Accepts `sample` into the smoothed speed, or returns why it was rejected.
    @discardableResult
    public mutating func ingest(_ sample: GPSSample, now: Date) -> GPSRejection? {
        let speed = sample.speedMetersPerSecond
        guard speed.isFinite, speed >= 0 else { return .invalidSpeed }
        let accuracy = sample.horizontalAccuracyMeters
        guard accuracy.isFinite, accuracy >= 0, accuracy <= accuracyThresholdMeters else { return .poorAccuracy }
        if let lastAcceptedTime, sample.timestamp <= lastAcceptedTime { return .notNewer }
        let age = now.timeIntervalSince(sample.timestamp)
        guard age >= -Self.futureTolerance else { return .fromFuture }
        guard age <= maxAge else { return .tooOld }

        // Smooth only across an unbroken run of valid speed: after expiry, start fresh.
        var smoothed = speed
        if let previous = self.speed(at: now) {
            smoothed = previous.metersPerSecond + smoothing * (speed - previous.metersPerSecond)
        }
        if smoothed <= stationaryMetersPerSecond { smoothed = 0 }
        latest = SpeedReading(metersPerSecond: smoothed, source: .gps, timestamp: sample.timestamp)
        lastAcceptedTime = sample.timestamp
        return nil
    }

    /// Drops the current speed (stream ended, location error, permission lost).
    /// The last accepted time is kept so older samples still count as not newer.
    public mutating func invalidate() {
        latest = nil
    }
}
