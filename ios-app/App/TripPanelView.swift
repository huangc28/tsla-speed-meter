import HUDCore
import SwiftUI
import UIKit

/// The parked screen's 行程 card (L73 S12-05, the master's `.htrip.tight`): the title button 「行程 ⌄」
/// (#79), the GPS group (本趟, 平均, 最高, 行駛時間) with its source note, then, after a divider,
/// 本趟電量變化 with its own note. The battery group is left out when the trip has no battery change.
/// With no trip yet, 「尚無行程」. In the drive frame's type (#101): the system font, labels and notes in `FF.sec`,
/// values in `FF.mid`, at the canvas's `scale`. Its height is known before layout; the left panel scrolls it when it
/// is taller.
struct TripCardView: View {
    let trip: TripSummary?
    let unit: SpeedUnit
    let width: CGFloat
    let title: CardTitle
    var scale: CGFloat = 1
    /// The panel scrolls: the swipe starts on the title row only.
    var swipesOnTitle = false
    @Environment(\.locale) private var locale

    /// The card's height at `width`, `copy` nil with no trip. Every line has a fixed height: the title
    /// and its gap 24, each row 27 and its 1 px divider (the first with one on top too), each note 4 + its
    /// lines, and the battery group 4 + its row before its note.
    static func height(_ copy: TripCopy?, width: CGFloat, scale: CGFloat) -> CGFloat {
        guard let copy else { return 24 * scale + (CardLine.topGap - 4) * scale + CardLine.font(scale).lineHeight.rounded(.up) }
        let gps = 24 * scale + (27 * scale + 2) + 3 * (27 * scale + 1) + 4 * scale + noteHeight(copy.gpsNote, width: width, scale: scale)
        guard copy.batteryChange != nil else { return gps }
        return gps + 4 * scale + (27 * scale + 2) + 4 * scale + noteHeight(copy.batteryNote, width: width, scale: scale)
    }

    static func noteFont(_ scale: CGFloat) -> UIFont { .systemFont(ofSize: 13 * scale) }

    /// The note's laid-out height (in the system font a Chinese line is taller than a Latin one).
    static func noteHeight(_ text: String, width: CGFloat, scale: CGFloat) -> CGFloat {
        let box = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                  options: .usesLineFragmentOrigin, attributes: [.font: noteFont(scale)], context: nil)
        return box.height.rounded(.up)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The button's 4 below the row keep the rows where the master has them.
            CardTitleButton(card: .trip, title: title, width: width, scale: scale, swipes: swipesOnTitle)
                .accessibilitySortPriority(DriveScreen.readingOrder.leftTitle)
                .padding(.bottom, 4 * scale)
            if let trip {
                let copy = TripCopy(trip: trip, unit: unit, locale: locale)
                rows(copy)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: copy.title))
                    .accessibilityValue(Text(verbatim: copy.spokenCard))
                    .accessibilitySortPriority(DriveScreen.readingOrder.left)
            } else {
                CardLine(text: "No trip yet", scale: scale)
                    .padding(.top, (CardLine.topGap - 4) * scale)
                    .accessibilitySortPriority(DriveScreen.readingOrder.left)
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private func rows(_ copy: TripCopy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            row(copy.distanceLabel, copy.distance, unit: copy.distanceUnit, first: true)
            row(copy.averageLabel, copy.average, unit: copy.speedUnit(copy.average))
            row(copy.maxLabel, copy.max, unit: copy.speedUnit(copy.max))
            row(copy.driveTimeLabel, copy.driveTime, unit: nil)
            note(copy.gpsNote)
            if let change = copy.batteryChange {
                row(copy.batteryChangeLabel, change, unit: "%", first: true)
                    .padding(.top, 4 * scale)
                note(copy.batteryNote)
            }
        }
    }

    /// 27 high and its bottom `divider` (a top one too on the first): the label 13/600 `FF.sec`, and the value 18/600
    /// `FF.mid`, tabular, on one baseline 2 below the top; the unit 12/500 `FF.sec`.
    private func row(_ label: String, _ value: String, unit: String?, first: Bool = false) -> some View {
        VStack(spacing: 0) {
            if first { divider }
            HStack(alignment: .firstTextBaseline, spacing: 8 * scale) {
                Text(verbatim: label)
                    .font(.system(size: 13 * scale, weight: .semibold))
                    .foregroundStyle(Palette.frameLabel)
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 3 * scale) {
                    Text(verbatim: value)
                        .font(.system(size: 18 * scale, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Palette.frameText)
                    if let unit {
                        Text(verbatim: unit)
                            .font(.system(size: 12 * scale, weight: .medium))
                            .foregroundStyle(Palette.frameLabel)
                    }
                }
                .fixedSize()
            }
            .lineLimit(1)
            .padding(.top, 2 * scale)
            .frame(height: 27 * scale, alignment: .top)
            divider
        }
    }

    private var divider: some View {
        Palette.divider.frame(height: 1)
    }

    /// A source note: 13 `FF.sec`, 4 below the group (S12-03: small print is 13 or more).
    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Font(Self.noteFont(scale)))
            .foregroundStyle(Palette.frameLabel)
            .frame(width: width, height: Self.noteHeight(text, width: width, scale: scale), alignment: .leading)
            .padding(.top, 4 * scale)
    }
}

