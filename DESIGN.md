# DESIGN.md — tsla-speed-meter

Design tokens and rules for the design locked in design round 8 (2026-10-20): speed gauge direction **C "fan"** (扇形), landscape only. These feed the Flutter implementation (Dart constants / `ThemeData` / `CustomPainter`). Register: **product** (app UI, driver in-task). Family: **digital instrument cluster**, adapted for an EV phone HUD.

Sources in parentheses: `Lnn` = `docs/design/00-rulings.md` (wins on any conflict); `02 §x` = `docs/design/02-visual.md`; `01 §x` = `docs/design/01-flows.md`; `R7-nn` / `R8-nn` = `docs/design/03-safety-review.md`. Reference mockups: `docs/design/frames/landscape-mockups.html` (PNGs in `docs/design/frames/landscape/`).

## Design principles
- **Glanceable first.** The speed numeral is the only thing that must read at a 0.3 s peripheral glance. Everything else is secondary and quieter; nothing may compete with the numeral (L32).
- **Two states.** `drive` (minimal, default while moving) and `parked` (summary, only when known to be parked). The gauge has the same size and position in both, so switching never jumps (L31, L6).
- **Landscape only**, in both landscape directions; content always stays upright. There is no portrait layout (L28).
- **No mirror mode.** The HUD is never flipped; there is no mirror setting, preview or copy (L29).
- **Gunmetal neutrals; cyan only for what you can act on.** The whole app (HUD, forms, settings) uses C's gunmetal neutral palette. Cyan is reserved for buttons, toggles, selection, links and the speed-camera side bar; static icons and list marks are neutral (L55, R8-02). Crimson is only the gauge's current-value needle. Amber is for GPS searching / warnings and the over-limit state (v1 off). Green marks a valid source.
- **State is never color-only.** Every status pairs color with a shape (● valid · ◐ fallback / connecting · ◌ waiting · ▲ no valid speed) and a word (L3, 01 §3.4).
- **Trust the reading.** No valid speed → `—` plus a reason, never `0` and never a frozen old value. Values change instantly, with no tweening (L32, L7, L39).

## Color tokens
Neutrals — gunmetal (L49, L55, 02 §9.4):
- `bg.base` `#0A0B0D` — app surface. Screens sit on a radial gradient `#1D1F23` → `#0A0B0D` (HUD: centered at 50% 45%; pages: top center).
- `surface.raised` `#24272C` — segmented-control track, toggle off, battery icon body.
- `card` `#15171A` · `card.border` `#4A4F57` — date pill, notice card, placeholders, secondary-button outline. `panel` `#1A1C20` — dialogs and the S07 panel.
- `divider` `#2A2D32`.

Text — contrast measured against the brightest background `#1D1F23` (02 §9.2):
- `text.primary` `#F5F7FA` (15.38:1) — speed numeral, titles, values.
- `text.row` `#E1E5EA` (13.04) — settings row label, secondary-button text.
- `text.secondary` `#CDD2D9` (10.86) — labels, source chip, battery line, static list icons (R8-02).
- `unit` `#A6ACB5` (7.22) — units, trip labels.
- `text.tertiary` `#8E949C` (5.40) — chrome icons (≥3:1). `text.dim` `#6B7078` — decorative lines only, never required text.
- `text.stale` `#8F949B` (5.40) — a stale battery value; "stale" is carried by its own time line, not by dimming alone (L21).
- `text.inactive` `#9EA3AA` (5.90 on `surface.raised`) — unselected segment, disabled button text.

Accent — cyan, interactive only (L55, R8-02):
- `accent` `#2BD4E0` — primary button fill and toggle on; text on it is `bg.base` (10.87:1).
- `accent.text` `#6FD8E2` (9.90) — links, selected segment text, and the speed-camera side bar + camera icon (01 §5.2).
- `accent.segActiveBg` `#1E3C45` · `accent.bright` `#8FE6EE` · `accent.dim` `#3C7A82`.
- Settings offers an accent choice: cyan (default) · indigo `#6E7BFF` (01 §6.4). Amber is never an accent (02 §4.1).

