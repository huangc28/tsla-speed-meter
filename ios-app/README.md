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
# HUDCore and TeslaBLE on the Mac
swift test --package-path Packages/HUDCore
swift test --package-path Packages/TeslaBLE

# Everything (app tests + HUDCore tests + TeslaBLE tests) on a simulator
# (pick one from `xcrun simctl list devices available`; use `id=` when two share a name)
xcodebuild test -project SpeedHUD.xcodeproj -scheme SpeedHUD \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData
```

The app tests also render the main drive-screen states to `Snapshots/*.png` (git-ignored) for visual review against `docs/design/frames/landscape/`.

`HUDRenderTests` compares the main states against `AppTests/References/*.png` (1x, small per-pixel tolerance). After an intended visual change, re-record, look at the new PNGs, and commit them:

```sh
TEST_RUNNER_RECORD_REFERENCES=1 xcodebuild test -project SpeedHUD.xcodeproj -scheme SpeedHUD \
  -destination 'platform=iOS Simulator,id=<simulator id>' -derivedDataPath DerivedData \
  -only-testing:SpeedHUDTests/HUDRenderTests
```

On a failure the render is saved as `Snapshots/<name>-actual.png`.

## GPS speed on the simulator

The simulator reports `speedAccuracy` −1 for simulated locations and routes, and the app follows Apple's rule that a negative `speedAccuracy` means the speed is invalid. So a simulated drive shows "—", not a speed. Check live GPS speed on a real iPhone (still pending: the test phone was unreachable when the GPS HUD landed).

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

## Drive logger (test build, #30)

The main screen has a small 行車紀錄 button that opens 行車紀錄(測試): enter the VIN, 連線, 加入鑰匙 (once), 讀一次, 開始紀錄 / 停止紀錄, 匯出. The page does not poll the car itself. The app's one car feed (`CarFeed` in TeslaBLE, created at launch) owns the connection, and every button goes through it. The feed polls while the link is up and someone listens; here that is the page while recording, which logs phone GPS speed on the same timeline. One request is in flight at a time, one category per request, as vehicle-command's `GetState` does (replies to one request for all three claimed RESPONSE_MTU_EXCEEDED, #39). Drive state is asked as soon as the previous reply arrives, but never sooner than 200 ms after the previous drive request, so about 5 a second (L61). Charge state and tire pressure are each asked once every 10 s, right after a drive reply and followed by the next drive request, so two of them are never sent back to back. Each drive request makes one row; a charge or tire pressure request goes on the row of the drive request after it, which is that row's last request, so its phone time and GPS fix are taken right after the drive reply. If charge state or tire pressure fails because the link is down or the car does not answer the handshake (`notConnected`, `disconnected`, a link error, `timeout(sessionInfo)`), that row's drive request is skipped; a fault or a failed reply does not skip it. While the link is down the feed sends nothing and no rows are written. 讀一次 asks for all three and lists which came back, or which were skipped. 讀一次 and 加入鑰匙 pause the feed's polling (the request in flight is cancelled) and it resumes afterwards. If the link drops while recording, it reconnects with the saved VIN on its own (自動重新連線中; `auto_reconnect` events). An attempt can take about 35 s when the car is out of reach (30 s scan, then a 5 s pause). If CoreBluetooth's own reconnect has not finished after 15 s, it is cancelled and the app's reconnect takes over (`system_reconnect_stalled`).

Two kinds of log folder, each with the same files:

- Diagnostics, `Documents/Diagnostics/<time>/`: starts at the first 連線 (or 加入鑰匙 / 讀一次 / 開始紀錄) after the app launches and covers everything until the app quits, so a failed connect or enrollment is kept. 讀一次 rows go here too. Past about 50 MB a new folder continues it (`diagnostics_rotated`, `continues`); only the newest 10 diagnostics folders are kept.
- Recordings, `Documents/Logs/<start time>/`: one per 開始紀錄 … 停止紀錄.

Files:

- `samples.csv`: one row per drive request (and per 讀一次 in diagnostics). An empty value cell means the car did not send it, or the category was not asked for: the battery and charging columns are filled on about one row in 50, and the tire columns on another one in 50. `drive_*`, `charge_*` and `tire_pressure_*` give each category's own `response_ms` (from the completed write to the reply) and `error`; both are empty when the category was not asked for on that row, and `error` is `skipped` when an earlier category's link or handshake failure skipped it. `response_ms` and `send_wait_ms` add up the categories that came back, and `error` is the first error of the row. 停止紀錄, 讀一次 and 加入鑰匙 cancel the feed's request in flight: a cancelled category is left out of the row, and a row whose drive request was cancelled (with no other failure) is not written. A reply whose tag fails but claims a fault logs it as `invalidResponseTag(reportedFault: …)` and an `unverified_fault` event (「車子回報:回應太大(未驗證)」); the app never acts on it.
- `gps.csv`: every phone GPS fix (speed and accuracy only, no coordinates). Recordings only.
- `events.jsonl`: every connect, disconnect, handshake, request, response, fault, timeout, enrollment step and app state change. The BLE local name (derived from the VIN) is not written.
- `frames.txt`: every whole BLE message, hex, both directions. A reply that came back unencrypted is written only as its byte count, because its payload can hold private data such as the navigation destination.
- `meta.json`: app build, iOS version, phone model, masked VIN, settings, counts. `settings` give the cadence (`drive_request_min_interval_ms`, `charge_interval_ms`, `tire_pressure_interval_ms`, …). `error_count` counts rows where drive state did not come back (failed or skipped); `category_error_count` counts rows where drive state came back but charge state or tire pressure did not. The page shows the first as 「錯誤 N 筆」 and the second, when not zero, as 「另有 N 筆只有充電或胎壓沒讀到」.

匯出 shares one zip with this run's diagnostics folders and the latest recording; it works before any recording exists.

In the background: GPS is when-in-use and there is no background location mode, so locking the phone or switching apps stops GPS. Polling the car may go on over Bluetooth (`bluetooth-central`) for a while, or may stop; the data shows which: `app_phase` events mark the switch, and `gps_fix_age_ms` grows while GPS is stopped. The screen stays on while the app is open, so the owner is asked not to lock the phone.

開車路線(車主照著做一次就能回答所有問題):

1. 停在 P 檔,人坐在車上、腳踩煞車,讓車子保持醒著。(車子在睡覺的話,先開一下車門或踩煞車。)
2. 按「讀一次」,確認有讀到資料。
3. 按「開始紀錄」,把手機放上手機架,之後就不要再碰手機。
4. 打 R 檔,倒車幾公尺後停下。
5. 打 D 檔,慢慢滑行 1–2 分鐘。
6. 正常開 10 分鐘。
7. 可以的話,開過隧道或進地下停車場。
8. 停好打 P 檔,等 2 分鐘。
9. 停好車後才拿手機,按「停止紀錄」。
10. 按「匯出」,把檔案傳給我們。

Screenshots: launch a Debug build with `-DriveLoggerOpen YES` (opens the page), `-DriveLoggerDemo YES` (example values) and `-DriveLoggerScrollTo key|read|record|route`.
