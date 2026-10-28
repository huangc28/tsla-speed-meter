import HUDCore
import SwiftUI

/// The main screen (S04 / S05): icon-only source chip top-left, the time top-center, settings
/// gear top-right, gauge A centered and fixed with `P R N D` above the numeral (Car Bluetooth
/// only), bottom-left battery slot (empty on GPS), nothing animated (L31, L32, L81).
///
/// The left panel shows the trip (L89): 本趟 and 行駛時間 centered while driving, the trip card parked.
/// The right panel shows the car's navigation while driving (#77); a Q11 switch to it fades in.
///
/// The parked layout (S06, `HUDState.layout`) keeps the gauge exactly where it is and adds the
/// date to the time, the tire panel on the right, and a taller battery slot whose stale value
/// keeps its own age line.
struct DriveScreen: View {
    let state: HUDState
    /// The time shown top-center.
    let now: Date
    let screen: CGSize
    let layout: DriveLayout
    /// No car is paired: the gear carries the setup dot (01 §4.1, S04-a).
    let setupPending: Bool
    /// The first-launch invitation at the bottom (L66).
    let showsInvite: Bool
    let actions: DriveScreenActions
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var parked: Bool { state.layout == .parked }

    init(state: HUDState, now: Date, screen: CGSize, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat,
         setupPending: Bool = false, showsInvite: Bool = false, actions: DriveScreenActions = DriveScreenActions()) {
        self.state = state
        self.now = now
        self.screen = screen
        layout = DriveLayout(screen: screen, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset)
        self.setupPending = setupPending
        self.showsInvite = showsInvite
        self.actions = actions
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(colors: [Palette.backgroundGlow, Palette.background],
                           center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0,
                           endRadius: hypot(screen.width / 2, screen.height * 0.55))
            SourceIconChip(status: state.source)
                .offset(x: layout.sourceChipOrigin.x, y: layout.sourceChipOrigin.y)
            // Centered on the gauge and on the chip's 28-high line (L74, L82). Parked adds the date at
            // 844 in Chinese, as plain text (the master's `parkedA`; no pill, L81).
            ClockText(now: now, showsDate: parked && layout.gaugeArea.width >= 300 && locale.language.languageCode == .chinese)
                .position(x: layout.gaugeArea.midX, y: layout.sourceChipOrigin.y + 14)
            GaugeView(state: state, size: layout.gaugeArea.width)
                .offset(x: layout.gaugeArea.minX, y: layout.gaugeArea.minY)
            if let gear = state.gearRow {
                // Its own element, so the gauge keeps only the speed sentence. On whole points; the
                // baseline keeps its fraction.
                let top = (layout.gearRowBaselineY - GearRow.capHeight - 4).rounded(.down)
                GearRow(gear: gear, baselineY: layout.gearRowBaselineY - top)
                    .offset(x: layout.gaugeArea.midX - GearRow.width / 2, y: top)
            }
            if let trip = state.trip {
                let panel = layout.leftPanel
                Group {
                    if parked {
                        TripCardView(trip: trip, unit: state.unit, size: panel.size)
                    } else {
                        TripPanelView(trip: trip, unit: state.unit)
                            .frame(width: panel.width, height: panel.height, alignment: .leading)
                    }
                }
                .offset(x: panel.minX, y: panel.minY)
            }
            // Only the Q11 switch fades (≤ 0.2 s, L73), at once with Reduce Motion; the rest never animates.
            ZStack(alignment: .topLeading) {
                if !parked, let navigation = state.navigation {
                    let panel = layout.rightPanel
                    NavigationPanelView(panel: navigation, unit: state.unit, size: panel.size)
                        .offset(x: panel.minX, y: panel.minY)
                        .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: state.navigationSwitches)
            // Empty on GPS: battery / range needs Car Bluetooth (L50, 01 §7.4).
            if let battery = state.battery {
                let slot = parked ? layout.parkedBatterySlot : layout.batterySlot
                BatteryBlockView(block: battery, unit: state.unit, parked: parked)
                    .frame(width: slot.width, height: slot.height, alignment: .bottomLeading)
                    .offset(x: slot.minX, y: slot.minY)
            }
            if let tires = state.tires {
                TirePanelView(panel: tires, size: layout.tirePanel.size)
                    .offset(x: layout.tirePanel.minX, y: layout.tirePanel.minY)
            }
            SettingsGearButton(setupPending: setupPending, action: actions.openSettings)
                .offset(x: layout.settingsGear.minX, y: layout.settingsGear.minY)
        }
        .frame(width: screen.width, height: screen.height, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            if showsInvite {
                InviteCard(connect: actions.connect, later: actions.dismissInvite)
                    .frame(maxWidth: screen.width - 2 * layout.sourceChipOrigin.x)
                    .padding(.bottom, screen.height - layout.contentBottom)
            }
        }
        .background(Palette.background)
        .transaction { $0.animation = nil }
    }
}

