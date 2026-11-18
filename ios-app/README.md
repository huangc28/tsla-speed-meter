# Speed HUD (iOS)

Native Swift rewrite, iPhone first (`docs/design/00-rulings.md` L59). The earlier Flutter app was removed from `main` on 2026-10-24; it is in git history up to `9e621ba`.

- `project.yml`: XcodeGen spec. The `.xcodeproj` is generated and not committed.
- `App/`: SwiftUI app target `SpeedHUD` (bundle id `com.tslaspeedmeter.hud`).
- `AppTests/`: unit tests hosted in the app.
- `Packages/HUDCore/`: local SwiftPM package, pure Swift logic (no UIKit, SwiftUI or CoreBluetooth).
- `App/Fonts/`: Inter Regular, Medium, SemiBold and Bold from Google Fonts, SIL Open Font License 1.1 (`App/Fonts/Inter-OFL.txt`, shipped in the app bundle), for the parked cards' Latin text (the drive screen's frame uses the system font since #100); Hanken Grotesk Medium and SemiBold, the static 500 and 600 instances Google Fonts serves, SIL Open Font License 1.1 (`App/Fonts/HankenGrotesk-OFL.txt`, shipped in the app bundle), for the round gauge's numeral, unit and `P R N D` (#98). CJK text uses the system font.
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

