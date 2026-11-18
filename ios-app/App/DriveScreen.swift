import HUDCore
import SwiftUI

/// The main screen (S04 / S05), on the design canvas (#98, #100, the design page's `drawMain`): the source icon
/// top-left with the time beside it, the settings gear top-right, the round gauge centred and fixed with
/// `P R N D` inside the top of the ring (Car Bluetooth only), and the footer: battery and range on the left, `ODO`
/// on the right (empty on GPS). Nothing animated (L31, L32, L81).
///
/// Driving, the left card shows the car navigation while it is shown (L73 Q11; the switch to it fades in), and
/// otherwise the trip, in the same frame (owner decision 1, #96). The right is the tire column, with car data.
/// Nothing on them can be tapped.
///
/// Parked, each panel shows its chosen card under a title button (#79): 行程 or 車況 on the left, 胎壓 or
/// 車上導航 on the right, switched with the title's list or a vertical swipe, in the drive frame's bands with no
/// face (#101). Leaving parked, the panels fade to their drive content (≤ 0.3 s, at once with Reduce Motion). The
/// parked layout (S06, `HUDState.layout`) keeps the gauge, the top row and the footer where they are, and adds the
/// date to the time and the outside temperature.
struct DriveScreen: View {
    let state: HUDState
    /// The time shown top-left.
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
        let canvas = layout.canvas
        ZStack(alignment: .topLeading) {
            GroundView()
            // The time 12 right of the chip, on the top row's 28-high line, so the top centre belongs to the ring
            // (the design page's `topRow`). Parked adds the date in front of it at 844 and wider in Chinese, as
            // plain text (the master's `parkedA`; no pill, L81).
            HStack(spacing: canvas.length(12)) {
                SourceIconChip(status: state.source, scale: canvas.scale)
                ClockText(now: now, showsDate: parked && screen.width >= 844 && locale.language.languageCode == .chinese,
                          scale: canvas.scale)
            }
            .frame(height: layout.topRowHeight)
            .offset(x: layout.sourceChipOrigin.x, y: layout.sourceChipOrigin.y)
            .accessibilitySortPriority(Self.readingOrder.topRow)
            if parked, let outside = state.vehicle?.outsideCelsius {
                // Left of the gear, parked only; none without a value (#79, M12-13).
                OutsideTemperatureView(celsius: outside, scale: canvas.scale)
                    .frame(width: layout.temperatureSlot.width, height: layout.temperatureSlot.height, alignment: .trailing)
                    .offset(x: layout.temperatureSlot.minX, y: layout.temperatureSlot.minY)
                    .accessibilitySortPriority(Self.readingOrder.temperature)
            }
            ZStack(alignment: .topLeading) {
                if parked, let panels = state.panels {
                    let panel = Self.leftFrame(layout, showsHint: panels.showsHint, locale: locale)
                    // The title button and the body carry their own reading order (`leftTitle`, `left`).
                    LeftCardView(state: state, title: cardTitle(.left, panels), size: panel.size, showsHint: panels.showsHint,
                                 scale: canvas.scale)
                        .offset(x: panel.minX, y: panel.minY)
                        .transition(.opacity)
                } else if let card = state.driveLeftCard {
                    // The face stays when only the content changes (trip to navigation), so it never dims.
                    ZStack(alignment: .topLeading) {
                        LeftCardFace(canvas: canvas)
                        LeftCardContent(card: card, unit: state.unit, canvas: canvas)
                            .id(Self.contentKind(card))
                            .transition(.opacity)
                    }
                    .transition(.opacity)
                    .accessibilitySortPriority(Self.readingOrder.left)
                }
            }
            // Only the Q11 switch (L73) and leaving parked (M12-03) fade, at once with Reduce Motion: on this persistent
            // stack, so a card that appears with the switch (nothing on the left before it) fades in too.
            .animation(Self.navigationFade(reduceMotion: reduceMotion), value: state.navigationSwitches)
            .animation(parked ? nil : Self.panelFade(reduceMotion: reduceMotion), value: parked)
            let gauge = GaugeView.frame(canvas)
            GaugeView(state: state, canvas: canvas)
                .offset(x: gauge.minX, y: gauge.minY)
                .accessibilitySortPriority(Self.readingOrder.speed)
            if let gear = state.gearRow {
                // Its own element, so the gauge keeps only the speed sentence.
                let row = GearRow.frame(canvas)
                GearRow(gear: gear, canvas: canvas)
                    .offset(x: row.minX, y: row.minY)
                    .accessibilitySortPriority(Self.readingOrder.gear)
            }
            if let status = state.carStatus {
                // Inside the ring at fixed slots, each lit disc its own element (#99, L108); a closed part
                // or a normal tire leaves its slot empty, and nothing moves when another lights. Without
                // car data (`carStatus` nil) nothing is drawn.
                CarStatusDiscs(status: status, canvas: canvas)
                    .accessibilitySortPriority(Self.readingOrder.discs)
            }
            ZStack(alignment: .topLeading) {
                if parked, let panels = state.panels {
                    // The right card on the canvas, its title and body each with their reading order (`rightTitle`, `right`).
                    RightCardView(state: state, title: cardTitle(.right, panels), layout: layout)
                        .transition(.opacity)
                } else if case .wheels(let wheels)? = state.tires {
                    // With car data only: hidden on GPS, with no link, or lost for more than 10 s.
                    TireColumnView(wheels: wheels, canvas: canvas)
                        .transition(.opacity)
                        .accessibilitySortPriority(Self.readingOrder.right)
                }
            }
            .animation(parked ? nil : Self.panelFade(reduceMotion: reduceMotion), value: parked)
            // Empty on GPS: battery / range and the odometer need Car Bluetooth (L50, 01 §7.4).
            if let battery = state.battery {
                BatteryBlockView(block: battery, unit: state.unit, parked: parked, canvas: canvas)
                    .accessibilitySortPriority(Self.readingOrder.battery)
            }
            if let odometer = state.odometer {
                OdometerView(odometer: odometer, unit: state.unit, canvas: canvas)
                    .accessibilitySortPriority(Self.readingOrder.odometer)
            }
            SettingsGearButton(setupPending: setupPending, scale: canvas.scale, action: actions.openSettings)
                .offset(x: layout.settingsGear.minX, y: layout.settingsGear.minY)
                .accessibilitySortPriority(Self.readingOrder.settings)
            if parked, let panels = state.panels, let side = panels.openList {
                // A tap anywhere else closes the list.
                Color.clear
                    .frame(width: screen.width, height: screen.height)
                    .contentShape(Rectangle())
                    .onTapGesture { actions.cards(.closeList) }
                    .accessibilityHidden(true)
                let panel = Self.listFrame(side, layout: layout, showsHint: panels.showsHint, locale: locale)
                CardListView(title: cardTitle(side, panels), width: panel.width)
                    .offset(x: panel.minX, y: panel.minY)
            }
        }
        .frame(width: screen.width, height: screen.height, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            if showsInvite {
                InviteCard(connect: actions.connect, later: actions.dismissInvite)
                    .frame(maxWidth: screen.width - 2 * layout.sideMargin)
                    .padding(.bottom, screen.height - layout.contentBottom)
            }
        }
        .background(Palette.ground)
        .transaction { $0.animation = nil }
    }

    /// VoiceOver's order (#100): the top row, the left card, the speed, `P R N D`, the lit discs, the right column,
    /// the footer, then the settings gear. Every part is placed by offset, so SwiftUI cannot sort them by place.
    /// Parked (#101), the one-time card, then each card's title button before its body.
    static let readingOrder = (topRow: 10.0, temperature: 9.5, hint: 9.2, leftTitle: 9.1, left: 9.0, speed: 8.0, gear: 7.0, discs: 6.0,
                               rightTitle: 5.1, right: 5.0, battery: 4.0, odometer: 3.0, settings: 2.0)

    /// The left card's content kind: a switch between them is a new view, so it can fade.
    static func contentKind(_ card: DriveLeftCard) -> Int {
        if case .trip = card { 0 } else { 1 }
    }

    /// The parked left panel's frame, moved up when the one-time card needs it.
    static func leftFrame(_ layout: DriveLayout, showsHint: Bool, locale: Locale) -> CGRect {
        LeftCardView.frame(layout.leftPanel, showsHint: showsHint, locale: locale, hintTop: layout.parkedHintTop, scale: layout.canvas.scale)
    }

    /// An open card list's frame: over its panel, 6 past the panel's outer edges so its rounded corners
    /// cover the title, but no further than the panel toward the ring (#98): from x 69 to 245 on the left, 592 to 774
    /// on the right, at 844 (#101). The list is not scaled: its rows are 44-high
    /// hit areas.
    static func listFrame(_ side: PanelSide, layout: DriveLayout, showsHint: Bool, locale: Locale) -> CGRect {
        let panel = side == .left ? leftFrame(layout, showsHint: showsHint, locale: locale) : layout.tirePanel
        let out = panel.insetBy(dx: -6, dy: -6)
        let frame = side == .left
            ? CGRect(x: out.minX, y: out.minY, width: panel.maxX - out.minX, height: out.height)
            : CGRect(x: panel.minX, y: out.minY, width: out.maxX - panel.minX, height: out.height)
        // On whole points (the panels are on the canvas, #101), so its 44-high rows stay whole, and inside the panel's
        // ring-facing edge.
        let minX = side == .left ? frame.minX.rounded(.down) : frame.minX.rounded(.up)
        let maxX = side == .left ? frame.maxX.rounded(.down) : frame.maxX.rounded(.up)
        return CGRect(x: minX, y: frame.minY.rounded(.down), width: maxX - minX, height: frame.height)
    }

    /// The Q11 switch to navigation (L73): a fade of 0.2 s, or none with Reduce Motion.
    static func navigationFade(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }

    /// Leaving parked, the panels change to their drive content (M12-03): opacity only, within 300 ms, or
    /// at once with Reduce Motion.
    static func panelFade(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.25)
    }

    /// A parked side's title button; on the right its hit area stays below the settings gear's, rounded up to a whole
    /// point (at 667 a centred one would start 0.006 above it, #101).
    private func cardTitle(_ side: PanelSide, _ panels: ParkedPanels) -> CardTitle {
        CardTitle(side: side, deck: panels.deck(side),
                  topReach: side == .right ? layout.tirePanel.minY - layout.settingsGear.maxY.rounded(.up) : .infinity,
                  act: actions.cards)
    }
}