/// What the drive screen's controls do.
struct DriveScreenActions {
    var openSettings: @MainActor () -> Void = {}
    /// 現在連接 on the invitation.
    var connect: @MainActor () -> Void = {}
    /// 之後再說: the invitation never shows again.
    var dismissInvite: @MainActor () -> Void = {}
}

/// The settings entry, a 48×48 hit area (DESIGN.md Layout). While no car is paired it
/// carries a setup dot: a shape, not only a color (01 §4.1, S04-a).
struct SettingsGearButton: View {
    let setupPending: Bool
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            LucideIconView(icon: .settings, size: 24, color: Palette.textTertiary)
                .frame(width: 48, height: 48)
                .overlay(alignment: .topLeading) {
                    if setupPending {
                        Circle()
                            .fill(Palette.accent)
                            .padding(2)
                            .background(Circle().fill(Palette.background))
                            .frame(width: 14, height: 14)
                            .offset(x: 31, y: 3)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Settings"))
        .accessibilityValue(setupPending ? Text("Setup not finished") : Text(verbatim: ""))
    }
}

/// L66: one card at the bottom on first launch, while no car is paired.
struct InviteCard: View {
    let connect: @MainActor () -> Void
    let later: @MainActor () -> Void

    var body: some View {
        // As wide as its text on one line, or the full width with the text on two.
        ViewThatFits(in: .horizontal) {
            card.fixedSize(horizontal: true, vertical: false)
            card
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            Text("Connect your Tesla to see gear, battery and tires")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            Button(action: later) {
                Text("Maybe later")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textRow)
                    .padding(.horizontal, 14)
                    .frame(minWidth: 44, minHeight: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.cardBorder))
                    .fixedSize()
            }
            Button(action: connect) {
                Text("Connect now")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Palette.background)
                    .padding(.horizontal, 14)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 10))
                    .fixedSize()
            }
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.cardBorder))
    }
}

/// The drive screen's source chip, icons only (L81): each source has its own shape and color,
/// and the words are its accessibility label.
struct SourceIconChip: View {
    let status: SourceStatus

    var body: some View {
        HStack(spacing: 6) {
            switch status {
            case .valid(.carBluetooth):
                LucideIconView(icon: .bluetooth, size: 22, color: Palette.sourceOK)
            case .gpsFallback:
                LucideIconView(icon: .navigation, size: 20, color: Palette.sourceDegraded)
                LucideIconView(icon: .bluetoothOff, size: 20, color: Palette.unit)
            case .valid(.gps):
                LucideIconView(icon: .navigation, size: 20, color: Palette.sourceOK)
            case .waiting:
                LucideIconView(icon: .circleDashed, size: 20, color: Palette.unit)
            case .searchingGPS, .speedUnavailable, .gpsUnavailable:
                LucideIconView(icon: .triangleAlert, size: 20, color: Palette.sourceDegraded)
            }
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Speed source: \(Text(status.label))"))
    }
}

/// Battery / range, bottom-left (L33, L50, DESIGN.md "Main screen — direction A"): a battery icon,
/// then `72% / 315 km` in Inter 17/500, tabular, on one 24-high line at the bottom of the slot.
/// When that does not fit, it wraps to `72%` / `315 km`, the second line under the text, growing up.
/// Parked, a stale value stays in `text.stale` with a grey level and its own 「N 分鐘前」 line under
/// it (L21); driving, it shows `—% / — km`.
struct BatteryBlockView: View {
    let block: BatteryBlock
    let unit: SpeedUnit
    var parked = false
    @Environment(\.locale) private var locale