`HUDRenderTests` (drive and parked screens) and `PairingRenderTests` (S13–S17) compare the main states against `AppTests/References/*.png` (1x, small per-pixel tolerance; 844 × 390 and 667 × 375, plus drive and parked states at the owner's 956 × 440). The pairing screens, and the parked screens whose left card scrolls, render in a window (`drawHierarchy`), because `ImageRenderer` draws the VIN field and scroll views as placeholders. After an intended visual change, re-record, look at the new PNGs, and commit them:

```sh
TEST_RUNNER_RECORD_REFERENCES=1 xcodebuild test -project SpeedHUD.xcodeproj -scheme SpeedHUD \
  -destination 'platform=iOS Simulator,id=<simulator id>' -derivedDataPath DerivedData \
  -only-testing:SpeedHUDTests/HUDRenderTests -only-testing:SpeedHUDTests/PairingRenderTests
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

## Round gauge (#98)

The drive screen's gauge is the round gauge of `docs/design/DESIGN-atelier-tesla-edition.md`, ported from the design page's `ringT(true)`, `ticksT`, `gearsT`, `numT` and `unitT`. Its geometry is in HUDCore (`RoundGauge`) in 844 × 390 design points; `DesignCanvas` scales them uniformly by `min(w / 844, h / 390)` and centres the box, so 844 × 390 is 1:1, 667 × 375 about 0.79 and 956 × 440 about 1.13. `NumeralLayout` gives each digit's pen in its fixed 57.8 cell, the group centred; the baseline, the unit and the reason come from the ink of "8" (`HankenMetrics`, checked against the bundled font), so nothing moves with the digit count. With no speed the numeral is a 49.4 × 4.2 dash with the reason 12 below it, and the ring stays the same. `RoundGauge.slots` are the four icon-disc centres and the empty speed-limit slot, in design points; `CarStatusDiscs` draws the lit discs there through the canvas. The clearance gate (`RoundGaugeClearanceTests`) measures every speed from 0 to 250 against the production disc layer on 1x ink masks, as the design's `tools/clr.py` does. The left card, the tire column, the footer and the top row are on the same canvas (#100, below). The source chip shows Lucide icons (the words are its VoiceOver label); a small arrow left of the unit marks GPS speed (green, or amber for GPS fallback). The time is 24-hour and updates each minute.

## Drive screen frame (#100)

The rest of the drive screen is ported from the design page's `navX`, `tyreColN(COL25.a)`, `footX` and `topRow` (`App/DriveFrameViews.swift`), in design points on the canvas (`DriveFrame`: the left card (62, 79, 183, 181), the tire column from x 592 to 768, the footer on y 345.6 from x 90 to 769, the top row at y 16). Its text is the iOS system font at the page's weights and sizes, placed by its ink as the page's `placeF` does (`PlacedText`: left or right ink edge, the ink of "0" or of the string centred on a line, tabular digits unless proportional); Hanken Grotesk stays in the gauge. Nothing follows Dynamic Type, as before: the drive frame's text is fixed-size and scales only with the canvas.

- Left card (owner decision 1, #96; `HUDState.driveLeftCard`): the car navigation while it is shown (#77's rules), otherwise the trip (#76), in the same face (`xnFill`, `xnRim`, radius 17). Only the Q11 switch fades its content (0.2 s, at once with Reduce Motion); a route that ended or a GPS fallback swaps it at once, and the face never fades.
- Tire column (`TireColumnView`): the tire mark and 胎壓 ("Tires"), the top-view car 130 high (the page's `CAR_BODY`, `CAR_GLASS`, window and mirror paths), and a reading beside each tire, 15/500. A low wheel (`TireWheel.isLow`, #97) fills its tire and turns its reading amber (`icon-warning`); a reading more than 15 minutes old or with no time dims to `tire.stale` unless it is low; no reading is `—`. It shows with the rest of the car data (`HUDState.tires` on the drive screen, `showsCarData`): hidden with no car link, an idle link, a link lost for more than 10 s, and while GPS supplies the speed. VoiceOver reads each wheel as its own element: 「左前,42 psi」, 「左後,31 psi,胎壓不足」, 「右後,尚無讀值」.
- Footer, drive and parked: battery and range on the left (`BatteryBlockView`: the outline filled with the level, `72` `%` · `315 km`), `ODO` and the odometer on the right (`OdometerView`, `HUDState.odometer`: whole km rounded down, or whole miles in mph mode, `— km` before the first value; VoiceOver 「總里程 48,213 公里」). Both hide like the battery block.
- Top row: the source icon at (75, 16), the time 12 right of it (system font 17/600 `FF.sec`), the gear (24, `FF.sec`) at (721, 16); the icons and the time scale with the canvas, the gear's hit area stays 48.
- Clearance (`DriveFrameTests.theFrameClearsTheRing`): at 844 the left card is 21 from the ring's line and each tire-column element at least 20 (the nearest, the front-left reading `44 psi`, 20.5).
- VoiceOver reads the top row, the left card, the speed, `P R N D`, the lit discs, the wheels, the footer, then the settings gear (`DriveScreen.readingOrder`).
- The first-launch invitation stays at the bottom, unscaled, over the ring's bottom arc as before (a known gap: below the ring there are 40 pt and the card is 56 high).

## Gear row (#48)

`P R N D` sits inside the top of the ring, 0.692 of its radius above the centre, letters 21.6 apart, in Hanken Grotesk 500 grey with the current gear 600 in white (`GearRow`, its own VoiceOver element 「檔位 D」). `HUDEngine` gives the gear (`HUDState.gearRow`) only while the car's speed shows (or on the parked screen, #50), and only after 2 distinct, in-order readings in a row with a known gear, also on cold start; a stale reading, a lost link, a link the feed stopped trying (idle: 斷線, a cancelled pairing), an unknown gear or a fresh P at 5 km/h or more hides the whole row, and it comes back only after 2 new readings, so a P flickering around 5 km/h never makes it blink. Showing or hiding it changes no pixel outside the row (`gearRowMovesNothingElse`).

## Battery / range (#49)

The footer's left (#100, `BatteryBlockView`) shows a battery outline filled with the level and `72% · 315 km`, the car's rated range converted from miles to km, or shown in miles in mph mode (`72% · 196 mi`), on one line. `HUDEngine` gives `HUDState.battery`: hidden while GPS supplies the speed (except on the parked screen, #50), with no car link or reading this foreground session, once the link has been lost for more than 10 s, or at once when the feed stops trying (its link status goes idle: 斷線, a cancelled or failed pairing; the feed then cancels its request in flight, and a reply that still arrives does not bring the block or the gear row back); `—% · — km` until the first battery reading and once it is more than 60 s old (by phone receive time), with an empty icon; VoiceOver then says 「電量尚無讀值」 ("Battery: no reading yet") instead of the dashes.

## Parked screen (#50)

`HUDEngine` chooses the parked layout (`HUDState.layout`) after 2 distinct, in-order drive readings in a row in P, with or without a speed, and only while the last is fresh (2 s); another or unknown gear, P at 5 km/h or more, a lost or idle link or the background ends it, and GPS never parks or keeps it parked. A P with no speed of its own is judged against the speed on screen, the car's or GPS, so a shown 5 km/h or more is never parked. Parked, P is lit in `P R N D` whatever supplies the speed (GPS when the car sends none), and battery / range stays even then. The gear is tracked apart from the speed, so a fresh P with no speed at all still parks: the gauge then shows 「P 檔」 in the numeral's face (smaller to fit its ink in 150 × 60, clear of the discs and the reason) with 「車速暫不可用」 where the unit goes, and no `P R N D`. The gauge is the drive gauge (`parkedGaugeIsTheDriveGauge`): the same pixels, except that the ring's blurred glow may composite 1 of 255 apart in one to three pixels near the top of the ring. The time adds the date in front of it at 844 and wider in Chinese (`10/27(二) 14:05`, plain text); 667 and English show the time only, as in the master. The side panels show the parked cards (#79, #101, below).

- 胎壓 card (#101): the drive screen's tire column (`TireColumnView` without its own title; the card's title button takes its place), so the car, the readings and the low amber are as on drive. Each wheel shows whole psi (TeslaBLE converts the car's bar, the engine rounds) or `—`; a reading more than 15 minutes old by the car's own clock, or with no time, dims to `tire.stale` on its own. One time line under the car names the oldest reading, also when all are fresh (L82): 「3 分鐘前」, 「部分讀值 18 分鐘前」, 「時間未知」, 「部分讀值時間未知」, or 「尚無讀值」 before any reading; 13/400 `FF.sec` centred on the car (x 683), its ink 14 below the car's, on two lines when wider than the column (English 「Some readings: time unknown」). VoiceOver reads each wheel (「左前,42 psi」, 「右後,尚無讀值」), then the time line once. The column fits at every size, so the old scrolling list and the photo-like ceramic car are gone. `TirePanel.notSupported` (「這台車沒有提供胎壓資料」) is drawn but never chosen yet: nothing tells a car without sensors from one whose sensors have not reported.
- Battery / range is the footer's (#100). A value more than 60 s old stays, in `text.stale` with a grey level, with its age 「N 分鐘前」 after a dot; the drive screen still shows `—% · — km` for it.

## Trip (#76)

`TripTracker` (HUDCore, owned by `HUDEngine`) adds up the trip (L89): it starts at the first valid speed after the app opens (not while the car's fresh gear is P), ends at the auto-parked P, and a trip whose shown speed never reached 5 km/h is dropped then, so opening the app in a parked car (GPS jitter, a link blip) leaves no trip. The ended trip stays until the next valid speed of 5 km/h or more outside parked and outside a fresh P, so GPS jitter beside a parked car does not replace it. With GPS only (no Car Bluetooth reading since the last speed above 0), 10 minutes without a speed above 0 starts a new trip at the next. Distance is the shown speed (the numeral's, car first, in m/s before rounding) held until the next, split where a speed expires; while a running trip has no valid speed it shows `—` and adds nothing (L84-3). Drive time is wall-clock since the start. The battery change is the battery % now minus at the start (a reading no more than 60 s old at the start, or one arriving within 10 s of it), hidden with no start value.

- Drive: the left card when it does not show navigation (#100): 本趟 `12.4 km` and 行駛時間 `0:18`, each a 12/400 label over a 20/600 value, centred in the card's height, no title; one VoiceOver element 「行程」 read in words.
- Parked (`TripCardView`): 「行程」, 本趟 / 平均 / 最高 / 行駛時間, 「距離和車速由手機 GPS 計算」, then a divider, 本趟電量變化 and 「依車輛藍牙電量計算」 (left out with no battery change). Taller than the panel (667 with the battery group, English) the left panel scrolls it (`CardScroll`) with the system's scroll indicator and a 28 px bottom fade; its title is the card button 「行程 ⌄」 (#79).

## Car navigation (#77)

Since #100 the drive screen shows the car's navigation in its left card (`LeftCardContent`, the design page's `navX`, over its road art): the destination 15/400 beside the pin (one line, `…` when too long; 「導航中」 when the car sends an empty name), the distance 20/600 with its unit (miles in mph mode; to 0.1 under 10, whole from 10), 「剩餘 18 分」 ("Remaining 18 min"; minutes whole), and 「抵達時約剩 64%」 (left out when the car sends no energy at arrival, 0% for a negative estimate; whether it is a % is checked on the car). No title; one VoiceOver element 「車上導航」 read in words. The route comes in the drive reply already polled 5 times a second (`DriveState.activeRoute*`), so the request is unchanged; a route counts only when its destination is present, and it is fresh for 2 s like the gear.

`HUDEngine` (`NavigationTracker`, `HUDState.navigation`) chooses the panel once on entering the drive layout (the app's first state, or leaving parked): navigation if a fresh route is present, otherwise empty. If it was empty, the first fresh route switches it to navigation once (L73 Q11), not while the car's fresh gear is P, fading in over 0.2 s (at once with Reduce Motion; `HUDState.navigationSwitches` counts the switches). It then stays navigation until the next drive after a valid park (the parked layout, which also ends the trip); a cancelled route, a new destination, a reconnect or the background do not choose again. A fresh reply with no destination ends it: the left card shows the trip (L84-4); no fresh reply on Car Bluetooth leaves a dashed pin with no words (「車上導航資料過期」 to VoiceOver), but only once a drive reply came in this app run: before the first, the panel is empty (#79); GPS supplying the speed, no car link, or a link lost for more than 10 s (as the battery block) removes the whole group (L71), and the left card shows the trip: during the brief GPS fallback when a drive request times out (#93) it swaps to the trip at once, with no fade and no Q11 switch, and back when the car's speed returns. Parked, navigation is a right card (#79, #101: `NavigationCardBody`, below); entering drive after it, the panel is navigation.

## Car-status icons (#78, #99)

The front trunk, door, rear trunk and tire each have a fixed disc inside the ring (`RoundGauge.slots`; DESIGN-atelier-tesla-edition.md "Icon disc", L108), on the drive and the parked screen, drawn only for an event: open is the red (`icon-open` `#EF6A69`) open drawing, a low tire the amber (`icon-warning` `#EFA83F`) tire, unknown the grey (`icon-unknown` `#A6ACB5`) closed outline in flat-capped dashes; closed, normal and a tire with no reading draw nothing, not even the disc. `CarStatusIcon` (`App/CarStatusView.swift`) ports the design page's `slotT` as the main screen calls it: the disc (`discT`, the `defsT` gradients, 37.1 with a 0.7 rim), the icons in the owner's 576 × 576 crop coordinates (`TI`, `tiInner`, scaled by `TK`, line 21 units ≈ 1.67), and the dashes (`tDash` with the main screen's 60 / 50). The app's gap is 45 and the dashes come from the design's `tDash` at that gap, with phases found on the native 1× 844 render (`CarStatusIcon.nativeGap`, `nativePhase`): the design's gap of 35 and `T_OFF_LOW` were tuned on Chrome, and CoreGraphics places dash ends near corners differently, so the app keeps the guide's rule instead, a real gap of at least 2 px at 1×. Each disc view sits on whole points and draws at exact design coordinates. Each lit disc is its own VoiceOver element with its sentence (「後車廂開著」, 「車門狀態未知」, 「胎壓不足」, "Tire pressure low"), read in the slots' order: front trunk, door, rear trunk, tire. They appear and go at once. The bottom slot (`speedLimit`) stays empty, and there are no night colors yet (#81).

The car feed asks for closures (`getClosuresState`) in the 10 s batch with charge state and tire pressure; TeslaBLE keeps each door and trunk field's presence (absent is unknown, never closed). `HUDEngine` gives `HUDState.carStatus` from the last closures reply of the foreground session, one state per slot: the door is open when any door is open, and unknown when none is and any is unknown. A slot the reply left out is unknown at once; a reply more than 30 s old (the car's time of the reply, plus the phone time since it arrived, minus the closures' own time, as the tires) makes all three unknown, and each slot comes back with its own next value. Before the first closures reply, all three are unknown. The tire slot (`CarStatus.tire`, #97) comes from the last tire reply instead, so it can be low or normal with no closures reply: low when the car's own TPMS warning (hard or soft) is on for any wheel, and no reading before the first tire reply or once it is more than 30 s old by the phone's clock. The group shows whenever battery / range may (`showsCarData`): it is hidden with no car link, when the link goes idle (a late reply stores nothing), once the link has been lost for more than 10 s, and while GPS supplies the speed, except parked. `CarStatusIconTests.iconsStayInsideTheirDiscs` checks that every icon's ink stays 1 inside its 37.1 disc, so `RoundGaugeClearanceTests` covers the icons: it renders the production discs (`CarStatusDiscs`, each slot in each state it can show) and takes the pixels they cover by more than 60 of 255 (as the design's white `&ink=disc` passes 60 on black), and measures them against the numeral at every speed 0–250, the dash, 「P 檔」 / "Gear P", the unit (km/h and mph, with the GPS cue), the reasons, `P R N D` and the ticks on 1x ink masks at 844. The reason under the dash and under 「P 檔」 is one line in both languages.

## Parked cards (#79)

Parked, each side panel shows one card under a title button (07 §2.3, §3.1, L84-7, M12-14): 行程 or 車況 on the left, 胎壓 or 車上導航 on the right (正在播放 is #83). The defaults are 行程 and 胎壓; the choice is stored in UserDefaults (`CardStore`: `cards.left`, `cards.right`) and shown on the next parked screen. Cards that need car data are not offered without it, and the right panel then says 「尚無車輛資料」 (the engine cannot reach that yet: the fresh car P that parks also links the car).

- `CardSwitcher` (HUDCore, owned by `HUDEngine`) holds the choice, the open list and a swipe under way; `HUDState.panels` (parked only) gives each side's cards and the one showing. Card actions count only while parked, and leaving parked cancels an open list or a swipe for good (M12-03, M12-04). Entering drive, `NavigationTracker` takes the right card: navigation when it was 車上導航, else navigation if a fresh route is set, else empty (07 §3.1).
- Frames (#101, `DriveFrame.parkedLeft` / `parkedRight`): each side in its drive frame's band on the canvas, with no face (the cards are text and drawings on the ground). The left runs from the text column x 75 to the left card's right edge 245 (21 from the ring), the right across the tire column's band, 592–768, with its text column at x 598.5 (the column title's place); both from the title row, 20 high and centred on the drive frame's titles' line y 98.2, to 3 above the footer's ink. Everything in them scales with the canvas (about 0.79 at 667, 1.13 at 956), except the hit areas.
- The title `名稱 ⌄` (16/600 `accent.text`, the master's `.pt.btn`) has a 44-high hit area at least 120 wide, unscaled; on the right it stays below the settings gear (at 667 it starts 0.9 lower than centred). It opens a list over its panel, 6 past the panel's outer edges but not past its ring-facing edge (#98; x 69–245 and 592–774 at 844, on whole points), unscaled: 44-high rows, 16 px names, a check on the current card; choosing one, the title again, a tap outside or VoiceOver's escape closes it. Vertical dots (4 px, 3 apart, current filled) sit at the title row's right end.
- A vertical swipe moves one card (up for the next; the ends do not wrap), with a light haptic. On a card whose content scrolls, only a swipe that starts on the title row switches, and there it takes the drag from the scroll view (a high-priority gesture), so it does not also scroll; elsewhere it works anywhere on the panel. The gesture is attached to the panel and to the title row, and `CardSwipe.end` decides what a finished drag does (the action and whether the haptic plays, injected for tests). A `DragGesture` cannot be synthesized in-process, so the attach sites themselves are a car-run check; the list and VoiceOver's actions are driven through the hosted screen.
- VoiceOver reads the title as 「胎壓，第 1 張，共 2 張」 with the button trait, and offers 下一張 / 上一張 where there is one. Each card reads its title, then its body (`DriveScreen.readingOrder`'s `leftTitle` / `rightTitle`, on the leaf views).
- Leaving parked, the panels fade to their drive content in 0.25 s (at once with Reduce Motion). Nothing on the drive panels can be tapped.
- 車上導航 (`NavigationCardBody`, #101) draws `navX`'s content with no road art: the pin and destination (15/400 `FF.mid`, one line with `…`) with the pin's top 20 under the title row, the distance (20/600 and its unit 14/500) 36 below, then 剩餘 and 抵達時約剩 (12/400 `FF.sec`) at `navX`'s own steps; the stale pin dashed as on drive; a route known to have ended says 「車上沒有在導航」. Like the other parked car data, GPS supplying the speed does not hide it. With no trip, 行程 says 「尚無行程」.
- 行程 and 車況 keep their rows in the frame's type (#101): the system font, labels and notes in `FF.sec`, values in `FF.mid` (tabular), at their old sizes times the canvas's scale.
- Clearance (`ParkedCardsTests.theCardsClearTheRing`): at 844 every card's ink stays at least 20 from the ring's line for the widest content (left 21.0, right 20.3 on ink; the navigation text boxes 20.5), and nothing on the left draws past x 245.
- 車況 (`A-v-park-vehicle`): 總里程 (the drive reply's `odometerInHundredthsOfAMile`: whole miles straight from it in mph mode, or km, rounded down), 車外 and 車內 (climate state, °C or °F as the system shows them; hidden after 90 s), and 車窗 (closures, aged like the car-status icons): the open one by position (「左後開著」, the left being the driver's side), 「2 扇開著」, 「都關著」 only when all four came back closed. A row with no value is not drawn; a row too wide for one line (667 English) puts its value under the label.
- The car feed asks climate state (`getClimateState`) only while parked (`CarFeed.setClimatePolling(_:)`; `HUDViewModel.pollsClimate` decides: parked and in front), once every 30 s in the slow batch. On the fake car with 150 ms round trips, drive state still comes back 4.83 times a second with it (4.85 without).
- The top row shows the outside temperature while parked (`DriveLayout.temperatureSlot`, the design's x 633 on the canvas): Lucide `thermometer` 16 and `23°` 13/500, scaled with the canvas, VoiceOver 「車外 23 度」; nothing without a value. Neither it nor the date meets the ring's ink or the gear's hit area at 844, 667 and 956 (`ParkedCardsTests.theTopRowClearsTheRingAndTheGear`).
- The one-time card (L84-5, the master's `NOTICE2` / `NOTICE2_EN`): 「胎壓僅供參考，請以車上的胎壓警示為準。」, 「停車時點標題或上下滑動，可以換內容。」 and one 「知道了」, pinned above the left card and in no card. Switching cards keeps it; 知道了 hides it for good (`cards.hintDismissed`). The card below moves down and the panel scrolls; when 知道了 would not clear the fade at the panel's top the panel starts at y 52, or right below the top row at 667 (`DriveLayout.parkedHintTop`, y 73), so it is whole on the first parked screen (R7-16). Since #101 the card scales with the canvas, except 知道了's 44-high hit area, so it fits the narrower 667 panel without moving up.

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

The main screen has a small 行車紀錄 button (under the gear) that opens 行車紀錄(測試): it shows the paired car; its VIN field is a testing override (empty means the paired car, and it never becomes the paired car); 連線, 加入鑰匙 (once), 讀一次, 開始紀錄 / 停止紀錄, 匯出. The page does not poll the car itself. The app's one car feed (`CarFeed` in TeslaBLE, created at launch) owns the connection, and every button goes through it. The feed keeps the link up and polls while someone listens: the main screen while the app is in front, and this page while recording, which logs phone GPS speed on the same timeline. One request is in flight at a time, one category per request, as vehicle-command's `GetState` does (replies to one request for all three claimed RESPONSE_MTU_EXCEEDED, #39). Drive state is asked as soon as the previous reply arrives, but never sooner than 200 ms after the previous drive request, so about 5 a second (L61). Charge state, tire pressure and closures (doors, frunk, trunk; #78) are each asked once every 10 s, right after a drive reply and followed by the next drive request, so two of them are never sent back to back; while parked, climate state (#79) joins them once every 30 s. Each drive slot makes one row: a drive request, with the charge state, tire pressure or closures request asked just before it (if any) on the same row. Drive state is the slot's last request, so the row's phone time and GPS fix are taken right after the drive reply. If one of those fails because the link is down or the car does not answer the handshake (`notConnected`, `disconnected`, a link error, `timeout(sessionInfo)`), the slot's drive request is not sent: the row is still written, with drive marked `skipped`. A fault or a failed reply does not skip it. The first request after polling starts or resumes is drive state; 讀一次 counts as asking those (and climate), and a slot cut short by a pause leaves its category due again. While the link is down the feed sends nothing and no rows are written. 讀一次 asks for all five (climate too, #79) and lists which came back, or which were skipped. 讀一次, 加入鑰匙 and the session start after 連線 pause the feed's polling (the request in flight is cancelled) and it resumes afterwards. If the link drops while someone listens, the feed reconnects on its own to the last connected car (else the paired one) (自動重新連線中; `auto_reconnect` events). Failed attempts, and slots where nothing came back verified (the car does not know the key, its key changed, it does not answer), retry quietly after 1 s, doubling to at most 10 s; the next verified reply resets it. If CoreBluetooth's own reconnect has not finished after 15 s, it is cancelled and the feed's reconnect takes over (`system_reconnect_stalled`).

Two kinds of log folder, each with the same files:

- Diagnostics, `Documents/Diagnostics/<time>/`: starts at the first 連線 (or 加入鑰匙 / 讀一次 / 開始紀錄) after the app launches and covers everything until the app quits, so a failed connect or enrollment is kept. 讀一次 rows go here too. Past about 50 MB a new folder continues it (`diagnostics_rotated`, `continues`); only the newest 10 diagnostics folders are kept.
- Recordings, `Documents/Logs/<start time>/`: one per 開始紀錄 … 停止紀錄.

Files:

- `samples.csv`: one row per drive slot (and per 讀一次 in diagnostics). An empty value cell means the car did not send it, or the category was not asked for: the battery and charging columns are filled on about one row in 50, the tire columns on another one in 50, and the closures columns (added at the end of the row, #78: `door_*_open`, `trunk_front_open`, `trunk_rear_open`, `closures_state_time`; `true`, `false`, or empty when the car did not send it) on a third. #79 appends `window_*_open`, `climate_response_ms`, `climate_error`, `outside_temp_c`, `inside_temp_c`, `climate_state_time` (climate is asked only while parked), `odometer_hundredths_mi` and `odometer_km`. `drive_*`, `charge_*`, `tire_pressure_*`, `closures_*` and `climate_*` give each category's own `response_ms` (from the completed write to the reply) and `error`; both are empty when the category was not asked for on that row, and `error` is `skipped` when an earlier category's link or handshake failure skipped it. `response_ms` and `send_wait_ms` add up the categories that came back, and `error` is the first error of the row. 停止紀錄, 讀一次 and 加入鑰匙 cancel the feed's request in flight: a cancelled category is left out of the row, and a slot whose drive request was cancelled (with no other failure) writes no row. A reply whose tag fails but claims a fault logs it as `invalidResponseTag(reportedFault: …)` and an `unverified_fault` event (「車子回報:回應太大(未驗證)」); the app never acts on it.
- `gps.csv`: every phone GPS fix (speed and accuracy only, no coordinates). Recordings only.
- `events.jsonl`: every connect, disconnect, handshake, request, response, fault, timeout, enrollment step and app state change. The BLE local name (derived from the VIN) is not written.
- `frames.txt`: every whole BLE message, hex, both directions. A reply that came back unencrypted is written only as its byte count, because its payload can hold private data such as the navigation destination.
- `meta.json`: app build, iOS version, phone model, masked VIN, settings, counts. `settings` give the cadence (`drive_request_min_interval_ms`, `charge_interval_ms`, `tire_pressure_interval_ms`, `closures_interval_ms`, …). `error_count` counts rows where drive state did not come back (failed or skipped); `category_error_count` counts rows where drive state came back but charge state, tire pressure or closures did not. The page shows the first as 「錯誤 N 筆」 and the second, when not zero, as 「另有 N 筆只有充電、胎壓或車門沒讀到」. Since #78 `settings.drive_slot` names closures too, and `charge_and_tire_pressure_between_drive_requests` is renamed `slow_categories_between_drive_requests` (same meaning: charge state, tire pressure and closures are each followed by a drive request).

匯出 shares one zip with this run's diagnostics folders and the latest recording; it works before any recording exists.

Probe (#92, test only): the 紀錄 step has a 探測其他資料(測試) switch, off at every launch and locked while recording. While a recording runs with it on, the car feed (`CarFeed.setProbing(_:)`) also asks the seven GetVehicleData groups the app does not read (location, charge schedule, preconditioning schedule, media, media detail, software update, parental controls), and climate state while the parked screen is not asking it, each once every 30 s in a slot where no other category is due and the previous drive request came back; at most one group is asked for the first time every 5 s, so drive state still comes back about 4.7 times a second on the fake car (150 ms round trips). Every decrypted reply of all twelve groups goes to the recording's `probe.jsonl`, one JSON object per reply: `group`, `answered`, `retired`, `phone_time`, `monotonic_ms`, `text` (protobuf text format: known fields by name, unknown fields at every nesting level by number) and `plaintext_hex`, or `error`. A group the car refuses (a signed action status not OK, or a vehicle fault) is not asked again in that recording; one that does not answer is dropped after two misses in a row, a miss in a slot where drive state failed too not counting, or after four misses in all. A link drop during a probe request skips the slot's drive request and writes the cause in `samples.csv`'s `error`. The file holds the car's location and navigation destination in clear, and `meta.json`'s `unencrypted_reply_payloads_saved` and `gps_coordinates_logged` say `true` for such a recording. With the switch off nothing the app asks changes, and no `probe.jsonl` is written. `python3 Tools/probe_changes.py <zip or folder> [more …]` lists every field that changes during each recording, each change with the window between its group's two replies and the speed and gear at both ends, and the fields that changed in every log given.

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