/// The ground (the design page's `.screen.te`): `ground` around the gauge, flat to 42%, darkening to
/// `ground-edge` toward the corners, on an ellipse 78% of the width by the full height, centred at 50% 44%.
/// No horizon, glow band or gradient under the gauge (the No-Horizon Rule).
struct GroundView: View {
    var body: some View {
        Canvas { context, size in
            let rx = 0.78 * size.width, ry = size.height
            var ellipse = context
            ellipse.translateBy(x: size.width / 2, y: 0.44 * size.height)
            ellipse.scaleBy(x: rx / ry, y: 1)
            let gradient = Gradient(stops: [.init(color: Palette.ground, location: 0), .init(color: Palette.ground, location: 0.42),
                                            .init(color: Palette.groundEdge, location: 1)])
            // The whole screen, in the ellipse's coordinates.
            let cover = CGRect(x: -size.width / 2 * ry / rx, y: -0.44 * size.height, width: size.width * ry / rx, height: size.height)
            ellipse.fill(Path(cover), with: .radialGradient(gradient, center: .zero, startRadius: 0, endRadius: ry))
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// What the drive screen's controls do.
struct DriveScreenActions {
    var openSettings: @MainActor () -> Void = {}
    /// 現在連接 on the invitation.
    var connect: @MainActor () -> Void = {}
    /// 之後再說: the invitation never shows again.
    var dismissInvite: @MainActor () -> Void = {}
    /// The parked cards' title buttons, lists, swipes and 知道了 (#79).
    var cards: @MainActor (CardAction) -> Void = { _ in }
}

/// The settings entry, a 48×48 hit area (DESIGN.md Layout), the gear 24 in `FF.sec` at the canvas's `scale`
/// (the page's `.gear`). While no car is paired it carries a setup dot: a shape, not only a color (01 §4.1, S04-a).
struct SettingsGearButton: View {
    let setupPending: Bool
    var scale: CGFloat = 1
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            LucideIconView(icon: .settings, size: 24 * scale, color: Palette.frameLabel)
                .frame(width: 48, height: 48)
                .overlay {
                    if setupPending {
                        // Its centre 14 right of and 14 above the gear's, as at 1×.
                        Circle()
                            .fill(Palette.accent)
                            .padding(2 * scale)
                            .background(Circle().fill(Palette.background))
                            .frame(width: 14 * scale, height: 14 * scale)
                            .offset(x: 14 * scale, y: -14 * scale)
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
    /// The design canvas's scale (#100): the icons and their gap scale with it.
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: 6 * scale) {
            switch status {
            case .valid(.carBluetooth):
                LucideIconView(icon: .bluetooth, size: 22 * scale, color: Palette.sourceOK)
            case .gpsFallback:
                LucideIconView(icon: .navigation, size: 20 * scale, color: Palette.sourceDegraded)
                LucideIconView(icon: .bluetoothOff, size: 20 * scale, color: Palette.unit)
            case .valid(.gps):
                LucideIconView(icon: .navigation, size: 20 * scale, color: Palette.sourceOK)
            case .waiting:
                LucideIconView(icon: .circleDashed, size: 20 * scale, color: Palette.unit)
            case .searchingGPS, .speedUnavailable, .gpsUnavailable:
                LucideIconView(icon: .triangleAlert, size: 20 * scale, color: Palette.sourceDegraded)
            }
        }
        .frame(height: 28 * scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Speed source: \(Text(status.label))"))
    }
}

/// The parked top row's outside temperature (#79, the master's `.htemp`): Lucide `thermometer` 16 and
/// `23°` 13/500, 4 apart, in `text.secondary`, in the system's °C / °F, at the canvas's `scale` (#101). VoiceOver reads
/// 「車外 23 度」.
struct OutsideTemperatureView: View {
    let celsius: Double
    var scale: CGFloat = 1
    @Environment(\.locale) private var locale

    var body: some View {
        let degrees = TemperatureText.degrees(celsius, locale: locale)
        HStack(spacing: 4 * scale) {
            LucideIconView(icon: .thermometer, size: 16 * scale, color: Palette.textSecondary)
            Text(verbatim: "\(degrees)°")
                .font(.custom(HUDFont.interMedium, fixedSize: 13 * scale))
                .monospacedDigit()
                .foregroundStyle(Palette.textSecondary)
                .fixedSize()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: locale.localized("Outside \(degrees) degrees")))
        .accessibilityAddTraits(.isImage)
    }
}

/// The time, `14:05`: the system font 17/600 in `FF.sec`, tabular (the page's `.htime`), at the canvas's
/// `scale`, 24-hour as in the mockups. The drive screen passes a new `now` each minute. Parked can lead with
/// the date, `10/27(二) 14:05`.
struct ClockText: View {
    let now: Date
    var showsDate = false
    var scale: CGFloat = 1

    var body: some View {
        Text(verbatim: Self.text(now, showsDate: showsDate))
            .font(.system(size: 17 * scale, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(Palette.frameLabel)
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
