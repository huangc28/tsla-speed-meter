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

## VoiceOver order for views placed with `.offset`

SwiftUI can't sort views placed with `.offset` by where they appear. Set `accessibilitySortPriority` on the leaf views, or on a container marked `.accessibilityElement(children: .contain)`.
- A plain wrapper with a priority merges its children into one element as big as the panel, or reads as an empty element.
- A `ScrollView` is its own accessibility container. Give it the priority itself, or its content is read last.

- **Evidence:** #100: a wrapper's priority made an empty element, fixed in PR #105. #101: while the one-time hint scrolled, VoiceOver read the left panel after the settings gear, and 「尚無車輛資料」 took the whole panel as its frame. Both #101 cases were fixed in PR #106.
- **Validated:** 2026-11-19, `ParkedCardsTests.theOneTimeCardReadsBeforeTheGauge`, `theNavigationBodyIsOnlyWhatItDraws` and `DriveFrameTests.theScreenReadsInOrder`.
- **Decays when:** the screens stop placing views with `.offset`, or SwiftUI starts sorting elements by frame.

## Accessibility frames are floats: compare 44-point hit areas with a tolerance

On the scaled canvas a hit area 44 high can sit at a fractional y. Its accessibility frame then reads back as 43.99999. Snap interactive frames to whole points, or compare with a tolerance of 1e-3. A strict `< 1` that only passes by chance doesn't count.

- **Evidence:** #101: the card-list rows, the title frames at 956, and the right title's offset of 0.9995 at 667 (PR #106).
- **Validated:** 2026-11-19, `CardSwitchingTests.theTitleOpensTheListAndChoosingClosesIt` and `ParkedCardsTests.theTitlesHitAreasDoNotScale`.
- **Decays when:** hit areas move off the scaled canvas.

## CoreGraphics dashes differ from Chrome's: port the dash builder, not its numbers

The design page's dash lengths and phases come out differently in CoreGraphics. With the design's gap of 35, the app showed 1 px gaps. Changing only the gap and keeping the design's lengths leaves a stub at the start.
- The app ports the page's `tDash` with the gap as a parameter (45 units) and whole periods, so the outlines close.
- A test reads the drawn dashes back to check that each one is whole.

- **Evidence:** #99, PR #104.
- **Validated:** 2026-11-19, `CarStatusIconTests.drawnDashesAreWhole`, and the check for gaps of at least 2 px at 1× 844.
- **Decays when:** the unknown-state dashes are redesigned or removed.
