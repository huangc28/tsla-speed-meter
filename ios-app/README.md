# Speed HUD (iOS)

Native Swift rewrite, iPhone first (`docs/design/00-rulings.md` L59). The earlier Flutter app was removed from `main` on 2026-10-24; it is in git history up to `9e621ba`.

- `project.yml`: XcodeGen spec. The `.xcodeproj` is generated and not committed.
- `App/`: SwiftUI app target `SpeedHUD` (bundle id `com.tslaspeedmeter.hud`).
- `AppTests/`: unit tests hosted in the app.
- `Packages/HUDCore/`: local SwiftPM package, pure Swift logic (no UIKit, SwiftUI or CoreBluetooth).
- `App/Fonts/`: Barlow Semi Condensed Regular, Medium and Bold from Google Fonts, SIL Open Font License 1.1 (`App/Fonts/OFL.txt`, shipped in the app bundle), used only for the speed numeral, its unit and `P R N D`; Inter Regular, Medium, SemiBold and Bold from Google Fonts, SIL Open Font License 1.1 (`App/Fonts/Inter-OFL.txt`, shipped in the app bundle), for Latin UI text such as the drive screen's time. CJK text uses the system font.
- `App/Icons/`: icons drawn as SwiftUI shapes from Lucide's SVG data, ISC License (`App/Icons/LICENSE-lucide.txt`, shipped in the app bundle).
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

The app tests also render the main drive- and parked-screen states to `Snapshots/*.png` (git-ignored) for visual review against `docs/design/frames/main-redesign/a2/` (direction A). Every render shows the time 14:05.

`HUDRenderTests` (drive and parked screens), `TirePanelTests` (the tire list) and `PairingRenderTests` (S13–S17) compare the main states against `AppTests/References/*.png` (1x, small per-pixel tolerance). The pairing screens, and the parked screens whose trip card scrolls, render in a window (`drawHierarchy`), because `ImageRenderer` draws the VIN field and scroll views as placeholders. After an intended visual change, re-record, look at the new PNGs, and commit them:

