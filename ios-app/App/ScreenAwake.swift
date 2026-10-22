import SwiftUI
import UIKit

/// Keeps the screen on whenever the app is in the foreground, including while
/// a system prompt (e.g. a permission dialog) makes the scene `.inactive`.
enum ScreenAwake {
    static func shouldKeepAwake(in phase: ScenePhase) -> Bool {
        phase != .background
    }

    @MainActor
    static func apply(for phase: ScenePhase) {
        UIApplication.shared.isIdleTimerDisabled = shouldKeepAwake(in: phase)
    }
}
