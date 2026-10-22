import SwiftUI

@main
struct SpeedHUDApp: App {
    @Environment(\.scenePhase) private var scenePhase
    /// Created at launch so CoreBluetooth state restoration can reach it.
    @State private var driveLogger = DriveLogger.live()

    var body: some Scene {
        WindowGroup {
            HUDView()
                .overlay(alignment: .topTrailing) { DriveLoggerEntryButton(logger: driveLogger) }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            ScreenAwake.apply(for: phase)
        }
    }
}