Gauge C (L49, 02 §9.4):
- `dial.band` linear `#3A3E45` → `#26292E` (top → bottom) · `dial.face` radial `#22252A` → `#1A1C20` (inside the band).
- `dial.tickMinor` `#60656D` · `dial.tickMajor` `#C3C8CF`.
- `dial.fill` `rgba(225,230,236,0.30)` · `dial.edge` `#E1E6EC` (the bright rim over the filled part).
- `needle` `#E8344F` with `needle.outline` `#0D0E10`.
- `dial.noData` `#5A5F67` (dashed outline).
- `gear.on` `#F5F7FA` (≥7:1) · `gear.off` `#83868A` (≥3:1, brightness ratio to `gear.on` ≥2:1) (R7-04).
- `speed.unavailable` `#B7BCC4` — the `—` numeral.

Semantic:
- `source.ok` `#3DE0A8` (● valid source) · `source.degraded` `#F5B53C` (◐ fallback / connecting, ▲ no valid speed, GPS searching).
- `over` `#FFB638` — amber numeral + ▲ for "over the listed limit" (ahead mode only; v1 off, L8) · `over.cardBg` `#2A1F0A` (warning cards).
- `danger.text` `#FF8A9B` · `danger.border` `#6A2C39`.
- `battery.fill` linear `#2BBF86` → `#3DE0A8` · `battery.body` `#24272C` · `battery.border` `#4A4F57` · stale fill `#5D6168`.

Tire panel (L40, L42, L49):
- `tire.backing` `#1D1F23` — the solid text backing under every reading and the shared time line; never removed (L40).
- `tire.value` `#F5F7FA` · `tire.stale` `#A6ACB5` (7.22; brightness ratio 2.27, ≥2:1) · `tire.label` `#CDD2D9` (title, shared time line) (R7-15, R7-17).

High contrast (the "Large text & high contrast" setting; 02 §9.2): secondary `#EEF1F4`, unit `#D0D4DA`, icons `#B8BDC4`, card border `#6B7078`, divider `#3A3E45`, stale battery `#A3A8AE`. The gauge itself does not change.

## Typography
Fonts are **bundled with the app**; no system fallback (L15). **Inter** for UI Latin text and non-speed numerals. **Noto Sans TC** for all CJK text. **Barlow Semi Condensed** (SIL OFL 1.1) only for the speed numeral, its unit and `P R N D` (L49, 02 §9.4). Every number uses tabular figures (`FontFeature.tabularFigures()`) (L38).

| Role | Font | Size (844 / 667) | Weight | Tracking |
|---|---|---|---|---|
| Speed numeral, 1–2 digits | Barlow SC | 176 / 164 | 400 | -1 |
| Speed numeral, 3 digits | Barlow SC | 152 / 144 | 400 | -6 |
| Unit (`km/h`, `mph`) | Barlow SC | 23 / 21 | 500 | 2 |
| `P R N D` | Barlow SC | ink cap height 13 | 700 current / 400 others | 18 px per letter cell |
| Reason under `—` (車速暫不可用) | Noto Sans TC | 18 | 600 | 1 |
| Source chip | Inter / Noto | 13 (18 large text) | 600 | 1 |
| Speed-camera alert: text / number / unit | Inter / Noto | 15 / 20 / 15 | 600 / 600 / 500 | 0 |
| Battery / range | Inter | 17 (21 large text) | 500 | 0 |
| Date pill | Inter | 13 (16 large text) | 500 | 0.3 |
| Trip label / value / unit | Inter / Noto | 13 / 18 / 12 | 600 / 600 / 500 | 1 / 0 / 0 |
| Tire reading / unit | Inter | 19 / 12 (minimum 15 / 12) | 600 / 400 | 0 |
| Tire shared time line | Inter / Noto | 12 | 400 | 0 |
| Page title | Inter / Noto | 20 | 700 | 0 |
| Body / small print | Inter / Noto | 15 / 13 (line height 1.6) | 400 | 0 |
| Settings row label | Inter / Noto | 17 | 500 | 0 |
| Buttons | Inter / Noto | 16–17 | 700 primary / 600 secondary | 0 |