/// The trip's words and values in the screen's language, for drawing and VoiceOver alike. VoiceOver
/// never reads "—" or `h:mm`.
struct TripCopy {
    let trip: TripSummary
    let unit: SpeedUnit
    let locale: Locale

    var title: String { locale.localized("Trip") }
    /// 「本趟」: its English, "Trip", is also the title's.
    var distanceLabel: String { locale.localized("trip.distance", defaultValue: "Trip") }
    var averageLabel: String { locale.localized("Avg") }
    var maxLabel: String { locale.localized("Max") }
    var driveTimeLabel: String { locale.localized("Drive time") }
    var batteryChangeLabel: String { locale.localized("Battery change") }
    var gpsNote: String { locale.localized("Distance and speed from phone GPS") }
    var batteryNote: String { locale.localized("From car Bluetooth battery level") }

    /// `12.4`, one decimal, or "—".
    var distance: String { trip.distance.map { String(format: "%.1f", $0) } ?? HUDState.noSpeedNumeral }
    /// `km` or `mi`; none beside "—".
    var distanceUnit: String? { trip.distance == nil ? nil : unit.distanceSymbol }
    var average: String { trip.averageSpeed.map(String.init) ?? HUDState.noSpeedNumeral }
    var max: String { String(trip.maxSpeed) }
    /// `0:18`, `h:mm`.
    var driveTime: String { Self.driveTime(minutes: trip.driveMinutes) }
    /// `−4` (a real minus sign), `+3`, `0`; nil hides the battery group.
    var batteryChange: String? { trip.batteryChange.map(Self.signed) }

    func speedUnit(_ value: String) -> String? { value == HUDState.noSpeedNumeral ? nil : unit.symbol }

    static func driveTime(minutes: Int) -> String {
        "\(minutes / 60):" + String(format: "%02d", minutes % 60)
    }

    static func signed(_ value: Int) -> String {
        value < 0 ? "\u{2212}\(-value)" : value > 0 ? "+\(value)" : "0"
    }

    var spokenDistance: String {
        guard trip.distance != nil else { return locale.localized("Trip distance unavailable") }
        let words = unit == .kilometersPerHour ? locale.localized("kilometers") : locale.localized("miles")
        return locale.localized("Trip \(distance) \(words)")
    }

    var spokenDriveTime: String {
        let minutes = trip.driveMinutes
        return minutes < 60 ? locale.localized("Drive time \(minutes) min")
            : locale.localized("Drive time \(minutes / 60) hr \(minutes % 60) min")
    }

    private var speedWords: String {
        unit == .kilometersPerHour ? locale.localized("kilometers per hour") : locale.localized("miles per hour")
    }

    var spokenCard: String {
        var parts = [spokenDistance,
                     trip.averageSpeed.map { locale.localized("Average \($0) \(speedWords)") }
                        ?? locale.localized("Average unavailable"),
                     locale.localized("Max \(trip.maxSpeed) \(speedWords)"),
                     spokenDriveTime, gpsNote]
        if let batteryChange {
            let percent = "\(batteryChange)%"
            parts += [locale.localized("Battery change this trip \(percent)"), batteryNote]
        }
        return spoken(parts)
    }

    /// The parts joined as the language joins a list (`%@, %@`).
    func spoken(_ parts: [String]) -> String {
        parts.dropFirst().reduce(parts.first ?? "") { locale.localized("\($0), \($1)") }
    }
}
