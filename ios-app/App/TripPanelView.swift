import HUDCore
import SwiftUI
import UIKit

/// The drive screen's left panel (L80, DESIGN.md "Drive side panels", the master's `wingTrip`):
/// 本趟 and 行駛時間, a small label over each value, with no title or source note. Centered in the
/// panel by the caller. On GPS only it is the same (L71).
struct TripPanelView: View {
    let trip: TripSummary
    let unit: SpeedUnit
    @Environment(\.locale) private var locale

    var body: some View {
        let copy = TripCopy(trip: trip, unit: unit, locale: locale)
        VStack(alignment: .leading, spacing: 17) {
            item(copy.distanceLabel, copy.distance, unit: copy.distanceUnit)
            item(copy.driveTimeLabel, copy.driveTime, unit: nil)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: copy.title))
        .accessibilityValue(Text(verbatim: copy.spoken([copy.spokenDistance, copy.spokenDriveTime])))
    }

    /// Label 13/600 `unit`, tracking 1, on a 16 line; 3 below it the value 22/600 `text.secondary`,
    /// tabular, on a 26 line, its unit 12/500 `unit` 5 after it. As in the master, a unit keeps the
    /// 26 line height at its own size, which grows the line 3.6 below the value.
    private func item(_ label: String, _ value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: label)
                .font(.custom(HUDFont.interSemiBold, fixedSize: 13))
                .tracking(1)
                .foregroundStyle(Palette.unit)
                .frame(height: 16)
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
            .frame(height: unit == nil ? 26 : 29.6, alignment: .top)
        }
        .lineLimit(1)
        .fixedSize()
    }
}

/// The parked screen's left card (L73 S12-05, the master's `.htrip.tight`): the title 「行程」, the
/// GPS group (本趟, 平均, 最高, 行駛時間) with its source note, then, after a divider, 本趟電量變化 with
/// its own note. The battery group is left out when the trip has no battery change. When the card
/// is taller than the panel (667 with the battery group, English) it scrolls inside it (L24), with no
/// indicator and the bottom 28 fading out, as the master's `.pn.scroll`; its end scrolls clear of the
/// fade.
struct TripCardView: View {
    let trip: TripSummary
    let unit: SpeedUnit
    let size: CGSize
    @Environment(\.locale) private var locale

    /// The master's fade at the bottom of a panel that scrolls.
    static let fadeHeight: CGFloat = 28

    var body: some View {
        let copy = TripCopy(trip: trip, unit: unit, locale: locale)
        Group {
            if !Self.scrolls(trip, unit: unit, locale: locale, size: size) {
                card(copy)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    card(copy).padding(.bottom, Self.fadeHeight)
                }
                .mask(LinearGradient(stops: [.init(color: .black, location: 1 - Self.fadeHeight / size.height),
                                             .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: copy.title))
        .accessibilityValue(Text(verbatim: copy.spokenCard))
    }

    /// Whether the card scrolls in a panel of `size`.
    static func scrolls(_ trip: TripSummary, unit: SpeedUnit, locale: Locale, size: CGSize) -> Bool {
        height(TripCopy(trip: trip, unit: unit, locale: locale), width: size.width) > size.height
    }

    /// The card's height at `width`. Every line has a fixed height, so it is known before layout: the
    /// title and its gap 24, the first row 29 and the others 28, each note 4 + 16 a line, and the
    /// battery group 4 + 29 before its note.
    static func height(_ copy: TripCopy, width: CGFloat) -> CGFloat {
        let gps = 24 + 29 + 3 * 28 + 4 + noteHeight(copy.gpsNote, width: width)
        guard copy.batteryChange != nil else { return gps }
        return gps + 4 + 29 + 4 + noteHeight(copy.batteryNote, width: width)
    }

    static let noteFont = UIFont(name: HUDFont.interRegular, size: 13) ?? .systemFont(ofSize: 13)

    /// 16 a line, counted with Inter's line height, so a Chinese fallback font's taller line does not
    /// add one.
    static func noteHeight(_ text: String, width: CGFloat) -> CGFloat {
        let box = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                  options: .usesLineFragmentOrigin, attributes: [.font: noteFont], context: nil)
        return 16 * max(1, (box.height / noteFont.lineHeight).rounded())
    }

    private func card(_ copy: TripCopy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Plain text until the card switcher (#79) makes it the ⌄ button; spaced like the button,
            // so the rows stay where the master has them.
            Text(verbatim: copy.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
                .frame(height: 20)
                .padding(.bottom, 4)
            row(copy.distanceLabel, copy.distance, unit: copy.distanceUnit, first: true)
            row(copy.averageLabel, copy.average, unit: copy.speedUnit(copy.average))
            row(copy.maxLabel, copy.max, unit: copy.speedUnit(copy.max))
            row(copy.driveTimeLabel, copy.driveTime, unit: nil)
            note(copy.gpsNote)
            if let change = copy.batteryChange {
                row(copy.batteryChangeLabel, change, unit: "%", first: true)
                    .padding(.top, 4)
                note(copy.batteryNote)
            }
        }
        .frame(width: size.width, alignment: .leading)
    }

    /// 28 high with its bottom `divider` (29 with a top one too): the label 13/600 `unit`, tracking 1,
    /// and the value 18/600 `text.primary`, tabular, on one baseline 2 below the top; unit 12/500 `unit`.
    private func row(_ label: String, _ value: String, unit: String?, first: Bool = false) -> some View {
        VStack(spacing: 0) {
            if first { divider }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: label)
                    .font(.custom(HUDFont.interSemiBold, fixedSize: 13))
                    .tracking(1)
                    .foregroundStyle(Palette.unit)
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(verbatim: value)
                        .font(Font(HUDFont.tabular(HUDFont.interSemiBold, size: 18)))
                        .foregroundStyle(Palette.textPrimary)
                    if let unit {
                        Text(verbatim: unit)
                            .font(.custom(HUDFont.interMedium, fixedSize: 12))
                            .foregroundStyle(Palette.unit)
                    }
                }
                .fixedSize()
            }
            .lineLimit(1)
            .padding(.top, 2)
            .frame(height: 27, alignment: .top)
            divider
        }
    }

    private var divider: some View {
        Palette.divider.frame(height: 1)
    }

    /// A source note: 13 `unit` on 16 lines, 4 below the group (S12-03: small print is 13 or more).
    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Font(Self.noteFont))
            .foregroundStyle(Palette.unit)
            .frame(width: size.width, height: Self.noteHeight(text, width: size.width), alignment: .leading)
            .padding(.top, 4)
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
