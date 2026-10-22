import SwiftUI
import Testing
import UIKit
@testable import SpeedHUD

struct ScreenAwakeTests {
    @Test func keepsScreenAwakeUnlessInBackground() {
        #expect(ScreenAwake.shouldKeepAwake(in: .active))
        #expect(ScreenAwake.shouldKeepAwake(in: .inactive))
        #expect(!ScreenAwake.shouldKeepAwake(in: .background))
    }

    @Test @MainActor func applyTogglesIdleTimer() {
        ScreenAwake.apply(for: .active)
        #expect(UIApplication.shared.isIdleTimerDisabled)
        ScreenAwake.apply(for: .background)
        #expect(!UIApplication.shared.isIdleTimerDisabled)
    }
}
