import Foundation
import Observation
import TeslaBLE

/// What the drive screen shows for setup: the gear's setup dot while no car is paired
/// (01 §4.1), and the first-launch invitation while no car is paired and 之後再說 was
/// never tapped (L66).
@MainActor
@Observable
final class CarSetup {
    static let inviteDismissedKey = "pairing.inviteDismissed"

    /// Whether the Keychain holds a paired car; nil until read, which shows neither.
    private(set) var paired: Bool?
    private(set) var inviteDismissed: Bool
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        inviteDismissed = defaults.bool(forKey: Self.inviteDismissedKey)
    }

    var showsSetupDot: Bool { paired == false }
    var showsInvite: Bool { paired == false && !inviteDismissed }

    /// 之後再說: the invitation never shows again; the dot stays.
    func dismissInvite() {
        inviteDismissed = true
        defaults.set(true, forKey: Self.inviteDismissedKey)
    }

    func refresh(from feed: CarFeed) async {
        paired = await feed.pairedVIN != nil
    }
}
