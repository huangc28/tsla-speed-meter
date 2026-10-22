import SwiftUI
import UIKit

/// Keeps the screen on while the app is in the foreground and active.
enum ScreenAwake {
    static func shouldKeepAwake(in phase: ScenePhase) -> Bool {
        phase == .active
    }

    @MainActor
    static func apply(for phase: ScenePhase) {
        UIApplication.shared.isIdleTimerDisabled = shouldKeepAwake(in: phase)
    }
}
