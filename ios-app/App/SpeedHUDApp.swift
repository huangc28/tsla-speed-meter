import SwiftUI

@main
struct SpeedHUDApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HUDView()
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            ScreenAwake.apply(for: phase)
        }
    }
}