**Speed numeral floors** (these are minimums, not targets; L39, L44, L46, R7-01, R7-02):
- Vertical stems ≥9 px at 844 width and ≥8.5 px at 667, and ≥ digit height ÷ 12. The thinnest parts (top/bottom of `0`, the diagonal of `7`) ≥0.8 × that floor. Check three digits, 667 width and the night preset. Measured on C: "112" stems 10.5 / 10.0 px (02 §9.2).
- No glow, shadow, outline, gradient, hollow, seven-segment or broken strokes; same weight day and night (R7-02).
- Contrast ≥7:1, measured against the brightest background within 9 px of the stroke (L38, R7-02). C: 15.38 day, ≥7.09 in the night preset.
- Three-digit ink height ≥105 px at 844 / ≥100 px at 667, measured on "147" (L39). C: 106.4 / 100.8.
- Never shrink the numeral to make room for anything else (L43).

## Spacing & radius
- Spacing scale (base 4): `2, 4, 8, 12, 16, 24`.
- Horizontal safe area: both sides use max(left, right) of the device insets, plus 16, so rotating 180° never shifts the layout. Buttons stay out of the home-indicator area (01 §7.1, 02 §2.1).
- Radius: date pill `13`, notice card `12`, cards and S07 panel `16`, dialogs `20`, buttons `16` (forms) / `10` (notice button), segmented `9–11`, toggle `15`.

## Layout (landscape)
Coordinates are screen points, origin top-left (01 §7.4). Reference sizes: 844×390 (side inset 59 + 16 = 75, bottom gesture area 21) and the 667×375 minimum (no notch, margins 16).

| Element | 844×390 | 667×375 | Rule |
|---|---|---|---|
| Gauge area | 300×300 at (272, 50) | 280×280 at (193, 50) | Screen center; same in drive and parked; nothing pushes it (L31) |
| Source chip | (75, 16), height 28, ≤270 wide (parked ≤160) | (16, 16), ≤245 (parked ≤150) | Always names the current speed source (L9) |
| Settings gear | 48×48 at x 721, y 16 | x 603, y 16 | — |
| Speed-camera alert | right column x 584–769, from y 72 | x 485–651, from y 72 | ≥12 from the gauge area (L52, R7-11) |
| Battery / range | bottom-left x 75–260; drive reserves y 321–369, parked y 300–369 | x 16–181; y 306–359 / 286–359 | One line sits at the bottom; nothing moves when it grows (L33, L50) |
| Date pill (parked) | top center, y 16–42, ≤140 wide | ≤120 wide | ≥16 from the source chip, ≥12 from `P R N D` (R6-03, R7-05) |
| Left column (parked) | status line y 52–80 (fixed), scroll area y 84–296 | y 84–282 | (01 §7.4) |
| Tire panel (parked) | 184×288 at (585, 72) | 165×272 at (486, 72) | Fixed, never scrolls (L42) |
| Bottom-right | empty | empty | Reserved for v1.x |

