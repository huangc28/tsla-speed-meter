# Speed HUD (iOS)

Native Swift rewrite, iPhone first (`docs/design/00-rulings.md` L59). The Flutter app at the repo root stays as reference.

- `project.yml`: XcodeGen spec. The `.xcodeproj` is generated and not committed.
- `App/`: SwiftUI app target `SpeedHUD` (bundle id `com.tslaspeedmeter.hud`).
- `AppTests/`: unit tests hosted in the app.
- `Packages/HUDCore/`: local SwiftPM package, pure Swift logic (no UIKit, SwiftUI or CoreBluetooth).
- `App/Fonts/`: Barlow Semi Condensed Regular and Medium from Google Fonts, SIL Open Font License 1.1 (`App/Fonts/OFL.txt`, shipped in the app bundle). Used only for the speed numeral and unit.
- `App/Settings.bundle`: the speed unit (km/h by default, or mph), set in the system Settings app.

All commands below run from this `ios-app/` directory.

## Generate

```sh
xcodegen generate
```

Run it again after changing `project.yml` or adding/removing files.

Pin every remote package in `project.yml` with `exactVersion`: the generated `.xcodeproj` and its `Package.resolved` are git-ignored, so `project.yml` is the only lock.

## Test

```sh
# HUDCore on the Mac
swift test --package-path Packages/HUDCore

# Everything (app tests + HUDCore tests) on a simulator
# (pick one from `xcrun simctl list devices available`)
xcodebuild test -project SpeedHUD.xcodeproj -scheme SpeedHUD \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData
```

The app tests also render the main drive-screen states to `Snapshots/*.png` (git-ignored) for visual review against `docs/design/frames/landscape/`.

## Install on a device

```sh
DEVICE=<device id from `xcrun devicectl list devices`>

xcodebuild build -project SpeedHUD.xcodeproj -scheme SpeedHUD -configuration Debug \
  -destination "id=$DEVICE" -allowProvisioningUpdates -derivedDataPath DerivedData

xcrun devicectl device install app --device "$DEVICE" \
  DerivedData/Build/Products/Debug-iphoneos/SpeedHUD.app

xcrun devicectl device process launch --device "$DEVICE" com.tslaspeedmeter.hud
```

Signing is automatic with team `XSFD8WRKQL`; the Xcode account for that team must be signed in. Keep the phone unlocked during install and launch.
