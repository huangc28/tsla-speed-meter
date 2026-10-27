import HUDCore
import SwiftUI

/// The drive screen (S04 / S05): icon-only source chip top-left, the time top-center, settings
/// gear top-right, gauge A centered and fixed with `P R N D` above the numeral (Car Bluetooth
/// only), bottom-left battery slot (empty on GPS), nothing
/// animated (L31, L32, L81).
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
            // Centered on the gauge and on the chip's 28-high line (L74, L82).
            ClockText(now: now)
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
            // `layout.batterySlot` stays empty: battery / range needs Car Bluetooth (L50, 01 §7.4).
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

/// The time, `14:05`: Inter 15/600, tabular, 24-hour as in the mockups. The drive screen passes
/// a new `now` each minute.
struct ClockText: View {
    let now: Date

    var body: some View {
        Text(verbatim: now.formatted(Self.format))
            .font(.custom(HUDFont.interSemiBold, fixedSize: 15))
            .monospacedDigit()
            .foregroundStyle(Palette.textSecondary)
            .fixedSize()
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
