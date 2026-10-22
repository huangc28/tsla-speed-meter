import Foundation

/// Cell and line formatting shared by the drive-log files. A missing value
/// is always an empty cell, never 0.
enum LogFormat {
    /// ISO 8601 with milliseconds and the phone's UTC offset.
    static func iso(_ date: Date?) -> String {
        guard let date else { return "" }
        return date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true, timeZone: .current))
    }

    /// Shortest representation that round-trips (a raw protobuf float stays as sent).
    static func raw(_ value: Float?) -> String {
        value.map { "\($0)" } ?? ""
    }

    static func int<T: BinaryInteger>(_ value: T?) -> String {
        value.map { "\($0)" } ?? ""
    }

    static func decimal(_ value: Double?, places: Int) -> String {
        guard let value, value.isFinite else { return "" }
        return String(format: "%.\(places)f", value)
    }

    static func bool(_ value: Bool?) -> String {
        value.map { $0 ? "true" : "false" } ?? ""
    }

    /// RFC 4180: quote a cell that holds a comma, quote or line break.
    static func csvCell(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    static func csvLine(_ cells: [String]) -> String {
        cells.map(csvCell).joined(separator: ",") + "\n"
    }

    static func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    /// All but the last six characters replaced by `*`.
    static func maskedVIN(_ vin: String) -> String {
        guard vin.count > 6 else { return vin }
        return String(repeating: "*", count: vin.count - 6) + vin.suffix(6)
    }

    /// Whole milliseconds of a duration.
    static func ms(_ duration: Duration) -> Int {
        let parts = duration.components
        return Int(parts.seconds) * 1000 + Int(parts.attoseconds / 1_000_000_000_000_000)
    }
}
