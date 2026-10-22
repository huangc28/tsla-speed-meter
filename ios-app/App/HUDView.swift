import HUDCore
import SwiftUI

/// Root view: runs the GPS source and shows the drive screen. GPS never switches to parked (#23).
struct HUDView: View {
    @State private var model = HUDViewModel()
    @State private var location = LocationSpeedSource()
    @Environment(\.scenePhase) private var scenePhase
    /// Set in the system Settings app (`Settings.bundle`); km/h by default.
    @AppStorage("speedUnit") private var unitSetting = SpeedUnit.kilometersPerHour.rawValue

    var body: some View {
        // The reader keeps the safe area so it can report the insets; the screen itself spans the display.
        GeometryReader { proxy in
            let insets = proxy.safeAreaInsets
            let screen = CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                                height: proxy.size.height + insets.top + insets.bottom)
            DriveScreen(state: model.state, screen: screen,
                        leftInset: insets.leading, rightInset: insets.trailing, bottomInset: insets.bottom)
                .offset(x: -insets.leading, y: -insets.top)
        }
        .background(Palette.background)
        .preferredColorScheme(.dark)
        .task { await model.run(location.events()) }
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

#Preview(traits: .landscapeLeft) {
    HUDView()
}
