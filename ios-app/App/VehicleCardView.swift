import HUDCore
import SwiftUI
import UIKit

/// The parked 車況 card (#79, the master's `A-v-park-vehicle` and `VEHICLE`): the title button, then
/// 總里程, 車外, 車內 and 車窗 as the trip card's rows with more room (`.htrip .tr`: 7 above and below,
/// the label 13/600 and the value 18/600 on one baseline). In the drive frame's type (#101): the system font, labels
/// in `FF.sec`, values in `FF.mid`, at the canvas's `scale`. A row too wide for one line (English) puts its value
/// under the label, right-aligned. A row whose value is missing is left out; with none, 「尚無讀值」. One VoiceOver
/// element 「車況」 read in words.
struct VehicleCardView: View {
    let vehicle: VehicleCard?
    let unit: SpeedUnit
    let width: CGFloat
    let title: CardTitle
    var scale: CGFloat = 1
    /// The panel scrolls: the swipe starts on the title row only.
    var swipesOnTitle = false
    @Environment(\.locale) private var locale

    static func labelFont(_ scale: CGFloat) -> UIFont { .systemFont(ofSize: 13 * scale, weight: .semibold) }
    static func valueFont(_ scale: CGFloat) -> UIFont { .monospacedDigitSystemFont(ofSize: 18 * scale, weight: .semibold) }
    static func unitFont(_ scale: CGFloat) -> UIFont { .systemFont(ofSize: 12 * scale, weight: .medium) }
    /// A value line, and the padding above and below it.
    static let lineHeight: CGFloat = 22
    static let padding: CGFloat = 7

    /// The card's height at `width`: the title and its gap 24, then each row 7 + its lines + 7 and its
    /// bottom divider, the first with one on top too.
    static func height(_ copy: VehicleCopy, width: CGFloat, scale: CGFloat) -> CGFloat {
        guard !copy.rows.isEmpty else { return 24 * scale + (CardLine.topGap - 4) * scale + CardLine.font(scale).lineHeight.rounded(.up) }
        return 24 * scale + 1 + copy.rows.reduce(0) { $0 + rowHeight($1, width: width, scale: scale) }
    }

    /// The label's line when the value goes under it.
    static let labelLineHeight: CGFloat = 18

    /// The label and the value side by side fit `width`.
    static func fitsOneLine(_ row: VehicleCopy.Row, width: CGFloat, scale: CGFloat) -> Bool {
        let label = (row.label as NSString).size(withAttributes: [.font: labelFont(scale)]).width
        return label + 8 * scale + valueWidth(row, scale: scale) <= width
    }

    static func valueWidth(_ row: VehicleCopy.Row, scale: CGFloat) -> CGFloat {
        (row.value as NSString).size(withAttributes: [.font: valueFont(scale)]).width
            + (row.unit.map { 3 * scale + ($0 as NSString).size(withAttributes: [.font: unitFont(scale)]).width } ?? 0)
    }

    static func rowHeight(_ row: VehicleCopy.Row, width: CGFloat, scale: CGFloat) -> CGFloat {
        (2 * padding + lineHeight + (fitsOneLine(row, width: width, scale: scale) ? 0 : labelLineHeight)) * scale + 1
    }

