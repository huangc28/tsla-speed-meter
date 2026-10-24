import SwiftUI
import TeslaBLE

@main
struct SpeedHUDApp: App {
    @Environment(\.scenePhase) private var scenePhase
    /// The one car connection, created at launch so CoreBluetooth state
    /// restoration can reach it.
    private let carFeed: CarFeed
    private let carFeedPhase: CarFeedPhase
    @State private var driveLogger: DriveLogger

    init() {
        let feed = CarFeed.live()
        carFeed = feed
        carFeedPhase = CarFeedPhase(feed: feed)
        _driveLogger = State(initialValue: DriveLogger(feed: feed))
    }

    var body: some Scene {
        WindowGroup {
            HUDView(carFeed: carFeed)
                .overlay(alignment: .topTrailing) { DriveLoggerEntryButton(logger: driveLogger) }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            ScreenAwake.apply(for: phase)
            carFeedPhase.apply(phase)
        }
    }
}

/// L60: the car feed talks to the car only while the app is in front. Phase changes reach
/// it one at a time and in order, so a quick trip to the background never leaves it suspended.
@MainActor
final class CarFeedPhase {
    private let feed: CarFeed
    private var last: Task<Void, Never>?

    init(feed: CarFeed) {
        self.feed = feed
    }

    func apply(_ phase: ScenePhase) {
        let previous = last
        let feed = feed
        switch phase {
        case .background:
            last = Task {
                await previous?.value
                await feed.suspend()
            }
        case .active:
            last = Task {
                await previous?.value
                await feed.resume()
            }
        default:
            break
        }
    }
}
