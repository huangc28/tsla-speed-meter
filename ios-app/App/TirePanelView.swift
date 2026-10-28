import HUDCore
import SwiftUI
import UIKit

/// The parked screen's tire panel (L42, DESIGN.md "Parked screen" → Tire pressure), ported from the
/// master's `tirePanel`: a top-down car, nose up, each wheel's reading in its own corner and one
/// shared time line under the car. When a reading is wider than its column, or the time line or
/// the title needs more lines than the diagram has, it becomes a list that names each position.
/// Old and unknown-time readings dim wheel by wheel; nothing dims a whole area (L21, R7-15).
struct TirePanelView: View {
    let panel: TirePanel
    let size: CGSize
    /// The master's `--text-scale`: 1 until the large-text setting exists.
    var textScale: CGFloat = 1

    @Environment(\.locale) private var locale

    var body: some View {
        let geometry = TireGeometry(size: size)
        let copy = TireCopy(panel: panel, locale: locale)
        Group {
            if panel == .notSupported {
                notSupported(copy)
            } else if Self.needsList(copy, geometry: geometry, textScale: textScale) {
                list(copy)
            } else {
                diagram(copy, geometry: geometry)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: copy.title))
    }

    // MARK: Diagram

    private func diagram(_ copy: TireCopy, geometry g: TireGeometry) -> some View {
        ZStack(alignment: .topLeading) {
            Palette.tireBacking
            heading(copy)
            CeramicCar()
                .frame(width: g.carSize.width, height: g.carSize.height)
                .offset(x: (size.width - g.carSize.width) / 2, y: g.carTop)
            if let summary = copy.summary {
                Text(verbatim: summary)
                    .font(.system(size: summaryFontSize))
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 2)
                    .background(Palette.tireBacking)
                    .frame(width: size.width)
                    .offset(y: g.summaryTop)
                    .accessibilityHidden(true)
            }
            ForEach(0..<4, id: \.self) { i in
                let left = i % 2 == 0, front = i < 2
                reading(copy.wheels[i])
                    .frame(width: g.column, alignment: left ? .trailing : .leading)
                    .offset(x: left ? g.labelRight - g.column : g.labelLeft,
                            y: front ? g.frontBottomY - lineHeight : g.rearTop)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: copy.spoken[i]))
            }
        }
    }

    // MARK: List

    private func list(_ copy: TireCopy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                heading(copy).frame(maxWidth: .infinity, alignment: .leading)
                CeramicCar().frame(width: 24, height: 48)
            }
            .padding(.bottom, 12)
            if let summary = copy.summary {
                Text(verbatim: summary)
                    .font(.system(size: summaryFontSize))
                    .foregroundStyle(Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
                    .accessibilityHidden(true)
            }
            // Only the four rows scroll.
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<4, id: \.self) { i in
                        HStack(spacing: 12) {
                            TireLocator(wheel: i).frame(width: 24, height: 40)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(verbatim: copy.positions[i])
                                    .font(.system(size: 12 * textScale))
                                    .foregroundStyle(Palette.textSecondary)
                                    .frame(minHeight: 16 * textScale)
                                reading(copy.wheels[i])
                            }
                        }
                        .frame(minHeight: 48)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: copy.spoken[i]))
                    }
                }
                .padding(.trailing, 7)
                .padding(.bottom, 12)
            }
            .accessibilityLabel(Text(verbatim: copy.region))
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(Palette.tireBacking)
    }

    // MARK: Not supported

    /// Only the title and one line; no car and no `—` (R6-08).
    private func notSupported(_ copy: TireCopy) -> some View {
        ZStack(alignment: .topLeading) {
            heading(copy)
            Text(verbatim: copy.notSupported)
                .font(.system(size: 14 * textScale))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: size.width, alignment: .leading)
                .offset(y: 38)
        }
    }

    // MARK: Parts

    private var lineHeight: CGFloat { 24 * textScale }
    private var summaryFontSize: CGFloat { 12 * min(textScale, 1.5) }

    private func heading(_ copy: TireCopy) -> some View {
        Text(verbatim: copy.title)
            .font(.system(size: 14 * textScale, weight: .semibold))
            .foregroundStyle(Palette.textSecondary)
            .frame(height: 18 * textScale)
            .accessibilityAddTraits(.isHeader)
    }

    /// `42 psi` or `—`, on its own solid backing (L40).
    private func reading(_ wheel: TireWheel) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.unitGap) {
            Text(verbatim: wheel.psi.map(String.init) ?? "—")
                .font(Font(Self.readingFont(textScale)))
            if wheel.psi != nil {
                Text(verbatim: "psi").font(Font(Self.unitFont(textScale)))
            }
        }
        .foregroundStyle(wheel.isDimmed ? Palette.tireStale : Palette.textPrimary)
        .fixedSize()
        .frame(height: lineHeight)
        .padding(.horizontal, 2)
        .background(Palette.tireBacking)
        .padding(.horizontal, -2)
    }

    static let unitGap: CGFloat = 3

    static func readingFont(_ scale: CGFloat) -> UIFont { HUDFont.tabular(HUDFont.interSemiBold, size: 19 * scale) }
    static func unitFont(_ scale: CGFloat) -> UIFont { HUDFont.tabular(HUDFont.interRegular, size: 12 * scale) }

    /// The master's `tireNeedsList`: a reading wider than its column, a time line over two lines, or
    /// a title over one line switches to the list.
    static func needsList(_ copy: TireCopy, geometry: TireGeometry, textScale scale: CGFloat) -> Bool {
        func width(_ string: String, _ font: UIFont) -> CGFloat {
            (string as NSString).size(withAttributes: [.font: font]).width
        }
        /// Laid-out height at the CSS line height.
        func height(_ string: String, _ font: UIFont, width: CGFloat, lineHeight: CGFloat) -> CGFloat {
            let box = (string as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                        options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
            return (box.height / font.lineHeight).rounded() * lineHeight
        }
        let readingWidths = copy.wheels.map { wheel in
            wheel.psi.map { width(String($0), readingFont(scale)) + unitGap + width("psi", unitFont(scale)) }
                ?? width("—", readingFont(scale))
        }
        if readingWidths.contains(where: { $0 > geometry.column + 0.01 }) { return true }
        let summaryScale = min(scale, 1.5)
        if let summary = copy.summary,
           height(summary, .systemFont(ofSize: 12 * summaryScale), width: geometry.size.width - 4,
                  lineHeight: 14 * summaryScale) > 32.01 {
            return true
        }
        return height(copy.title, .systemFont(ofSize: 14 * scale, weight: .semibold), width: geometry.size.width,
                      lineHeight: 18 * scale) > 24.01
    }
}