    var body: some View {
        let copy = VehicleCopy(vehicle: vehicle, unit: unit, locale: locale)
        VStack(alignment: .leading, spacing: 0) {
            CardTitleButton(card: .vehicle, title: title, width: width, scale: scale, swipes: swipesOnTitle)
                .accessibilitySortPriority(DriveScreen.readingOrder.leftTitle)
                .padding(.bottom, 4 * scale)
            if copy.rows.isEmpty {
                CardLine(text: "No readings yet", scale: scale)
                    .padding(.top, (CardLine.topGap - 4) * scale)
                    .accessibilitySortPriority(DriveScreen.readingOrder.left)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Palette.divider.frame(height: 1)
                    ForEach(copy.rows, id: \.label) { row($0, oneLine: Self.fitsOneLine($0, width: width, scale: scale)) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: copy.title))
                .accessibilityValue(Text(verbatim: copy.spoken))
                .accessibilitySortPriority(DriveScreen.readingOrder.left)
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private func row(_ row: VehicleCopy.Row, oneLine: Bool) -> some View {
        VStack(spacing: 0) {
            Group {
                if oneLine {
                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        label(row)
                        Spacer(minLength: 8 * scale)
                        value(row)
                    }
                    .frame(height: Self.lineHeight * scale)
                } else {
                    VStack(alignment: .trailing, spacing: 0) {
                        label(row)
                            .frame(maxWidth: .infinity, minHeight: Self.labelLineHeight * scale, maxHeight: Self.labelLineHeight * scale,
                                   alignment: .leading)
                        value(row).frame(height: Self.lineHeight * scale)
                    }
                }
            }
            .padding(.vertical, Self.padding * scale)
            Palette.divider.frame(height: 1)
        }
    }

    private func label(_ row: VehicleCopy.Row) -> some View {
        Text(verbatim: row.label)
            .font(Font(Self.labelFont(scale)))
            .foregroundStyle(Palette.frameLabel)
            .fixedSize()
    }

    /// The value 18/600 `FF.mid`, its unit 12/500 `FF.sec` 3 after it, on one line.
    private func value(_ row: VehicleCopy.Row) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3 * scale) {
            Text(verbatim: row.value)
                .font(Font(Self.valueFont(scale)))
                .foregroundStyle(Palette.frameText)
            if let unit = row.unit {
                Text(verbatim: unit)
                    .font(Font(Self.unitFont(scale)))
                    .foregroundStyle(Palette.frameLabel)
            }
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// The 車況 card's words and values in the screen's language, for drawing and VoiceOver alike (07 §5).
struct VehicleCopy {
    struct Row {
        let label: String
        let value: String
        let unit: String?
        /// The sentence VoiceOver reads for it.
        let spoken: String
    }

    let title: String
    let rows: [Row]
    let locale: Locale

    init(vehicle: VehicleCard?, unit: SpeedUnit, locale: Locale) {
        self.locale = locale
        title = locale.localized("Vehicle")
        var rows: [Row] = []
        if let odometer = vehicle?.odometer {
            // Thousands grouped in every language, as the range.
            let value = odometer.formatted(.number.locale(Locale(identifier: "en_US")))
            let words = unit == .kilometersPerHour ? locale.localized("kilometers") : locale.localized("miles")
            rows.append(Row(label: locale.localized("Odometer"), value: value, unit: unit.distanceSymbol,
                            spoken: locale.localized("Odometer \(value) \(words)")))
        }
        if let outside = vehicle?.outsideCelsius {
            let degrees = TemperatureText.degrees(outside, locale: locale)
            rows.append(Row(label: locale.localized("Outside"), value: "\(degrees)°", unit: nil,
                            spoken: locale.localized("Outside \(degrees) degrees")))
        }
        if let inside = vehicle?.insideCelsius {
            let degrees = TemperatureText.degrees(inside, locale: locale)
            rows.append(Row(label: locale.localized("Inside"), value: "\(degrees)°", unit: nil,
                            spoken: locale.localized("Inside \(degrees) degrees")))
        }
        if let windows = vehicle?.windows {
            let (value, spoken) = Self.windows(windows, locale: locale)
            rows.append(Row(label: locale.localized("Windows"), value: value, unit: nil, spoken: spoken))
        }
        self.rows = rows
    }

    /// The row's value beside 「車窗」 (「都關著」, 「左後開著」, 「2 扇開著」) and the whole sentence of 07 §5
    /// (「車窗都關著」, 「左後車窗開著」, 「2 扇車窗開著」).
    static func windows(_ windows: WindowState, locale: Locale) -> (value: String, spoken: String) {
        switch windows {
        case .allClosed:
            return (locale.localized("All closed"), locale.localized("All windows closed"))
        case .open(let open) where open.count == 1:
            let position = switch open[0] {
            case .frontLeft: locale.localized("Front left")
            case .frontRight: locale.localized("Front right")
            case .rearLeft: locale.localized("Rear left")
            case .rearRight: locale.localized("Rear right")
            }
            return (locale.localized("\(position) open"), locale.localized("\(position) window open"))
        case .open(let open):
            return (locale.localized("\(open.count) open"), locale.localized("\(open.count) windows open"))
        }
    }

    /// 「總里程 12,345 公里,車外 23 度,車內 26 度,車窗都關著」.
    var spoken: String {
        rows.dropFirst().reduce(rows.first?.spoken ?? "") { locale.localized("\($0), \($1.spoken)") }
    }
}

/// Temperatures in the person's unit, °C or °F as the system shows them (07 §5), whole degrees.
enum TemperatureText {
    static func degrees(_ celsius: Double, locale: Locale) -> Int {
        let unit = UnitTemperature(forLocale: locale, usage: .weather)
        return Int(Measurement(value: celsius, unit: UnitTemperature.celsius).converted(to: unit).value.rounded())
    }
}