## Gauge spec (CustomPainter) — C "fan"
Gauge area `S` (300 at 844, 280 at 667), `k = S / 300` (L49, 02 §9.2). Unchosen gauges are kept only as references, not specs: A "direct numeral", B "LED ring" and the earlier cyan ring, in `docs/design/frames/gauge-variants.html` (L54).
- **Dial**: upper half annulus centered at (`S/2`, `157k`), outer radius `148k`, inner `118k`, filled with `dial.band`; `dial.face` inside. 0–240 km/h maps from 180° (left foot) to 0° (right foot). The dial is in km/h even when the unit is mph; only the numeral and unit change (02 §9.2).
- **Ticks**: every 10 km/h a minor tick (`R−5k` to `R−11k`, 1.5 px), every 40 a major tick (to `R−17k`, 2.5 px). No tick numbers (R6-02, R6-05).
- **Fill and needle**: `dial.fill` plus a `dial.edge` rim (4k wide, at `R−2k`) from 0 to the current speed, starting at inner radius + `10k`. The needle runs from inner + `12k` to `R−4k`, `5k` wide, round caps, over a `needle.outline` stroke `5k + 4` wide. Nothing bright may sit within 9 px of the numeral at any speed 0–240 (R7-02, L48).
- **Numeral**: horizontally centered, ink center 2 below the gauge-area center (`S/2 − 6 + 8`). Unit `22k` below the digit ink. Instant updates, no tween (L32).
- **`P R N D`**: one row directly above the numeral, inside the gauge area. 18 px per letter, so letters never shift. Current gear `gear.on` 700 + 2 px underline 3 below the baseline; others `gear.off` 400. The underline sits 13 above the two-digit ink top, ≥6 from any dial graphic at any speed. Shown only for a fresh Car Bluetooth gear and layout "speed + car status". Hidden as a whole (no dimmed letters, no `—`) on GPS-only, stale, disconnected, asleep, unknown gear, no data, or a fresh P with any valid speed ≥5 km/h. After hiding, it returns only after 2 distinct, in-order fresh readings. Showing or hiding moves the numeral 0 px; changes are instant, at most a 150 ms opacity fade, 0 ms with reduced motion. R and N follow the same rules (L43, L46, R7-03–R7-07).
- **▲ over the listed limit** (ahead mode only; v1 off): one amber ▲ 24×20 directly below the unit at (422, 318) / (333, 302), together with an amber numeral. ≥12 from numeral and unit; ≥137 from the needle at any speed. Never beside the number or in the gear row (L46, R7-08, 02 §9.3).
- **No data**: `—` in `speed.unavailable` at the two-digit size, reason text below it (車速暫不可用 / GPS 不可用). Only a dashed outline of the band (`dial.noData`, 2 px, dash 5/8) — no fill, needle, ticks or gear row. It must not look like 0 km/h (L39 Q39, R6-05).
- **Parked, fresh P but no speed** (S06-f): `P 檔` at 110 in the center, reason below, dashed outline; `P R N D` hidden so P is not repeated (01 §2.2).
- **Night (dimmest preset; provisional until T03, 02 A25, Q42)**: numeral `#C0C2C4`, unit and `—` `#888D94`, secondary text `#93979C`, `gear.off` `#777B7F`, edge `#9DA1A5`, major ticks `#8F9298`, needle `#C32A41`, fill opacity .18. Source dot and battery fill at 62% brightness. Same weights and positions; no glow (L44, R7-02).

## Speed-camera alert (Taiwan, nearby mode)
- **Style: side bar** (L52). No card, no border. A 3 px `accent.text` bar on the left, 13 padding. A 20 px camera icon in `accent.text` starts the first line, then one line of text (02 §9.1).
- **Wording** (L53): 「此路段限速 60 公里」 / "Speed limit 60 km/h". With mph: 「此路段限速 37 英里」 / "Speed limit 37 mph". The screen reader says 「此路段限速每小時 60 公里」 / "Speed limit 60 kilometers per hour". **This is an exception to 06 C06**, which asked for 「點位資料速限」 wording. The user accepted the risk that 「此路段」 can be read as the road's legal limit when the camera data is wrong or old (L53, 01 A31). The camera icon carries the "speed camera" meaning and must never be removed.
- **Wrapping**: one line when it fits (Chinese at 844). Otherwise it breaks only between the phrase and `60 公里` / `60 km/h`; the icon stays at the start of line 1 and line 2 starts at the left. Never truncate, never shrink; at most 4 lines (R7-13).
- **Size and contrast**: text ≥15 px / ≥500; the limit number ≥16 px with ink height ≤ ¼ of the three-digit speed height (≤26 / ≤25). Number 15.38:1, text 10.86, unit 7.22, bar and icon 9.90 (R7-11, 02 §9.1).
- **Behavior**: nearby mode only, no distance, no color change on the speed (L8, L45). Appears and disappears with opacity only (≤200 ms; 0 ms with reduced motion), then stays still. The gauge, numeral and gear row never move (L31, R7-12). Not shown at all when the camera data is expired or known wrong (L16), when location is denied (L9), or outside Taiwan (L12).
- Unchosen alert styles (card / plain text / number column) and the round-7 wording are kept only as references in `gauge-variants.html` (L54).

