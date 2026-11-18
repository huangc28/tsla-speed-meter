import HUDCore
import SwiftUI

/// The 胎壓 card's words in the screen's language (#50, #101), for drawing, measuring and VoiceOver alike.
struct TireCopy {
    let title: String
    let notSupported: String
    /// Front left, front right, rear left, rear right.
    let positions: [String]
    let wheels: [TireWheel]
    /// 「左前,42 psi」, with the age for an old or unknown-time reading; 「右後,尚無讀值」, never "—".
    let spoken: [String]
    /// The shared time line under the car (L82); nil when there is none.
    let summary: String?

    init(panel: TirePanel, locale: Locale) {
        title = locale.localized("Tire pressure")
        notSupported = locale.localized("This car doesn't provide tire pressure")
        positions = [locale.localized("Front left"), locale.localized("Front right"),
                     locale.localized("Rear left"), locale.localized("Rear right")]
        guard case .wheels(let all) = panel else {
            wheels = []
            spoken = []
            summary = nil
            return
        }
        wheels = all.all
        spoken = zip(positions, wheels).map { position, wheel in
            guard let psi = wheel.psi else { return locale.localized("\(position), no reading yet") }
            switch wheel.freshness {
            case .old: return locale.localized("\(position), \(psi) psi, \(AgeText.text(minutes: wheel.ageMinutes ?? 0, locale: locale))")
            case .unknownTime: return locale.localized("\(position), \(psi) psi, \(locale.localized("time unknown"))")
            case .fresh, .missing: return locale.localized("\(position), \(psi) psi")
            }
        }
        summary = switch all.summary {
        case .noReadings: locale.localized("No readings yet")
        case .timeUnknown: locale.localized("Time unknown")
        case .someTimeUnknown: locale.localized("Some readings: time unknown")
        case .age(let minutes, let partial):
            partial ? locale.localized("Some readings \(AgeText.text(minutes: minutes, locale: locale))")
                : AgeText.text(minutes: minutes, locale: locale)
        }
    }
}

/// 「3 分鐘前」, 「2 小時前」, 「1 天前」: the tire time line's and the stale battery's age.
enum AgeText {
    static func text(minutes: Int, locale: Locale) -> String {
        if minutes < 60 { return locale.localized("\(minutes) min ago") }
        if minutes < 1440 { return locale.localized("\(minutes / 60) hr ago") }
        let days = minutes / 1440
        return days == 1 ? locale.localized("1 day ago") : locale.localized("\(days) days ago")
    }
}

extension Locale {
    /// `value` from the app's strings in this locale's language: the screen's words follow the
    /// environment's locale, like `Text`.
    func localized(_ value: String.LocalizationValue) -> String {
        var resource = LocalizedStringResource(value)
        resource.locale = self
        return String(localized: resource)
    }

    /// The string for `key`, whose English is `defaultValue`: for words whose English is another
    /// string's too (「本趟」 and 「行程」 are both "Trip").
    func localized(_ key: StaticString, defaultValue: String.LocalizationValue) -> String {
        String(localized: LocalizedStringResource(key, defaultValue: defaultValue, locale: self))
    }
}
