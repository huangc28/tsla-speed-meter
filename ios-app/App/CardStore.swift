import Foundation
import HUDCore

/// The parked cards the person chose and the one-time card's 知道了 (#79), kept in UserDefaults so the
/// next parked screen, also after a relaunch, shows them.
struct CardStore {
    static let leftKey = "cards.left"
    static let rightKey = "cards.right"
    static let hintDismissedKey = "cards.hintDismissed"

    let defaults: UserDefaults

    /// The stored choice; the defaults (行程, 胎壓) for anything missing or unknown.
    func load() -> CardSwitcher {
        let left = defaults.string(forKey: Self.leftKey).flatMap(PanelCard.init(rawValue:)) ?? .defaultCard(.left)
        let right = defaults.string(forKey: Self.rightKey).flatMap(PanelCard.init(rawValue:)) ?? .defaultCard(.right)
        return CardSwitcher(left: left, right: right, hintDismissed: defaults.bool(forKey: Self.hintDismissedKey))
    }

    func save(_ cards: CardSwitcher) {
        defaults.set(cards.left.rawValue, forKey: Self.leftKey)
        defaults.set(cards.right.rawValue, forKey: Self.rightKey)
        defaults.set(cards.hintDismissed, forKey: Self.hintDismissedKey)
    }
}
