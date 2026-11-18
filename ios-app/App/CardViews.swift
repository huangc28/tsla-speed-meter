import HUDCore
import SwiftUI
import UIKit

/// What a parked card's title button needs (#79, M12-14): its side's cards, where its hit area may reach,
/// and where the card actions go.
struct CardTitle {
    let side: PanelSide
    let deck: CardDeck
    /// How far the 44-high hit area may reach above the title row: half the extra height, or less where
    /// the settings gear is above (the right panel), so the two never overlap.
    var topReach: CGFloat = .infinity
    let act: @MainActor (CardAction) -> Void
}

extension PanelCard {
    /// The card's name: its title, its row in the list, and VoiceOver's.
    func name(_ locale: Locale) -> String {
        switch self {
        case .trip: locale.localized("Trip")
        case .vehicle: locale.localized("Vehicle")
        case .tires: locale.localized("Tire pressure")
        case .navigation: locale.localized("Car navigation")
        }
    }
}

/// A parked card's title as a button (the master's `.pt.btn` and `.tbtn`): the name 16/600 and a 16 ⌄ in
/// `accent.text` (L55: cyan only for what can be acted on), 2 apart, and the dots at the row's right end, on a 20 row
/// (#101: centred on the drive frame's titles' line), all at the canvas's `scale`. The hit area does not scale: 44 high,
/// at least 120 wide, around the row. VoiceOver reads 「胎壓，第 1 張，共 2 張」 with the button trait, and offers
/// 「下一張」 / 「上一張」 where there is one.
struct CardTitleButton: View {
    let card: PanelCard
    let title: CardTitle
    let width: CGFloat
    /// The design canvas's scale (#101).
    var scale: CGFloat = 1
    /// The card's content scrolls: the swipe counts only when it starts on this row.
    var swipes = false
    @Environment(\.locale) private var locale

    static let hitHeight: CGFloat = 44
    static let minHitWidth: CGFloat = 120
    static let fontSize: CGFloat = 16

    /// The row's height on the screen.
    static func rowHeight(_ scale: CGFloat) -> CGFloat { DriveFrame.parkedTitleHeight * scale }