## Parked screen
- **Left column**: the status line (◌ 等待車輛… / ◐ 藍牙中斷 / ◐ 藍牙資料過期 / ◐ 車輛休眠) is fixed at the top. Below it is a vertical scroll area, whose children never squash (R7-21), in this order:
  - the one-time tire notice card;
  - the trip rows (本趟 / 平均 / 最高 + 「由手機 GPS 計算」);
  - placeholders (「連接車輛後可顯示檔位與電量」, 「車況需要解鎖」, the trial-ended row).

  Placeholders may need scrolling at 844 (L56 Q46). Battery / range sits below the scroll area, in its reserved block.
- **First-time tire notice** (R7-16, R7-20, A30): 「胎壓僅供參考，請以車上的胎壓警示為準。」 + 「知道了」 (≥44 high) / "Tire pressure is for reference only. Rely on your car's tire pressure warnings." + "Got it". It is the first item in the left column, visible without scrolling at the default text size, not a dialog, and doesn't cover the speed. Shown until the user taps it.
- **Tire pressure** (only when 06 C03 passes; L42, L46, R7-14–R7-18):
  - **Diagram**: a top-down car, nose up. Each wheel shows only an integer `42 psi` or `—` in its own corner, with no leader lines, position names, per-wheel times or disclaimer. The unit is always psi.
  - **Freshness**: a reading is stale after 15 minutes, judged only from the car's measurement time. Only the stale wheels dim to `tire.stale`.
  - **Shared time line**: one line under the car, ≤2 lines, never dimmed, based on the oldest wheel, with "time unknown" winning. Texts: 「N 分鐘前」, 「部分讀值 N 小時前」, 「時間未知」, 「部分讀值時間未知」, and 「尚無讀值」 when all four are `—`.
  - **Not supported**: a car confirmed not to provide tire pressure shows only the title and 「這台車沒有提供胎壓資料」 (R6-08).
  - **List fallback**: if a reading is wider or taller than its slot, the time line needs a third line, or text touches the car, switch to the list layout. It names each position, and only the four rows scroll.
  - **Screen reader**: 「左前,42 psi」, 「右後,尚無讀值」 (never "—").
