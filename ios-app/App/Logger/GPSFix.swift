import CoreLocation
import Foundation

/// The parts of a phone GPS fix the drive log keeps. Latitude, longitude,
/// altitude and course are deliberately not stored.
struct GPSFix: Sendable, Equatable {
    /// When the fix was taken.
    let timestamp: Date
    /// m/s; nil when CoreLocation marks it invalid (negative).
    let speed: Double?
    /// m/s; nil when invalid.
    let speedAccuracy: Double?
    /// Meters; nil when invalid.
    let horizontalAccuracy: Double?

    init(timestamp: Date, speed: Double?, speedAccuracy: Double?, horizontalAccuracy: Double?) {
        self.timestamp = timestamp
        self.speed = speed
        self.speedAccuracy = speedAccuracy
        self.horizontalAccuracy = horizontalAccuracy
    }

    init(_ location: CLLocation) {
        timestamp = location.timestamp
        speed = location.speed >= 0 ? location.speed : nil
        speedAccuracy = location.speedAccuracy >= 0 ? location.speedAccuracy : nil
        horizontalAccuracy = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
    }

    /// Milliseconds between the fix and `now`.
    func ageMs(at now: Date) -> Int {
        Int((now.timeIntervalSince(timestamp) * 1000).rounded())
    }
}

/// `gps.csv`: one row per fix.
enum GPSCSV {
    static let header = LogFormat.csvLine([
        "phone_time", "monotonic_ms", "fix_time", "fix_age_ms",
        "speed_mps", "speed_kmh", "speed_accuracy_mps", "horizontal_accuracy_m",
    ])

    static func row(_ fix: GPSFix, receivedAt: Date, monotonicMs: Int) -> String {
        LogFormat.csvLine([
            LogFormat.iso(receivedAt),
            "\(monotonicMs)",
            LogFormat.iso(fix.timestamp),
            "\(fix.ageMs(at: receivedAt))",
            LogFormat.decimal(fix.speed, places: 3),
            LogFormat.decimal(fix.speed.map { $0 * 3.6 }, places: 2),
            LogFormat.decimal(fix.speedAccuracy, places: 3),
            LogFormat.decimal(fix.horizontalAccuracy, places: 1),
        ])
    }
}
