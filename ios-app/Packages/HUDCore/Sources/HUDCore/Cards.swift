import Foundation

/// A side panel of the main screen (07 §3.1).
public enum PanelSide: Equatable, Sendable {
    case left, right
}

/// What a side panel can show while parked (07 §2.3, §3.1, L84-7): 行程 and 車況 on the left, 胎壓 and
/// 車上導航 on the right (正在播放 is #83). The order is the list's and the swipe's.
public enum PanelCard: String, CaseIterable, Equatable, Sendable {
    case trip, vehicle, tires, navigation

    public var side: PanelSide { self == .trip || self == .vehicle ? .left : .right }
    /// 車況 and 胎壓 never show while driving (07 §2.3, L34).
    public var showsWhileDriving: Bool { self == .trip || self == .navigation }
    /// Every card but 行程 needs car data, so none of them is offered on GPS only (07 §2.3 「只有 GPS」).
    public var needsCarData: Bool { self != .trip }

    /// The parked default of each side: 行程 and 胎壓.
    public static func defaultCard(_ side: PanelSide) -> PanelCard { side == .left ? .trip : .tires }

    /// The cards offered on `side`, in order; with no car data, only those that need none.
    public static func offered(on side: PanelSide, carData: Bool) -> [PanelCard] {
        allCases.filter { $0.side == side && (carData || !$0.needsCarData) }
    }
}

/// One side's cards while parked: those offered, in order, and the one showing.
public struct CardDeck: Equatable, Sendable {
    public var cards: [PanelCard]
    /// Nil only when no card is offered: the right panel with no car data shows 「尚無車輛資料」.
    public var current: PanelCard?

    public init(cards: [PanelCard], current: PanelCard?) {
        self.cards = cards
        self.current = current
    }

    /// 1-based, for 「第 1 張，共 2 張」 and the dots.
    public var position: Int? { current.flatMap { cards.firstIndex(of: $0) }.map { $0 + 1 } }
}

/// The parked screen's panels (#79): each side's cards, the list open over a panel, and the one-time
/// card above the left one.
public struct ParkedPanels: Equatable, Sendable {
    public var left: CardDeck
    public var right: CardDeck
    /// The side whose card list is open over its panel; nil when none is.
    public var openList: PanelSide?
    /// The one-time card (L84-5): the tire note and how to switch cards, with one 「知道了」.
    public var showsHint: Bool

    public init(left: CardDeck, right: CardDeck, openList: PanelSide?, showsHint: Bool) {
        self.left = left
        self.right = right
        self.openList = openList
        self.showsHint = showsHint
    }

    public func deck(_ side: PanelSide) -> CardDeck { side == .left ? left : right }
}

/// What the person does with the parked cards (M12-14): the title button and its list, a vertical
/// swipe, VoiceOver's actions, and 「知道了」.
public enum CardAction: Equatable, Sendable {
    /// The title button: opens that side's list, or closes it when it is open.
    case toggleList(PanelSide)
    case closeList
    /// A row of the list: shows that card and closes the list.
    case choose(PanelCard)
    /// A vertical swipe started on that side's panel.
    case beginSwipe(PanelSide)
    /// The swipe ended: one card on (`forward`) or back. Counts only if it began in this parked stretch.
    case endSwipe(PanelSide, forward: Bool)
    /// VoiceOver's 「下一張」 / 「上一張」.
    case step(PanelSide, forward: Bool)
    /// 「知道了」 on the one-time card.
    case dismissHint
}

/// The cards the person chose and what is under way (M12-03, M12-04, M12-14). `HUDEngine` owns it:
/// actions count only while parked, and leaving parked cancels an open list or a swipe at once; neither
/// comes back on the next parked screen. Switching stops at the first and last card.
public struct CardSwitcher: Equatable, Sendable {
    /// The chosen card of each side, kept for the next parked screen (the app stores them).
    public private(set) var left: PanelCard
    public private(set) var right: PanelCard
    /// 「知道了」 was tapped: the one-time card never shows again (the app stores it).
    public private(set) var hintDismissed: Bool
    private var openList: PanelSide?
    private var swiping: Set<PanelSide> = []

    /// A card stored for the wrong side falls back to that side's default.
    public init(left: PanelCard = .defaultCard(.left), right: PanelCard = .defaultCard(.right), hintDismissed: Bool = false) {
        self.left = left.side == .left ? left : .defaultCard(.left)
        self.right = right.side == .right ? right : .defaultCard(.right)
        self.hintDismissed = hintDismissed
    }

    /// `side`'s cards: the chosen one shows if it is offered, otherwise the first offered.
    func deck(_ side: PanelSide, carData: Bool) -> CardDeck {
        let cards = PanelCard.offered(on: side, carData: carData)
        let chosen = side == .left ? left : right
        return CardDeck(cards: cards, current: cards.contains(chosen) ? chosen : cards.first)
    }

    func panels(carData: Bool) -> ParkedPanels {
        ParkedPanels(left: deck(.left, carData: carData), right: deck(.right, carData: carData),
                     openList: openList, showsHint: !hintDismissed)
    }

    /// An action while parked; `carData` says which cards are offered.
    mutating func handle(_ action: CardAction, carData: Bool) {
        switch action {
        case .toggleList(let side):
            openList = openList == side ? nil : side
        case .closeList:
            openList = nil
        case .choose(let card):
            guard PanelCard.offered(on: card.side, carData: carData).contains(card) else { return }
            show(card)
            openList = nil
        case .beginSwipe(let side):
            swiping.insert(side)
        case .endSwipe(let side, let forward):
            guard swiping.remove(side) != nil else { return }
            step(side, forward: forward, carData: carData)
        case .step(let side, let forward):
            step(side, forward: forward, carData: carData)
        case .dismissHint:
            hintDismissed = true
        }
    }

    /// The layout is not parked: an open list and a swipe under way end, never to resume.
    mutating func leaveParked() {
        openList = nil
        swiping = []
    }

    private mutating func step(_ side: PanelSide, forward: Bool, carData: Bool) {
        let deck = deck(side, carData: carData)
        guard let position = deck.position else { return }
        let next = position - 1 + (forward ? 1 : -1)
        guard deck.cards.indices.contains(next) else { return }
        show(deck.cards[next])
    }

    private mutating func show(_ card: PanelCard) {
        if card.side == .left { left = card } else { right = card }
    }
}
