import HUDCore
import SwiftUI

/// The navigation panel's words and values in the screen's language, for drawing and VoiceOver alike.
/// VoiceOver never reads "—" or the separator.
struct NavigationCopy {
    let route: NavigationRoute
    let unit: SpeedUnit
    let locale: Locale

    var title: String { locale.localized("Car navigation") }
    /// The car's name for the destination; 「導航中」 when it sends an empty one (07 §5).
    var destination: String { route.destination.isEmpty ? locale.localized("Navigating") : route.destination }
    var remainingLabel: String { locale.localized("Remaining") }
    /// 「・」, or a half-width "·" in English (L84-8).
    var separator: String { locale.language.languageCode == .chinese ? "・" : "·" }

    var minutes: String { route.minutes.map(String.init) ?? HUDState.noSpeedNumeral }
    /// 「分」 or "min"; none beside "—".
    var minutesUnit: String? { route.minutes == nil ? nil : locale.localized("min") }
    /// `12`, or `7.5` under 10.
    var distance: String { route.distance.map(Self.distance) ?? HUDState.noSpeedNumeral }
    var distanceUnit: String? { route.distance == nil ? nil : unit.distanceSymbol }
    /// 「抵達時約剩 64%」; nil when the car sends no energy at arrival.
    var arrival: String? {
        route.arrivalPercent.map { percent in
            let shown = "\(percent)%"
            return locale.localized("About \(shown) on arrival")
        }
    }

    static func distance(_ value: Double) -> String {
        value < 10 ? String(format: "%.1f", value) : String(Int(value))
    }

    /// 「目的地 台北車站,剩餘 18 分鐘、12 公里,抵達時約剩 64%」; a part the car did not send is left out.
    var spoken: String {
        var parts = [route.destination.isEmpty ? destination : locale.localized("Destination \(route.destination)")]
        let words = unit == .kilometersPerHour ? locale.localized("kilometers") : locale.localized("miles")
        let remaining = [route.minutes.map { locale.localized("\($0) min") },
                         route.distance.map { "\(Self.distance($0)) \(words)" }].compactMap { $0 }
        if !remaining.isEmpty {
            let joined = remaining.dropFirst().reduce(remaining[0]) { locale.localized("\($0) and \($1)") }
            parts.append(locale.localized("Remaining \(joined)"))
        }
        if let arrival { parts.append(arrival) }
        return parts.dropFirst().reduce(parts[0]) { locale.localized("\($0), \($1)") }
    }
}