    var body: some View {
        let rowHeight = Self.rowHeight(scale)
        let extra = Self.hitHeight - rowHeight
        let above = min(extra / 2, max(0, title.topReach))
        let position = title.deck.position ?? 1, count = title.deck.cards.count
        ZStack(alignment: .topLeading) {
            Button { title.act(.toggleList(title.side)) } label: {
                HStack(spacing: 2 * scale) {
                    Text(verbatim: card.name(locale))
                        .font(.system(size: Self.fontSize * scale, weight: .semibold))
                        .foregroundStyle(Palette.accentText)
                    LucideIconView(icon: .chevronDown, size: 16 * scale, color: Palette.accentText)
                }
                .lineLimit(1)
                .fixedSize()
                .frame(height: rowHeight)
                .padding(.top, above)
                .padding(.bottom, extra - above)
                .frame(minWidth: Self.minHitWidth, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .cardSwipe(title, on: .titleRow, scrolls: swipes)
            // The row keeps its height in the layout; the hit area reaches around it.
            .padding(.top, -above)
            .padding(.bottom, -(extra - above))
            .accessibilityLabel(Text(verbatim: locale.localized("\(card.name(locale)), card \(position) of \(count)")))
            .accessibilityActions {
                if position < count {
                    Button(locale.localized("Next card")) { title.act(.step(title.side, forward: true)) }
                }
                if position > 1 {
                    Button(locale.localized("Previous card")) { title.act(.step(title.side, forward: false)) }
                }
            }
            CardDots(position: position, count: count, scale: scale)
                .frame(width: width, height: rowHeight, alignment: .trailing)
        }
        .frame(width: width, height: rowHeight, alignment: .topLeading)
    }
}

/// The vertical dots at the title's right end (the master's `.dots`): 4 px, 3 apart, the current card
/// filled `text.secondary`, the others a 1 px ring in `text.tertiary`, at the canvas's `scale`. Parked only; not read aloud.
struct CardDots: View {
    let position: Int
    let count: Int
    var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: 3 * scale) {
            ForEach(1...max(1, count), id: \.self) { i in
                if i == position {
                    Circle().fill(Palette.textSecondary).frame(width: 4 * scale, height: 4 * scale)
                } else {
                    Circle().strokeBorder(Palette.textTertiary, lineWidth: scale).frame(width: 4 * scale, height: 4 * scale)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// The card list over a panel (07 §2.3, M12-14): a row per card, 44 high, the name 16/600, and a check in
/// front of the current one (a shape, not only a color). Choosing a card closes it; so does a tap outside,
/// the title again, or VoiceOver's escape.
struct CardListView: View {
    let title: CardTitle
    let width: CGFloat
    @Environment(\.locale) private var locale

    static let rowHeight: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            ForEach(title.deck.cards, id: \.self) { card in
                let current = card == title.deck.current
                Button { title.act(.choose(card)) } label: {
                    HStack(spacing: 8) {
                        LucideIconView(icon: .check, size: 16, color: Palette.accentText)
                            .opacity(current ? 1 : 0)
                        Text(verbatim: card.name(locale))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: Self.rowHeight, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: card.name(locale)))
                .accessibilityAddTraits(current ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
        .frame(width: width)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Palette.cardBorder))
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { title.act(.closeList) }
    }
}

/// The vertical swipe that switches parked cards (M12-14): one card a swipe, up for the next card and down
/// for the previous, with a light haptic when the card changes. On a card whose content scrolls, only a swipe
/// that starts on the title row switches; on the others it works anywhere on the panel.
///
/// The gesture is attached twice, to the whole panel and to the title row (`Surface`), and these functions
/// decide what each drag does, so the views stay thin: a drag on the title row of a card that does not
/// scroll reaches both, and only the panel's counts.
enum CardSwipe {
    static let minimumDistance: CGFloat = 12
    /// A swipe shorter than this does nothing.
    static let threshold: CGFloat = 30

    /// Where the drag's gesture is attached.
    enum Surface {
        case panel, titleRow
    }

    /// A drag on `surface` can switch: on the title row while the card scrolls, on the panel otherwise.
    static func counts(on surface: Surface, scrolls: Bool) -> Bool {
        scrolls ? surface == .titleRow : surface == .panel
    }

    /// On the title row of a card that scrolls, the swipe takes the drag from the scroll view (a
    /// high-priority gesture), so it switches the card and does not also scroll it; elsewhere it runs
    /// beside the content's own gestures.
    static func takesOverScrolling(on surface: Surface, scrolls: Bool) -> Bool {
        scrolls && surface == .titleRow
    }

    /// The step a finished drag makes: forward (up), back (down), or none: too short, or more sideways
    /// than vertical.
    static func step(_ translation: CGSize) -> Bool? {
        guard abs(translation.height) >= threshold, abs(translation.height) > abs(translation.width) else { return nil }
        return translation.height < 0
    }

    /// Whether a step moves off the current card (the ends do not wrap): only then is there a haptic.
    static func moves(_ deck: CardDeck, forward: Bool) -> Bool {
        guard let position = deck.position else { return false }
        return forward ? position < deck.cards.count : position > 1
    }

    /// A drag started on `surface`: the swipe begins if it counts there.
    @MainActor static func began(on surface: Surface, scrolls: Bool, title: CardTitle) {
        guard counts(on: surface, scrolls: scrolls) else { return }
        title.act(.beginSwipe(title.side))
    }

    /// A drag on `surface` ended after `translation`: the action to send, if any, and whether it changes the
    /// card (then the haptic plays).
    static func ended(_ translation: CGSize, on surface: Surface, scrolls: Bool,
                      side: PanelSide, deck: CardDeck) -> (action: CardAction, haptic: Bool)? {
        guard counts(on: surface, scrolls: scrolls), let forward = step(translation) else { return nil }
        return (.endSwipe(side, forward: forward), moves(deck, forward: forward))
    }

    /// `ended`, carried out: the haptic, then the action.
    @MainActor static func end(_ translation: CGSize, on surface: Surface, scrolls: Bool, title: CardTitle,
                               haptic: @MainActor () -> Void = lightHaptic) {
        guard let outcome = ended(translation, on: surface, scrolls: scrolls, side: title.side, deck: title.deck) else { return }
        if outcome.haptic { haptic() }
        title.act(outcome.action)
    }

    @MainActor static func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

/// Attaches the card swipe to a view; `CardSwipe` decides what each drag does.
struct CardSwipeModifier: ViewModifier {
    let title: CardTitle
    let surface: CardSwipe.Surface
    let scrolls: Bool
    @State private var began = false

    func body(content: Content) -> some View {
        let shaped = content.contentShape(Rectangle())
        if CardSwipe.takesOverScrolling(on: surface, scrolls: scrolls) {
            shaped.highPriorityGesture(drag)
        } else {
            shaped.simultaneousGesture(drag)
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: CardSwipe.minimumDistance)
            .onChanged { _ in
                guard !began else { return }
                began = true
                CardSwipe.began(on: surface, scrolls: scrolls, title: title)
            }
            .onEnded { value in
                began = false
                CardSwipe.end(value.translation, on: surface, scrolls: scrolls, title: title)
            }
    }
}

extension View {
    /// The card swipe on this view, the panel or the title row of a card that `scrolls` or not.
    func cardSwipe(_ title: CardTitle, on surface: CardSwipe.Surface, scrolls: Bool) -> some View {
        modifier(CardSwipeModifier(title: title, surface: surface, scrolls: scrolls))
    }
}

/// A parked panel's content from its top. Taller than the panel it scrolls inside it (L24), with the
/// system's scroll indicator and the bottom 28 fading out (the master's `.pn.scroll`), and its end scrolls
/// clear of the fade.
/// The scroll view reaches above the panel by half the title button's unscaled hit area beyond its scaled row
/// (`reach`), so a title button at the top keeps its whole hit area.
struct CardScroll<Content: View>: View {
    let size: CGSize
    let scrolls: Bool
    var scale: CGFloat = 1
    @ViewBuilder let content: Content

    /// The master's fade at the bottom of a panel that scrolls.
    static var fadeHeight: CGFloat { 28 }
    static func reach(_ scale: CGFloat) -> CGFloat { (CardTitleButton.hitHeight - CardTitleButton.rowHeight(scale)) / 2 }

    var body: some View {
        if !scrolls {
            content.frame(width: size.width, height: size.height, alignment: .topLeading)
        } else {
            let reach = Self.reach(scale), height = size.height + reach
            ScrollView(.vertical, showsIndicators: true) {
                content
                    .padding(.top, reach)
                    .padding(.bottom, Self.fadeHeight)
            }
            .mask(LinearGradient(stops: [.init(color: .black, location: 1 - Self.fadeHeight / height),
                                         .init(color: .clear, location: 1)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size.width, height: height)
            // The scroll view is an accessibility container: its content's priorities sort only inside it, so it takes the
            // left panel's place in the screen's reading order (#101: else the one-time card and 行程 read after 設定).
            .accessibilitySortPriority(DriveScreen.readingOrder.left)
            .offset(y: -reach)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }
}

/// The parked left panel (#79): the one-time card when it shows, pinned above the chosen card and in no
/// card (L84-5), then the chosen card, 行程 or 車況, with its title button, at the canvas's `scale` (#101). When the
/// one-time card's 「知道了」 would not clear the fade at the panel's top (667 in English before #101), the panel starts
/// higher (`DriveLayout.parkedHintTop`, the master's `leftTop`), so the note is read whole without scrolling (R7-16).
struct LeftCardView: View {
    let state: HUDState
    let title: CardTitle
    /// The panel's frame for `showsHint`, from `frame(_:showsHint:locale:hintTop:scale:)`.
    let size: CGSize
    let showsHint: Bool
    var scale: CGFloat = 1
    @Environment(\.locale) private var locale

    /// The left panel's frame: `panel`, or from `hintTop` when the one-time card needs it.
    static func frame(_ panel: CGRect, showsHint: Bool, locale: Locale, hintTop: CGFloat, scale: CGFloat) -> CGRect {
        guard showsHint,
              HintCard.buttonBottom(width: panel.width, locale: locale, scale: scale) > panel.height - CardScroll<EmptyView>.fadeHeight
        else { return panel }
        return CGRect(x: panel.minX, y: hintTop, width: panel.width, height: panel.maxY - hintTop)
    }

    /// Whether the panel scrolls in `size`.
    static func scrolls(_ state: HUDState, deck: CardDeck, showsHint: Bool, locale: Locale, size: CGSize, scale: CGFloat) -> Bool {
        let card: CGFloat = switch deck.current {
        case .vehicle?:
            VehicleCardView.height(VehicleCopy(vehicle: state.vehicle, unit: state.unit, locale: locale), width: size.width, scale: scale)
        default:
            TripCardView.height(state.trip.map { TripCopy(trip: $0, unit: state.unit, locale: locale) }, width: size.width, scale: scale)
        }
        return card + (showsHint ? HintCard.height(width: size.width, locale: locale, scale: scale) + HintCard.gap * scale : 0) > size.height
    }

    var body: some View {
        let scrolls = Self.scrolls(state, deck: title.deck, showsHint: showsHint, locale: locale, size: size, scale: scale)
        CardScroll(size: size, scrolls: scrolls, scale: scale) {
            VStack(alignment: .leading, spacing: 0) {
                if showsHint {
                    HintCard(act: title.act, scale: scale)
                        .accessibilitySortPriority(DriveScreen.readingOrder.hint)
                        .frame(width: size.width)
                        .padding(.bottom, HintCard.gap * scale)
                }
                switch title.deck.current {
                case .vehicle?:
                    VehicleCardView(vehicle: state.vehicle, unit: state.unit, width: size.width, title: title, scale: scale, swipesOnTitle: scrolls)
                default:
                    TripCardView(trip: state.trip, unit: state.unit, width: size.width, title: title, scale: scale, swipesOnTitle: scrolls)
                }
            }
        }
        .cardSwipe(title, on: .panel, scrolls: scrolls)
    }
}

/// The one-time card (L84-5, the master's `NOTICE2`): the tire note first, then how to switch cards, and
/// one 「知道了」 (16/600) that dismisses both for good. 14/500 `text.secondary` on 20 lines, on `card` with a 1 px
/// `card.border`, radius 12. All at the canvas's `scale` (#101), except the button's hit area: 44 high at every size.
struct HintCard: View {
    let act: @MainActor (CardAction) -> Void
    var scale: CGFloat = 1

    /// Below the card, above the chosen card's title.
    static let gap: CGFloat = 12
    static func font(_ scale: CGFloat) -> UIFont {
        UIFont(name: HUDFont.interMedium, size: 14 * scale) ?? .systemFont(ofSize: 14 * scale, weight: .medium)
    }
    static let lineHeight: CGFloat = 20
    static let buttonHeight: CGFloat = 44
    static let tireNote: LocalizedStringResource = "Tire pressure is for reference only. Rely on your car's tire pressure warnings."
    static let switchNote: LocalizedStringResource = "Tap a title or swipe to switch cards."

    /// The text's height at the card's inner width: 20 a line.
    static func textHeight(_ text: LocalizedStringResource, width: CGFloat, locale: Locale, scale: CGFloat) -> CGFloat {
        var resource = text
        resource.locale = locale
        let font = font(scale)
        let box = (String(localized: resource) as NSString).boundingRect(
            with: CGSize(width: width - 2 - 24 * scale, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin,
            attributes: [.font: font], context: nil)
        return lineHeight * scale * max(1, (box.height / font.lineHeight).rounded())
    }

    /// From the card's top to the bottom of 「知道了」.
    static func buttonBottom(width: CGFloat, locale: Locale, scale: CGFloat) -> CGFloat {
        1 + 10 * scale + textHeight(tireNote, width: width, locale: locale, scale: scale) + 6 * scale
            + textHeight(switchNote, width: width, locale: locale, scale: scale) + 10 * scale + buttonHeight
    }

    static func height(width: CGFloat, locale: Locale, scale: CGFloat) -> CGFloat {
        buttonBottom(width: width, locale: locale, scale: scale) + 12 * scale + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6 * scale) {
                note(Self.tireNote)
                note(Self.switchNote)
            }
            .accessibilityElement(children: .combine)
            Button { act(.dismissHint) } label: {
                Text("Got it")
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: Self.buttonHeight)
                    .overlay(RoundedRectangle(cornerRadius: 10 * scale).strokeBorder(Palette.cardBorder))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10 * scale)
        }
        .padding(.top, 10 * scale)
        .padding(.horizontal, 12 * scale)
        .padding(.bottom, 12 * scale)
        .padding(1)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 12 * scale))
        .overlay(RoundedRectangle(cornerRadius: 12 * scale).strokeBorder(Palette.cardBorder))
    }

    private func note(_ text: LocalizedStringResource) -> some View {
        let font = Self.font(scale)
        return Text(text)
            .font(Font(font))
            .lineSpacing(Self.lineHeight * scale - font.lineHeight)
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// The parked right panel (#79, 07 §3.1, #101): the chosen card's title button on the tire column's title (x 598.5,
/// on the titles' line), and its body in the drive frame's band with no face: 胎壓 is the drive screen's tire column
/// without its own title, plus the time line under the car; 車上導航 is `navX`'s lines with no road art. With no
/// card offered (no car data, 07 §2.3 「只有 GPS」), the one line 「尚無車輛資料」. Everything is drawn on the canvas.
struct RightCardView: View {
    let state: HUDState
    let title: CardTitle
    let layout: DriveLayout
    @Environment(\.locale) private var locale

    var body: some View {
        let canvas = layout.canvas, panel = layout.tirePanel, scale = canvas.scale
        // The text column, inside the panel.
        let x = canvas.point(DriveFrame.parkedRightTextX, 0).x
        ZStack(alignment: .topLeading) {
            // The swipe works anywhere on the panel (nothing on it scrolls).
            Color.clear
                .frame(width: panel.width, height: panel.height)
                .cardSwipe(title, on: .panel, scrolls: false)
                .offset(x: panel.minX, y: panel.minY)
            if let card = title.deck.current {
                CardTitleButton(card: card, title: title, width: panel.maxX - x, scale: scale)
                    .offset(x: x, y: panel.minY)
                    .accessibilitySortPriority(DriveScreen.readingOrder.rightTitle)
            }
            Group {
                switch title.deck.current {
                case .tires?:
                    switch state.tires {
                    case .wheels(let wheels)?:
                        TireColumnView(wheels: wheels, canvas: canvas, showsTitle: false,
                                       timeLine: TireCopy(panel: .wheels(wheels), locale: locale).summary)
                    case .notSupported?:
                        CardLine(text: "This car doesn't provide tire pressure", scale: scale)
                            .frame(width: panel.maxX - x, alignment: .leading)
                            .offset(x: x, y: panel.minY + CardTitleButton.rowHeight(scale) + CardLine.topGap * scale)
                    case nil:
                        EmptyView()
                    }
                case .navigation?:
                    switch state.navigation {
                    case .ended?:
                        // 07 §2.3: a route known to have ended.
                        CardLine(text: "No route set in the car", scale: scale)
                            .frame(width: panel.maxX - x, alignment: .leading)
                            .offset(x: x, y: panel.minY + CardTitleButton.rowHeight(scale) + CardLine.topGap * scale)
                    case let navigation?:
                        NavigationCardBody(panel: navigation, unit: state.unit, canvas: canvas)
                    case nil:
                        EmptyView()
                    }
                default:
                    CardLine(text: "No vehicle data yet", scale: scale)
                        .frame(width: panel.maxX - x, alignment: .leading)
                        .offset(x: x, y: panel.minY)
                }
            }
            .accessibilitySortPriority(DriveScreen.readingOrder.right)
        }
    }
}

/// One line in place of a card's content (the master's `.tu`): 14 `text.secondary`, 18 below the title row, at the
/// canvas's `scale`.
struct CardLine: View {
    let text: LocalizedStringKey
    var scale: CGFloat = 1

    static let topGap: CGFloat = 18
    static func font(_ scale: CGFloat) -> UIFont { .systemFont(ofSize: 14 * scale) }

    var body: some View {
        Text(text)
            .font(.system(size: 14 * scale))
            .foregroundStyle(Palette.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
