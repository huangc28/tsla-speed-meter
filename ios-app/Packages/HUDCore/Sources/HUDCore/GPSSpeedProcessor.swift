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
    case beforeResume       // taken before the app came back to the foreground (01 §3.2)
}

/// Turns GPS samples into a speed with GPS validity rules (01 §3.1): accuracy ≤ 50 m,
/// fix time within 2 s, speed finite and non-negative. CoreLocation's speed is already
/// filtered, so it is shown as is: no smoothing, no lag (L32).
///
/// A rejected sample is never a speed and never extends the last valid one; the last
/// valid speed expires `maxAge` after its own fix time, judged against the `now` the
/// caller passes in (the injectable clock).
public struct GPSSpeedProcessor: Sendable {
    /// Fix times this far ahead of now are tolerated as clock jitter.
    public static let futureTolerance: TimeInterval = 0.5

    public var accuracyThresholdMeters: Double
    public var maxAge: TimeInterval

    private var latest: SpeedReading?
    private var lastAcceptedTime: Date?
    private var earliestAcceptedTime: Date?

    public init(accuracyThresholdMeters: Double = 50, maxAge: TimeInterval = 2) {
        self.accuracyThresholdMeters = accuracyThresholdMeters
        self.maxAge = maxAge
    }

    /// The speed valid at `now`, or nil.
    public func speed(at now: Date) -> SpeedReading? {
        guard let latest, latest.isValid(at: now, maxAge: maxAge) else { return nil }
        return latest
    }

    /// Accepts `sample` as the current speed, or returns why it was rejected.
    @discardableResult
    public mutating func ingest(_ sample: GPSSample, now: Date) -> GPSRejection? {
        let speed = sample.speedMetersPerSecond
        guard speed.isFinite, speed >= 0 else { return .invalidSpeed }
        let accuracy = sample.horizontalAccuracyMeters
        guard accuracy.isFinite, accuracy >= 0, accuracy <= accuracyThresholdMeters else { return .poorAccuracy }
        if let lastAcceptedTime, sample.timestamp <= lastAcceptedTime { return .notNewer }
        if let earliestAcceptedTime, sample.timestamp < earliestAcceptedTime { return .beforeResume }
        let age = now.timeIntervalSince(sample.timestamp)
        guard age >= -Self.futureTolerance else { return .fromFuture }
        guard age <= maxAge else { return .tooOld }

        // A fix stamped slightly ahead counts from its arrival, so it never outlives `maxAge`.
        latest = SpeedReading(metersPerSecond: speed, source: .gps, timestamp: min(sample.timestamp, now))
        lastAcceptedTime = sample.timestamp
        return nil
    }

    /// Drops the current speed (stream ended, location error, permission lost, app suspended).
    /// The last accepted time is kept so older samples still count as not newer.
    public mutating func invalidate() {
        latest = nil
    }

    /// Drops the current speed and rejects every later sample stamped before `date`.
    public mutating func invalidate(rejectingFixesBefore date: Date) {
        latest = nil
        earliestAcceptedTime = date
    }
}