    static let lineHeight: CGFloat = 24
    /// The icon (30 body + 3 terminal) and the 10 after it: where the text starts.
    static let textInset: CGFloat = 43

    /// `72%` and `315 km`, or `—%` and `— km` while waiting or stale. Range groups thousands
    /// (`1,015 km`) in every language.
    static func parts(_ block: BatteryBlock, unit: SpeedUnit) -> (battery: String, range: String) {
        guard case .value(let percent, let range) = block else { return ("—%", "— \(unit.distanceSymbol)") }
        let rangeText = range.map { $0.formatted(.number.locale(Locale(identifier: "en_US"))) } ?? "—"
        return ("\(percent.map(String.init) ?? "—")%", "\(rangeText) \(unit.distanceSymbol)")
    }

    /// The shown text, or words when there is no value: VoiceOver never reads "—% / — km".
    static func spokenValue(_ block: BatteryBlock, unit: SpeedUnit) -> Text {
        guard case .value = block else { return Text("Battery: no reading yet") }
        let parts = parts(block, unit: unit)
        return Text(verbatim: "\(parts.battery) / \(parts.range)")
    }

    /// What the block shows: parked, a stale value is shown as a value.
    private var shown: BatteryBlock {
        if parked, case .stale(let percent, let range, _) = block { .value(percent: percent, range: range) } else { block }
    }

    /// The age line's minutes: parked with a stale value only.
    private var staleMinutes: Int? {
        if parked, case .stale(_, _, let minutes) = block { minutes } else { nil }
    }