/// The master's `tireGeometry` for the 184-wide (844) and 165-wide (667) panels, in panel points.
struct TireGeometry {
    let size: CGSize
    let carSize: CGSize
    let carTop: CGFloat
    /// The left wheels' readings end at `labelRight`, the right wheels' start at `labelLeft`,
    /// each in a column this wide.
    let column: CGFloat
    let labelRight: CGFloat
    let labelLeft: CGFloat
    /// The front readings' line ends here, 8 above the front wheels; the rear ones start at
    /// `rearTop`, 8 below the rear wheels.
    let frontBottomY: CGFloat
    let rearTop: CGFloat
    /// The shared time line's top.
    let summaryTop: CGFloat

    init(size: CGSize) {
        self.size = size
        let carWidth: CGFloat = size.width < 184 ? 94 : 104
        carSize = CGSize(width: carWidth, height: carWidth * 2)
        carTop = size.width < 184 ? 34 : 30
        labelRight = size.width / 2 - carWidth * 0.32
        column = min(64, labelRight)
        labelLeft = size.width - labelRight
        frontBottomY = carTop + carSize.height * 0.19 - 8
        rearTop = carTop + carSize.height * 0.73 + 8
        summaryTop = size.height - 34
    }
}

/// The panel's words in the screen's language, for drawing, measuring and VoiceOver alike.
struct TireCopy {
    let title: String
    let notSupported: String
    let region: String
    /// Front left, front right, rear left, rear right.
    let positions: [String]
    let wheels: [TireWheel]
    /// 「左前,42 psi」, with the age for an old or unknown-time reading; 「右後,尚無讀值」, never "—".
    let spoken: [String]
    /// The shared time line; nil when there is none.
    let summary: String?

    init(panel: TirePanel, locale: Locale) {
        title = locale.localized("Tire pressure")
        notSupported = locale.localized("This car doesn't provide tire pressure")
        region = locale.localized("Four tire readings")
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

/// The ceramic car (`docs/design/frames/tire/car-ceramic.svg`, rasterized as is), dimmed by the
/// filter DESIGN.md gives it: `saturate(.12) brightness(.8)` (R6-10, L49).
struct CeramicCar: View {
    /// `App/Images/car-ceramic@2x.png` and `@3x.png`, rendered from the SVG by Chrome, as the master is.
    static let image = UIImage(named: "car-ceramic") ?? UIImage()

    var body: some View {
        Image(uiImage: Self.image)
            .resizable()
            .saturation(0.12)
            .colorMultiply(Color(white: 0.8))
            .accessibilityHidden(true)
    }
}

/// The list's small car, marking which wheel the row is (the master's `tireLocator`).
struct TireLocator: View {
    /// 0 front left, 1 front right, 2 rear left, 3 rear right.
    let wheel: Int

    var body: some View {
        Canvas { context, _ in
            context.stroke(Path(roundedRect: CGRect(x: 7, y: 3, width: 10, height: 34), cornerRadius: 4),
                           with: .color(Palette.tireStale), lineWidth: 1)
            for (i, origin) in [CGPoint(x: 2, y: 9), CGPoint(x: 18, y: 9), CGPoint(x: 2, y: 27), CGPoint(x: 18, y: 27)].enumerated() {
                let tire = Path(roundedRect: CGRect(origin: origin, size: CGSize(width: 4, height: 7)), cornerRadius: 2)
                context.fill(tire, with: .color(i == wheel ? Palette.textSecondary : Palette.tireBacking))
                context.stroke(tire, with: .color(Palette.textSecondary), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}
