# Reference-image render tests (iOS app)

## Screens with UIKit-backed views render in a window

`ImageRenderer` draws UIKit-backed SwiftUI views, such as `TextField` and `ScrollView`, as placeholders. Screens that contain them can't be captured with `ImageRenderer`. Instead, host the view in a window and capture it with `drawHierarchy`, using `preferredRange = .standard`.

To keep two renders pixel-identical:
- give the view a switch that turns off field focus, so no caret is drawn;
- stop spinners with `.transaction { $0.animation = nil }`.

- **Evidence:** `ios-app/AppTests/PairingRenderTests.swift` (#55, PR #64). `rendersAreRepeatable` shows two renders differ by 0 pixels.
- **Validated:** 2026-10-25, on the iPhone 17 Pro simulator with iOS 26.5.
- **Decays when:** Apple adds platform-view support to `ImageRenderer`, or the render tests move to another snapshot tool.

## Two test runs must not share a simulator

Two `xcodebuild test` runs on the same simulator reinstall the app under each other. The test host then crashes with SIGILL or SIGBUS, and the app's container path changes between crash reports. Give each parallel run its own simulator of the same device type and runtime, so reference renders still match.

- **Evidence:** the crash reports from 2026-10-25 15:37–15:41, during #55's review.
- **Decays when:** the tests stop installing a host app, or Xcode isolates parallel runs on its own.
