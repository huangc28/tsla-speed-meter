import HUDCore
import SwiftUI
import TeslaBLE

/// Root view: runs the GPS source and listens to the car feed, and shows the drive screen.
/// GPS never switches to parked (#23).
struct HUDView: View {
    /// The app's one car feed; listened to only while the app is in front (L60).
    let carFeed: CarFeed?
    @State private var model = HUDViewModel()
    @State private var location = LocationSpeedSource()
    @Environment(\.scenePhase) private var scenePhase
    /// Set in the system Settings app (`Settings.bundle`); km/h by default.
    @AppStorage("speedUnit") private var unitSetting = SpeedUnit.kilometersPerHour.rawValue
    /// Whether the Keychain holds a paired car; nil until read.
    @State private var paired: Bool?
    /// L66: 之後再說 hides the invitation for good; the gear keeps its setup dot.
    @AppStorage("pairing.inviteDismissed") private var inviteDismissed = false
    /// The pairing flow while it is open (S13–S17).
    @State private var pairing: PairingFlow?

    var body: some View {
        // The reader keeps the safe area so it can report the insets; the screen itself spans the display.
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let screen = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                height: proxy.size.height + insets.top + insets.bottom)
            DriveScreen(state: model.state, screen: screen,
                        leftInset: insets.leading, rightInset: insets.trailing, bottomInset: insets.bottom,
                        setupPending: paired == false, showsInvite: paired == false && !inviteDismissed,
                        actions: DriveScreenActions(openSettings: startPairing, connect: startPairing,
                                                    dismissInvite: { inviteDismissed = true }))
                .offset(x: -insets.leading, y: -insets.top)
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .task { await model.run(location.events()) }
        .task(id: scenePhase == .active) { await refreshPaired() }
        // Until settings (S08 / S19) exist, the gear opens pairing directly; with a car
        // already paired, pairing again replaces it only after S17 (L65).
        .fullScreenCover(item: $pairing, onDismiss: { Task { await refreshPaired() } }) { flow in
            PairingFlowView(flow: flow)
        }
        .task(id: scenePhase == .background) {
            guard scenePhase != .background, let carFeed else { return }
            await model.run(car: carFeed.carEvents())
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background: model.suspend()
            case .active: model.resume()
            default: break
            }
        }
        .onChange(of: unitSetting, initial: true) {
            model.unit = SpeedUnit(rawValue: unitSetting) ?? .kilometersPerHour
        }
    }
}

extension HUDView {
    private func startPairing() {
        guard let carFeed else { return }
        pairing = PairingFlow(feed: carFeed)
    }

    private func refreshPaired() async {
        guard let carFeed else { return }
        paired = await carFeed.pairedVIN != nil
    }
}

#Preview(traits: .landscapeLeft) {
    HUDView(carFeed: nil)
}