- **Ceramic car dimming** (R6-10, L49): the ceramic car SVG is drawn with a CSS/color filter `saturate(.12) brightness(.8)` by day and `brightness(.5)` at night; the tire SVG is not edited. Mean luminance of the car area: 0.109 day (≤ the glass car's 0.113), 0.052 night. At night only the car dims; tire text stays (L56 Q47; revisit after T03) (02 §9.2).
- **Tire disclaimers outside the panel** (A30, R8-01, L57):
  - In the S06 first-time notice (above).
  - As feature-list item 5 on S20–S22: 「停車時查看胎壓」 with small print 「僅供參考，請以車上的胎壓警示為準」. S21 lists it under 「你會失去」.
  - As the S25 「胎壓 / Tire pressure」 section: last reported reading, may not be current, rely on the car's warnings, 「—」 means no reading, the app does not judge normal or abnormal.

  All only when 06 C03 passes.

### Hardened states — resilience, not the happy path
The HUD's core promise is *trust the reading*, so every non-live condition must be unambiguous, never a silently stale number.
- **Source**: the chip always names the *current speed source* (● 車輛藍牙 / ● GPS / ◐ GPS · 藍牙資料過期 / ▲ 車速暫不可用). Car-data problems are told by the chip in drive and by the left-column status line in parked (L9).
- **Stale car data**: speed and gear never show last-known values. Parked battery shows its last value in `text.stale` (≥4.5:1) with its own 「12 分鐘前」 line. Tires dim per wheel with the shared time line. Never dim a whole area by opacity (L21, R7-15). In drive, battery shows `—% / — km` after its own 60 s window, and the block hides after Bluetooth has been lost for >10 s (01 §3.2, §7.4). Auto-parked returns to drive when P is no longer fresh (S04-i).
- **Waiting for the car**: ◌ 等待車輛…; battery `—% / — km`; tires `—` ×4 + 「尚無讀值」 (R6-08, R7-18).
- **No valid source**: minimal HUD with `—` + reason; no alert; no parked summary (L6, L9).
- **Charging (v1.x, not in v1; 01 A16)**: the battery readout becomes a charge status — `⚡ 48 kW`, `82% → 90%`, `約 25 分`.
- **Reduced motion**: every transition becomes instant.
- **Boundary checks**: `100% / 520 km` and mph values wrap to two lines inside the reserved block (`100%` / `520 km`, the line break replacing ` / `); battery `0–100%`; range up to `1,015 km` (R6-03).

## Information architecture & data phasing
Governing rule: **`drive` stays minimal.** On GPS fallback `drive` shows only the speed, the source chip and (in Taiwan) the speed-camera alert. Car-data elements need Car Bluetooth.

| Element | Source / Phase | State | Notes |
|---|---|---|---|
| Speed numeral | Car Bluetooth → GPS | drive + parked | hero; Bluetooth while valid, else GPS while valid, else `—` (L7) |
| Source chip | Car Bluetooth / GPS | drive + parked | `車輛藍牙` / `GPS` + shape mark; never hidden by any layout setting (L3, L9) |
| Gear `P R N D` | Car Bluetooth | drive + parked | rules in Gauge spec (L43) |
| Battery % / range | Car Bluetooth | drive + parked | bottom-left `72% / 315 km`; hidden on GPS-only or layout "speed only" (L33, L50) |
| Speed-camera alert (side bar) | phone GPS + NPA dataset 7320 | drive | Taiwan only, nearby mode (L8, L12, L52, L53) |
| Over-listed-limit amber + ▲ | same | drive | ahead mode only — v1 off (L8) |
| Trip distance / avg / max | phone GPS | parked | left column (01 §6.2) |
| Tire pressure (psi) | Car Bluetooth | parked | only if 06 C03 passes (L42) |
| Date / time pill | phone | parked | top center |
| Charging status | Car Bluetooth | parked, v1.x | (01 A16) |
| Power / regen bar | BLE* / OBD | v1.x | default off |
| 0–100 timer, energy Wh/km, telltales, temperatures, heading | — | deferred | not in v1 |

Source consequence: with **Car Bluetooth connected**, gear, battery, range and tires are available. On **GPS fallback** (not paired / Bluetooth dropped / car asleep) only speed and speed-derived trip stats show. The `DataSource` seam degrades the UI gracefully; `drive` stays minimal either way.

### Data-source reality (corrected 2026-06-07)
Earlier docs assumed battery/range/gear required the **Tesla Fleet API (cloud, billed, polling)** in Phase 2. That was wrong. Tesla's **native BLE** has two channels: **VCSEC** (lock/sleep/presence — pollable while asleep) and **Infotainment** (battery, range, gear `P R N D`, charging kW, TPMS, temp, odometer — available while the car is awake/active, i.e. always while driving). Shipping apps (e.g. DriveCluster) and community work (`esphome-tesla-ble`) read this **locally over BLE — no dongle, no cloud, no Tesla account, no developer fees**. So the chosen architecture (decided 2026-06-07) is **BLE-primary with a GPS speed-fallback** — not GPS-first, not BLE-only:

- **Primary — Tesla native BLE** (`TeslaBleSource`): the default source for *everything* — speed, battery, range, gear, charging, TPMS (possibly drive power). Local, near-real-time, free. Needs one-time key-pair enrollment into the car; protocol is community-reverse-engineered (Protobuf + ECDH/AES) → firmware-drift maintenance risk.
- **Fallback — GPS** (`GpsSource`): **speed only**, used when BLE is not paired / not connected / drops / the car is asleep. Zero auth/hardware — it guarantees a day-one experience and a safety net the reverse-engineered BLE path cannot. On GPS-only, battery/gear/tires are simply hidden.
- **Optional — Tesla Fleet API** (`TeslaFleetSource`): remote / away-from-car only (cloud, billed). Off the in-car path.
- **Power-user — OBD-II** (`ObdSource`): only the deepest data BLE can't give (cell temps, fine motor power). ~US$150–190 hardware, iOS MFi-limited.

A composite source coordinates them: **speed = Car Bluetooth while valid, else GPS while valid, else `—`. On cold start the first valid Bluetooth reading shows; switching back from GPS needs 2 distinct, in-order valid Bluetooth readings. Every other field = BLE only** (L7, 01 §3.3). The `DataSource` (`Stream<Reading>`) interface is the seam that keeps this swap invisible to the UI.

**Spikes before building:** (1) Flutter feasibility — `flutter_blue_plus` + porting Tesla's Protobuf/crypto BLE layer from the Go (`teslamotors/vehicle-command`) / Python (`python-tesla-fleet-api`) libs to Dart; (2) whether BLE speed is high-frequency enough (~5–10 Hz) for a smooth gauge and whether instantaneous *drive* power is exposed — if either fails, GPS covers speed and the power bar drops to OBD.

### New element specs
- **Trip rows (parked)**: three rows in the left column — 本趟 (km) · 平均 (km/h) · 最高 (km/h). Label `unit` 13/600, tracking 1; value `text.primary` 18/600 tabular; `divider` lines between rows. Note 「由手機 GPS 計算」 12 below (01 §6.2).
- **Power / regen bar (v1.x, default off)**: a thin vertical bar at the screen edge; placement to be designed when the feature is scheduled. Hidden on GPS-only.
- **0–100 timer, energy panel**: deferred; not in v1.

## Screen inventory
- Main design: `docs/design/frames/landscape-mockups.html` — 66 screens, PNGs in `docs/design/frames/landscape/` (export with `docs/design/frames/export-landscape.sh`) (02 §9).
- Comparison page with the chosen C gauge and side bar, plus every unchosen option kept for reference: `docs/design/frames/gauge-variants.html` (L54).
- Superseded references: round-5 mockups in `docs/design/frames/archive-r5/`; portrait mockups `docs/design/frames/stage2-mockups.html`; `.pen` frames D / D2 / D3 / E / F and A/B/C explorations (`.pen` sync is pending a user decision, L5).

## Component states (build all per the PRD)
- **Toggle**: off `surface.raised` + `card.border` outline, knob left / on `accent`, knob right — position differs, not only color.
- **Segmented**: active `accent.segActiveBg` + `accent.text`; inactive transparent + `text.inactive`.
- **Buttons**: primary `accent` fill + `bg.base` text; secondary `card.border` outline + `text.row`; text button `accent.text`; destructive `danger.text` + `danger.border`. Every interactive control needs default / pressed / disabled at minimum.
- **Hit areas**: iOS ≥44×44 pt, Android ≥48×48 dp, measured per target. The mockups use ≥48 everywhere (01 §7.3, R5-02).
- **Static list marks** (feature-list checks, checklist dots): `text.secondary`, never cyan (R8-02).
- **Scroll hints** never dim text: content below is clipped, not faded. Leave bottom padding so the last item clears fixed buttons (R5-04).

### Forms & flows (landscape)
- Title bar 56 fixed. Single-column content ≤600 wide; long text ≤540 (~36 CJK characters per line). The button row is fixed at the bottom, outside the home-indicator area: secondary left, primary right (01 §7.2).
- **Settings**: always two columns (group list ~190 + content); detail pages open in the right column. Single column only when the right column would be <360 pt or at accessibility text sizes (iOS AX1+ / Android ≥200%) (01 §11 Q31).
- **Confirmations**: centered dialog ≤460 wide, ≤80% height, buttons in one row (cancel left, primary right); no bottom sheets. **Exception — S07** over the HUD: a right-column panel (x 584–769, y 16–369), title + L20 text, two ≥48 buttons stacked at the bottom; it never widens left, so the gauge and source chip stay visible (01 §7.4).
- **Pairing and purchase**: two columns. Price and primary buttons stay fixed at the bottom right. Feature lists only name shipped features (06 C07).
- **VIN keyboard**: only the step, the VIN field (17 characters + counter), the inline error and Next stay above the keyboard (01 §7.2).
- **Large text**: settings, pairing and purchase scroll instead of shrinking. In the HUD the gauge stays fixed while the chip, alert, battery and parked left column grow. Parked: the left column scrolls and the tire panel may switch to its list layout (L19, L24).