    var body: some View {
        let parts = Self.parts(shown, unit: unit)
        let age = staleMinutes.map { AgeText.text(minutes: $0, locale: locale) }
        VStack(alignment: .leading, spacing: 2) {
            ViewThatFits(in: .horizontal) {
                line(icon: true, "\(parts.battery) / \(parts.range)").fixedSize()
                VStack(alignment: .leading, spacing: 2) {
                    line(icon: true, parts.battery)
                    line(icon: false, parts.range).padding(.leading, Self.textInset)
                }
            }
            if let age {
                Text(verbatim: age)
                    .font(.custom(HUDFont.interMedium, fixedSize: 13))
                    .foregroundStyle(Palette.textSecondary)
                    .frame(height: 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Battery and range"))
        .accessibilityValue(age.map { Text("\(Self.spokenValue(shown, unit: unit)), \($0)") }
            ?? Self.spokenValue(shown, unit: unit))
    }

    /// The icon's fill; none while waiting or stale on the drive screen, so no old level shows.
    private var level: Int? {
        if case .value(let percent?, _) = shown { percent } else { nil }
    }

    private func line(icon: Bool, _ text: String) -> some View {
        HStack(spacing: 10) {
            if icon { BatteryIcon(percent: level, stale: staleMinutes != nil) }
            Text(verbatim: text)
                .font(.custom(HUDFont.interMedium, fixedSize: 17))
                .monospacedDigit()
                .foregroundStyle(staleMinutes != nil ? Palette.textStale : Palette.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(height: Self.lineHeight)
    }
}

/// A 30×14 body with a 1 px inner border, filled from the left to the battery level (empty
/// with no level, grey for a stale level), and a 3×7 terminal.
struct BatteryIcon: View {
    let percent: Int?
    var stale = false

    var body: some View {
        HStack(spacing: 0) {
            let body = RoundedRectangle(cornerRadius: 3)
            ZStack(alignment: .leading) {
                body.fill(Palette.surfaceRaised)
                body.strokeBorder(Palette.cardBorder, lineWidth: 1)
                // The level paints over the border, as in the master.
                Rectangle()
                    .fill(stale ? AnyShapeStyle(Palette.batteryStaleFill)
                        : AnyShapeStyle(LinearGradient(colors: Palette.batteryFill, startPoint: .leading, endPoint: .trailing)))
                    .frame(width: 30 * CGFloat(min(max(percent ?? 0, 0), 100)) / 100)
            }
            .frame(width: 30, height: 14)
            .clipShape(body)
            UnevenRoundedRectangle(bottomTrailingRadius: 2, topTrailingRadius: 2)
                .fill(Palette.cardBorder)
                .frame(width: 3, height: 7)
        }
    }
}

/// The time, `14:05`: Inter 15/600, tabular, 24-hour as in the mockups. The drive screen passes
/// a new `now` each minute. Parked can lead with the date, `10/27(二) 14:05`.
struct ClockText: View {
    let now: Date
    var showsDate = false

    var body: some View {
        Text(verbatim: Self.text(now, showsDate: showsDate))
            .font(.custom(HUDFont.interSemiBold, fixedSize: 15))
            .monospacedDigit()
            .foregroundStyle(Palette.textSecondary)
            .fixedSize()
    }

    static func text(_ now: Date, showsDate: Bool) -> String {
        let time = now.formatted(format)
        guard showsDate else { return time }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        let date = calendar.dateComponents([.month, .day, .weekday], from: now)
        let weekday = Array("日一二三四五六")[(date.weekday ?? 1) - 1]
        return "\(date.month ?? 0)/\(date.day ?? 0)(\(weekday)) \(time)"
    }

    static let format = Date.VerbatimFormatStyle(
        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)",
        timeZone: .autoupdatingCurrent, calendar: Calendar(identifier: .gregorian))
}

/// Always names the current speed source with a shape, a color and a word (L3, L9, 01 §3.4).
/// Pairing's S17 still shows it; the drive screen uses `SourceIconChip`.
struct SourceChip: View {
    let status: SourceStatus

    var body: some View {
        HStack(spacing: 8) {
            SourceMarkerView(marker: status.marker)
            Text(status.label)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Speed source: \(Text(status.label))"))
    }
}

struct SourceMarkerView: View {
    let marker: SourceMarker

    var body: some View {
        switch marker {
        case .valid:
            Circle().fill(Palette.sourceOK).frame(width: 12, height: 12)
        case .fallback:
            Circle()
                .fill(LinearGradient(stops: [.init(color: Palette.sourceDegraded, location: 0.5),
                                             .init(color: .clear, location: 0.5)],
                                     startPoint: .leading, endPoint: .trailing))
                .overlay(Circle().strokeBorder(Palette.sourceDegraded, lineWidth: 2))
                .frame(width: 12, height: 12)
        case .waiting:
            Circle().strokeBorder(Palette.unit, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                .frame(width: 12, height: 12)
        case .noSpeed:
            Triangle().fill(Palette.sourceDegraded).frame(width: 14, height: 12)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension SourceStatus {
    /// Chip wording from 01 §6.1 and DESIGN.md's hardened states. No source is ever called "Tesla".
    var label: LocalizedStringKey { LocalizedStringKey(labelKey) }

    /// The English wording, which is also its `Localizable.strings` key.
    var labelKey: String {
        switch self {
        case .valid(.carBluetooth): "Car Bluetooth"
        case .valid(.gps): "GPS"
        case .gpsFallback: "GPS · Car data stale"
        case .waiting: "Waiting for speed"
        case .searchingGPS: "Searching for GPS…"
        case .speedUnavailable: "Speed unavailable"
        case .gpsUnavailable: "GPS unavailable"
        }
    }
}