```sh
TEST_RUNNER_RECORD_REFERENCES=1 xcodebuild test -project SpeedHUD.xcodeproj -scheme SpeedHUD \
  -destination 'platform=iOS Simulator,id=<simulator id>' -derivedDataPath DerivedData \
  -only-testing:SpeedHUDTests/HUDRenderTests -only-testing:SpeedHUDTests/TirePanelTests \
  -only-testing:SpeedHUDTests/PairingRenderTests
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

## Main screen A (#75)

The drive screen is direction A (DESIGN.md "Main screen — direction A"): a ring and a disc instead of the C fan, the numeral at one size in fixed cells (L88), and an icon-only top row. `NumeralLayout` (HUDCore) gives each digit's glyph origin and the baseline; `GaugeView` draws each digit as its own CoreText line at that origin, with the tabular glyphs. The unit, the reason and the `P R N D` row hang off the ink of "0", so they never move with the digit count. `DriveLayout` holds the `P R N D` baseline, where the gear row is drawn (#48), and the four car-status slot centers, which nothing draws yet. The source chip shows Lucide icons (the words are its VoiceOver label); a small arrow left of the unit marks GPS speed (green, or amber for GPS fallback). The time is 24-hour and updates each minute.

## Gear row (#48)

`P R N D` sits above the numeral on `DriveLayout`'s baseline, one letter per 26 px cell, the current gear in Barlow Semi Condensed Bold with a 2 px underline (`GearRow`, its own VoiceOver element 「檔位 D」). `HUDEngine` gives the gear (`HUDState.gearRow`) only while the car's speed shows (or on the parked screen, #50), and only after 2 distinct, in-order readings in a row with a known gear, also on cold start; a stale reading, a lost link, a link the feed stopped trying (idle: 斷線, a cancelled pairing), an unknown gear or a fresh P at 5 km/h or more hides the whole row, and it comes back only after 2 new readings, so a P flickering around 5 km/h never makes it blink. Showing or hiding it changes no pixel outside the row (`gearRowMovesNothingElse`).

## Battery / range (#49)

The bottom-left block (`DriveLayout.batterySlot`) shows a battery icon and `72% / 315 km` (Inter 17/500, tabular), the car's rated range converted from miles to km, or shown in miles in mph mode (`72% / 196 mi`). It sits at the bottom of the slot; when one line does not fit the column it wraps to `100%` / `520 km` and grows up (at 844 that takes `1,015 km`; at 667 `100% / 520 km` already wraps). `HUDEngine` gives `HUDState.battery`: hidden while GPS supplies the speed (except on the parked screen, #50), with no car link or reading this foreground session, once the link has been lost for more than 10 s, or at once when the feed stops trying (its link status goes idle: 斷線, a cancelled or failed pairing; the feed then cancels its request in flight, and a reply that still arrives does not bring the block or the gear row back); `—% / — km` until the first battery reading and once it is more than 60 s old (by phone receive time), with an empty icon; VoiceOver then says 「電量尚無讀值」 ("Battery: no reading yet") instead of the dashes.

## Parked screen (#50)

`HUDEngine` chooses the parked layout (`HUDState.layout`) after 2 distinct, in-order drive readings in a row in P, with or without a speed, and only while the last is fresh (2 s); another or unknown gear, P at 5 km/h or more, a lost or idle link or the background ends it, and GPS never parks or keeps it parked. A P with no speed of its own is judged against the speed on screen, the car's or GPS, so a shown 5 km/h or more is never parked. Parked, P is lit in `P R N D` whatever supplies the speed (GPS when the car sends none), and battery / range stays even then. The gear is tracked apart from the speed, so a fresh P with no speed at all still parks: the gauge then shows 「P 檔」 (Barlow 110; English "Gear P" shrinks to 80% of the disc) with 「車速暫不可用」 over the dashed ring, and no `P R N D`. The gauge is the drive gauge, pixel for pixel (`parkedGaugeIsTheDriveGauge`). The top center adds the date at 844 in Chinese (`10/27(二) 14:05`, plain text); 667 and English show the time only, as in the master. The left panel shows the trip card (#76).

- Tire panel (`TirePanelView`, the master's `tirePanel`): 184×288 at (585, 72) on 844, 165×272 at (486, 72) on 667. Each wheel shows whole psi (TeslaBLE converts the car's bar, the engine rounds) or `—`; a reading more than 15 minutes old by the car's own clock, or with no time, dims to `tire.stale` on its own. One time line under the car names the oldest reading, also when all are fresh (L82): 「3 分鐘前」, 「部分讀值 18 分鐘前」, 「時間未知」, 「部分讀值時間未知」, or 「尚無讀值」 before any reading. When a reading is wider than its column or the time line needs a third line, it becomes a scrolling list that names each position (only reachable with larger text for now). VoiceOver reads each wheel: 「左前,42 psi」, 「右後,尚無讀值」. `TirePanel.notSupported` (「這台車沒有提供胎壓資料」) is drawn but never chosen yet: nothing tells a car without sensors from one whose sensors have not reported.
- The car (`App/Images/car-ceramic@2x.png` / `@3x.png`) is `docs/design/frames/tire/car-ceramic.svg` rendered by headless Chrome at 104×208, and dimmed in SwiftUI with `saturation(0.12)` and `colorMultiply(0.8)` (DESIGN.md "Ceramic car dimming").
- Battery / range sits in a taller slot (y 300–369 at 844, 286–359 at 667). A value more than 60 s old stays, in `text.stale` with a grey level, over its own 「N 分鐘前」 line; the drive screen still shows `—% / — km` for it.

## Trip (#76)

`TripTracker` (HUDCore, owned by `HUDEngine`) adds up the trip (L89): it starts at the first valid speed after the app opens (not while the car's fresh gear is P), ends at the auto-parked P, and a trip whose shown speed never reached 5 km/h is dropped then, so opening the app in a parked car (GPS jitter, a link blip) leaves no trip. The ended trip stays until the next valid speed of 5 km/h or more outside parked and outside a fresh P, so GPS jitter beside a parked car does not replace it. With GPS only (no Car Bluetooth reading since the last speed above 0), 10 minutes without a speed above 0 starts a new trip at the next. Distance is the shown speed (the numeral's, car first, in m/s before rounding) held until the next, split where a speed expires; while a running trip has no valid speed it shows `—` and adds nothing (L84-3). Drive time is wall-clock since the start. The battery change is the battery % now minus at the start (a reading no more than 60 s old at the start, or one arriving within 10 s of it), hidden with no start value.

- Drive (`TripPanelView`): 本趟 `12.4 km` and 行駛時間 `0:18`, centered in `DriveLayout.leftPanel` (x 75–260, y 84–296 at 844; x 16–181, y 84–282 at 667), no title; one VoiceOver element 「行程」 read in words.
- Parked (`TripCardView`): 「行程」, 本趟 / 平均 / 最高 / 行駛時間, 「距離和車速由手機 GPS 計算」, then a divider, 本趟電量變化 and 「依車輛藍牙電量計算」 (left out with no battery change). Taller than the panel (667 with the battery group, English) it is a `ScrollView` with no indicator and a 28 px bottom fade.

## Car navigation (#77)

The drive screen's right panel (`DriveLayout.rightPanel`: x 584–769, y 84–296 at 844; x 485–651, y 84–282 at 667) shows the car's navigation (`NavigationPanelView`, the master's `navWing`): the destination (Inter 20/700, one line, `…` when too long; 「導航中」 when the car sends an empty name), 剩餘 over `18 分 ・ 12 km` (`18 min · 12 km` in English, miles in mph mode; distance to 0.1 under 10, whole from 10; minutes whole), and 「抵達時約剩 64%」 (left out when the car sends no energy at arrival; whether it is a % is checked on the car). No title; one VoiceOver element 「車上導航」 read in words. The route comes in the drive reply already polled 5 times a second (`DriveState.activeRoute*`), so the request is unchanged; a route counts only when its destination is present, and it is fresh for 2 s like the gear.

`HUDEngine` (`NavigationTracker`, `HUDState.navigation`) chooses the panel once on entering the drive layout (the app's first state, or leaving parked): navigation if a fresh route is present, otherwise empty. If it was empty, the first fresh route switches it to navigation once (L73 Q11), not while the car's fresh gear is P, fading in over 0.2 s (at once with Reduce Motion; `HUDState.navigationSwitches` counts the switches). It then stays navigation until the next drive after a valid park (the parked layout, which also ends the trip); a cancelled route, a new destination, a reconnect or the background do not choose again. A fresh reply with no destination empties the panel (L84-4); no fresh reply on Car Bluetooth leaves a dashed pin with no words (「車上導航資料過期」 to VoiceOver); GPS supplying the speed, no car link, or a link lost for more than 10 s (as the battery block) removes the whole group (L71). Parked, the right panel is the tire panel (navigation as a parked card is #79).

## Car Bluetooth on the drive screen (#46)

The drive screen shows the car's speed (● 車輛藍牙) whenever it is valid: 2 s after it reached the phone, and only with the car's own timestamp. Otherwise it shows GPS (◐ GPS · 藍牙資料過期 once a car speed came and expired in this foreground session, ● GPS before that or with no paired car), otherwise `—` (▲ 車速暫不可用). The first car speed after the app comes to the front shows at once; after a lapse the car returns only after 2 distinct, in-order readings in a row (car timestamps compared). A repeated car timestamp is not a new reading: it may update the shown value, but the 2 s window runs from the first arrival of that timestamp, so a frozen drive state falls back after 2 s. Car speed is its magnitude, rounded to the nearest whole km/h, with no dead-band. The rules live in `HUDEngine` (HUDCore); `App/BLE/CarEvents.swift` maps the feed's polls to HUDCore's car events.

A paired car is the VIN stored in the Keychain with the app key. Only pairing stores it (#55), after reading the car; the client never does on its own. The main screen listens to the car feed while the app is in front; listening makes the feed connect and poll: to the car last connected in this app run (by pairing, the test page's 連線, or the feed itself), else the paired car; with neither it never connects. Going to the background or locking the phone suspends the feed: it disconnects, also ending a 連線 still in progress; coming back resumes it. The Bluetooth central is created at launch only when the Keychain holds a paired VIN, or cannot be read because the phone is locked (a background relaunch); otherwise it waits for the first connect (pairing's S15, or the test page's 連線), so a phone that was never paired is asked for Bluetooth permission only when pairing starts looking for the car.

## Pairing with a typed VIN (#55)

The drive screen has a settings gear top-right (48×48 at x 721 / 603, y 16). While no car is paired it carries a setup dot, and a first-launch card at the bottom says 「連接你的 Tesla，看排檔、電量、胎壓」 with 「現在連接」 and 「之後再說」 (L66; 之後再說 hides it for good, `pairing.inviteDismissed` in UserDefaults). Until the settings screens exist, the gear and 現在連接 open pairing directly, also with a car already paired.

- S13: the checklist; 開始 needs 「車子已經停好(P 檔)」 (L67, no GPS gate).
- S14: the VIN, typed or pasted: upper-cased, O → 0 and I → 1, Q flagged, grouped 3 · 6 · 8, 「已輸入 12 / 17 碼」. A wrong 9th character warns 「號碼好像打錯了，請再對一次」 with 仍要繼續. 「在哪裡找到 VIN？」 opens a placeholder until #58.
- S15: the feed connects to the VIN; the moment the scan sees the VIN's Bluetooth name the screen says 就是旁邊這台 (the nearby match, `TeslaClientEvent.vehicleFound`). If the feed is already connected to that car, the match shows at once.
- S16: the key card, while the car waits for it. A car that already holds this app key skips it.
- S17: one read; only with drive state back is the car stored as the paired car, replacing any other (L65). A live preview of speed, gear and battery until 完成. From then on the feed connects to it, with no restart.
- Any failure is one screen with 重試 and 稍後再說 (S18 a–h are #56). 取消 or 稍後再說 leave no paired car behind and send the feed back to the paired car, if any; a key the car already accepted stays on the car. The one exception: writing the paired VIN is the commit point, so a cancel that lands while it is being written leaves the new car paired (the screen just closes).

The VIN rules (look-alikes, check digit, candidates in recognized text, agreement over camera reads, the typed entry) are `VIN.swift` in TeslaBLE, pure and shared with the camera scan (#57). `App/Pairing/PairingFlow.swift` is the coordinator; `PairingScreen.swift` draws the steps.

## Drive logger (test build, #30)

The main screen has a small 行車紀錄 button (under the gear) that opens 行車紀錄(測試): it shows the paired car; its VIN field is a testing override (empty means the paired car, and it never becomes the paired car); 連線, 加入鑰匙 (once), 讀一次, 開始紀錄 / 停止紀錄, 匯出. The page does not poll the car itself. The app's one car feed (`CarFeed` in TeslaBLE, created at launch) owns the connection, and every button goes through it. The feed keeps the link up and polls while someone listens: the main screen while the app is in front, and this page while recording, which logs phone GPS speed on the same timeline. One request is in flight at a time, one category per request, as vehicle-command's `GetState` does (replies to one request for all three claimed RESPONSE_MTU_EXCEEDED, #39). Drive state is asked as soon as the previous reply arrives, but never sooner than 200 ms after the previous drive request, so about 5 a second (L61). Charge state and tire pressure are each asked once every 10 s, right after a drive reply and followed by the next drive request, so two of them are never sent back to back. Each drive slot makes one row: a drive request, with the charge state or tire pressure request asked just before it (if any) on the same row. Drive state is the slot's last request, so the row's phone time and GPS fix are taken right after the drive reply. If charge state or tire pressure fails because the link is down or the car does not answer the handshake (`notConnected`, `disconnected`, a link error, `timeout(sessionInfo)`), the slot's drive request is not sent: the row is still written, with drive marked `skipped`. A fault or a failed reply does not skip it. The first request after polling starts or resumes is drive state; 讀一次 counts as asking charge state and tire pressure, and a slot cut short by a pause leaves its charge or tire pressure due again. While the link is down the feed sends nothing and no rows are written. 讀一次 asks for all three and lists which came back, or which were skipped. 讀一次, 加入鑰匙 and the session start after 連線 pause the feed's polling (the request in flight is cancelled) and it resumes afterwards. If the link drops while someone listens, the feed reconnects on its own to the last connected car (else the paired one) (自動重新連線中; `auto_reconnect` events). Failed attempts, and slots where nothing came back verified (the car does not know the key, its key changed, it does not answer), retry quietly after 1 s, doubling to at most 10 s; the next verified reply resets it. If CoreBluetooth's own reconnect has not finished after 15 s, it is cancelled and the feed's reconnect takes over (`system_reconnect_stalled`).

Two kinds of log folder, each with the same files:

- Diagnostics, `Documents/Diagnostics/<time>/`: starts at the first 連線 (or 加入鑰匙 / 讀一次 / 開始紀錄) after the app launches and covers everything until the app quits, so a failed connect or enrollment is kept. 讀一次 rows go here too. Past about 50 MB a new folder continues it (`diagnostics_rotated`, `continues`); only the newest 10 diagnostics folders are kept.
- Recordings, `Documents/Logs/<start time>/`: one per 開始紀錄 … 停止紀錄.

Files:

- `samples.csv`: one row per drive slot (and per 讀一次 in diagnostics). An empty value cell means the car did not send it, or the category was not asked for: the battery and charging columns are filled on about one row in 50, and the tire columns on another one in 50. `drive_*`, `charge_*` and `tire_pressure_*` give each category's own `response_ms` (from the completed write to the reply) and `error`; both are empty when the category was not asked for on that row, and `error` is `skipped` when an earlier category's link or handshake failure skipped it. `response_ms` and `send_wait_ms` add up the categories that came back, and `error` is the first error of the row. 停止紀錄, 讀一次 and 加入鑰匙 cancel the feed's request in flight: a cancelled category is left out of the row, and a slot whose drive request was cancelled (with no other failure) writes no row. A reply whose tag fails but claims a fault logs it as `invalidResponseTag(reportedFault: …)` and an `unverified_fault` event (「車子回報:回應太大(未驗證)」); the app never acts on it.
- `gps.csv`: every phone GPS fix (speed and accuracy only, no coordinates). Recordings only.
- `events.jsonl`: every connect, disconnect, handshake, request, response, fault, timeout, enrollment step and app state change. The BLE local name (derived from the VIN) is not written.
- `frames.txt`: every whole BLE message, hex, both directions. A reply that came back unencrypted is written only as its byte count, because its payload can hold private data such as the navigation destination.
- `meta.json`: app build, iOS version, phone model, masked VIN, settings, counts. `settings` give the cadence (`drive_request_min_interval_ms`, `charge_interval_ms`, `tire_pressure_interval_ms`, …). `error_count` counts rows where drive state did not come back (failed or skipped); `category_error_count` counts rows where drive state came back but charge state or tire pressure did not. The page shows the first as 「錯誤 N 筆」 and the second, when not zero, as 「另有 N 筆只有充電或胎壓沒讀到」.

匯出 shares one zip with this run's diagnostics folders and the latest recording; it works before any recording exists.

In the background: GPS is when-in-use and there is no background location mode, so locking the phone or switching apps stops GPS. The car feed disconnects too (L60), so a recording has no car rows until the app is back in front: `app_phase` events mark the switch, and `gps_fix_age_ms` grows while GPS is stopped. The screen stays on while the app is open, so the owner is asked not to lock the phone.

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
