import SwiftUI
import TeslaBLE

@main
struct SpeedHUDApp: App {
    @Environment(\.scenePhase) private var scenePhase
    /// The one car connection, created at launch so CoreBluetooth state
    /// restoration can reach it.
    private let carFeed: CarFeed
    @State private var driveLogger: DriveLogger

    init() {
        let feed = CarFeed.live()
        carFeed = feed
        _driveLogger = State(initialValue: DriveLogger(feed: feed))
    }

    var body: some Scene {
        WindowGroup {
            HUDView(carFeed: carFeed)
                .overlay(alignment: .topTrailing) { DriveLoggerEntryButton(logger: driveLogger) }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            ScreenAwake.apply(for: phase)
            // L60: talk to the car only while the app is in front.
            switch phase {
            case .background: Task { await carFeed.suspend() }
            case .active: Task { await carFeed.resume() }
            default: break
            }
        }
    }
}
