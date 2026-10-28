import HUDCore
import SwiftUI

/// The drive screen's right panel while it shows the car's navigation (#77, L80, the master's
/// `navWing`): the destination, 剩餘 over `18 分 ・ 12 km`, and the sentence 「抵達時約剩 64%」 (L78:
/// never a large number), with no title. Centered in the panel; one VoiceOver element 「車上導航」 read
/// in words. Stale, a dashed destination pin in place with no words; ended, nothing (L84-4).
struct NavigationPanelView: View {
    let panel: NavigationPanel
    let unit: SpeedUnit
    let size: CGSize
    @Environment(\.locale) private var locale

    var body: some View {
        switch panel {
        case .route(let route):
            let copy = NavigationCopy(route: route, unit: unit, locale: locale)
            content(copy)
                .frame(width: size.width, height: size.height, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: copy.title))
                .accessibilityValue(Text(verbatim: copy.spoken))
        case .stale:
            StalePin()
                .accessibilityElement()
                .accessibilityLabel(Text("Navigation data stale"))
                .accessibilityAddTraits(.isImage)
                .frame(width: size.width, height: size.height, alignment: .leading)
        case .ended:
            EmptyView()
        }
    }

    /// As the master's `.wing`: the destination 20/700 on a 26 line, 20 below it the label 13/600 and the
    /// value 22/600 (as `TripPanelView`'s), and 18 below that the sentence 15/500 on a 20 line.
    private func content(_ copy: NavigationCopy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: copy.destination)
                .font(.custom(HUDFont.interBold, fixedSize: 20))
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 26, maxHeight: 26, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: copy.remainingLabel)
                    .font(.custom(HUDFont.interSemiBold, fixedSize: 13))
                    .tracking(1)
                    .foregroundStyle(Palette.unit)
                    .frame(height: 16)
                // As in the master, the units keep the 26 line height at their own size, which grows the
                // line 3.6 below the values.
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    value(copy.minutes, unit: copy.minutesUnit)
                    Text(verbatim: copy.separator)
                        .font(.custom(HUDFont.interMedium, fixedSize: 15))
                        .foregroundStyle(Palette.unit)
                        .padding(.horizontal, 10)
                    value(copy.distance, unit: copy.distanceUnit)
                }
                .frame(height: 29.6, alignment: .top)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.top, 20)
            if let arrival = copy.arrival {
                Text(verbatim: arrival)
                    .font(.custom(HUDFont.interMedium, fixedSize: 15))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)
                    .fixedSize()
                    .frame(height: 20)
                    .padding(.top, 18)
            }
        }
    }

    /// The value 22/600 `text.secondary`, tabular; its unit 12/500 `unit` 5 after it, none beside "—".
    private func value(_ value: String, unit: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(verbatim: value)
                .font(Font(HUDFont.tabular(HUDFont.interSemiBold, size: 22)))
                .foregroundStyle(Palette.textSecondary)
            if let unit {
                Text(verbatim: unit)
                    .font(.custom(HUDFont.interMedium, fixedSize: 12))
                    .foregroundStyle(Palette.unit)
            }
        }
    }
}

/// The master's `navStale`: a destination pin 28 × 28 (drawn in a 22-unit box), its outline dashed
/// 1.5 / 2.2 · 1.5 and its dot a solid line (S13-01), in `text.tertiary`.
struct StalePin: View {
    static let size: CGFloat = 28

    var body: some View {
        let k = Self.size / 22
        ZStack {
            PinOutline()
                .stroke(Palette.textTertiary, style: StrokeStyle(lineWidth: 1.5 * k, lineJoin: .round, dash: [2.2 * k, 1.5 * k]))
            Circle()
                .stroke(Palette.textTertiary, lineWidth: 1.5 * k)
                .frame(width: 4.6 * k, height: 4.6 * k)
                .position(x: 11 * k, y: 9.1 * k)
        }
        .frame(width: Self.size, height: Self.size)
    }
}

/// `M11 20.6 C8.2 17.9 4.4 13.6 4.4 9.1 A6.6 6.6 0 0 1 17.6 9.1 C17.6 13.6 13.8 17.9 11 20.6 Z` in a
/// 22-unit box, scaled to the frame.
private struct PinOutline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 11, y: 20.6))
        path.addCurve(to: CGPoint(x: 4.4, y: 9.1), control1: CGPoint(x: 8.2, y: 17.9), control2: CGPoint(x: 4.4, y: 13.6))
        path.addArc(center: CGPoint(x: 11, y: 9.1), radius: 6.6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        path.addCurve(to: CGPoint(x: 11, y: 20.6), control1: CGPoint(x: 17.6, y: 13.6), control2: CGPoint(x: 13.8, y: 17.9))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width / 22, y: rect.height / 22))
    }
}

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
