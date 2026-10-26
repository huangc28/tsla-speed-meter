---
target: A 雙翼 · 調整 2 (main-redesign-a2.html, HTML master)
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
timestamp: 2026-10-26T06-01-06Z
slug: docs-design-frames-main-redesign-a2-html
---
Method: dual-agent (A: critique-a-design · B: critique-b-detector). B's report reached the parent before A finished; A never saw B, and the synthesis was written after both were in.

Target: `docs/design/frames/main-redesign-a2.html`, direction A「雙翼」· 調整 2 ported from the .pen to the HTML master (L5). Four screens ① drive BLE, ② drive GPS over 110, ③ parked, ④ trunk open + door unknown. Compared against the Pen critique of 2026-10-26T05-20-26Z (調整 1, 24/36).

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 3 | Chip and tire time line are good; the unknown door has no word, and over-threshold is one 15 px line at the bottom edge. |
| 2 | Match system / real world | 3 | Plain labels; a needle-less dial has a dial's shape without its meaning. |
| 3 | User control and freedom | 3 | Nothing traps; panel switching in drive is not drawn. |
| 4 | Consistency and standards | 3 | Trip data has two layouts (drive vs parked); ring and disc are raw hex outside the tokens. |
| 5 | Error prevention | 3 | `—` not 0, dashed no-data ring, hysteresis inherited; new hole: forecast 64% outranks live 72%. |
| 6 | Recognition rather than recall | 3 | At 0.3 s the 13 px labels don't register; each value's meaning comes from its slot. |
| 7 | Flexibility and efficiency | 3 | Custom threshold, swappable parked panels, one-time auto-switch to navigation. |
| 8 | Aesthetic and minimalist design | 2 | Drive carries trip time, a footnote and two forecasts in the numeral's color (~15 elements in ①/④). |
| 9 | Error recovery | 3 | Fallback is named and recovers by itself; unknown gives no diagnosis. |
| 10 | Help and documentation | 2 | Provenance notes help; the dashed glyph and vertical paging have no hint. |
| **Total** | | **28/40** | **Good (bottom of the band)** |

Not like-for-like with the 05-20 Pen run (that one scored #10 n/a, 24/36).

## Design Specificity Verdict

Split. The frame (thin pale ring, dark disc, big numeral, label-over-value flanks) is the smartwatch / Dashla default; with arc, needle and ticks gone the ring carries no information and is the most prominent stroke on screen. The dark disc does real work (darkest spot under the hero, 17.7:1). Authored parts sit around the frame: Barlow `P R N D`, the trunk silhouette, the shape+word source chip, GPS-provenance notes, the tire car with 「3 分鐘前」, arrival battery from the car's navigation.

Deterministic scan: CLI exit 2, 4 × `overused-font` (Inter; lines 12, 117, 127, 161) — false positive, DESIGN.md pins Inter for UI Latin (L15). Browser (headless puppeteer fallback; chrome-devtools profile was locked by another session): `flat-type-hierarchy` (false positive: the 152/176 px numeral is SVG text the detector cannot see), `side-tab` on `.al.rule::before` (false positive: DESIGN.md requires the 3 px camera-alert bar; not on these screens), 11 × `ai-color-palette` on parked (false positive: `accent.text` on tappable panel titles; pager dots render neutral), 11 × `line-length` (review-page prose, not HUD), 1 × `cramped-padding` on 「本趟電量變化」 row (real but inherited from A 原稿's 28 px tight rows, already parked for S12-07). Page self-check: 0 issues at 1280/1440/390.

## Priority Issues

- **[P1] Status row overflow and gauge-box intrusion.** `.srow` is fixed 300 wide, nowrap, no 13 px fallback. Frunk + trunk + door + threshold ≈ 470 pt; centered at x 422 it runs into 「72% / 315 km」. Top at y 345 enters the 300×300 box by 5 pt (L35). The trunk item shifts 19 pt left when the unknown door is added. Fix: fixed slot per part, join open parts into one phrase (as 原稿's 「後車廂、車門開著」), 13 px fallback, cap at 300, start at y ≥ 350 or shrink icons to fit. Command: harden, then layout.
- **[P1] Look-alike numbers in drive.** Forecast 「64 %」 (24/600 primary) outshines live 「72% / 315 km」 (17/500 secondary); 「12 km」 remaining faces 「12.4 km」 trip across the ring; the 13 px labels are the first thing lost in a glance. Fix: wing values in text.secondary, drop 行駛時間 and the footnote from drive, bind labels inline (「抵達 64%」). Command: distill, then clarify.
- **[P1] Night preset never reaches the gauge.** `gA2` hard-codes ring #CFD3D9 and disc; at night the numeral is #C0C2C4, darker than the ring, and a full bright circle is the likeliest shape to reflect in the windshield. Collides with the owner's no-dimming pin: owner decides (a) raise the night numeral above the ring or (b) accept the ring as brightest and record it. Draw and measure a night frame first. Command: harden.
- **[P2] Unknown shown by shape only.** The dashed door (1.5 px dashes, #8E949C) vanishes in glare and has no word, against "state is never color-only / always a word". Fix: add 「車門未知」 in text.secondary 13/600. Command: clarify.
- **[P2] Custom threshold is the quietest alert.** 「超過 110（自訂）」 has the same weight as 「後車廂開著」. L73 bans color, camera, sign and ▲, not shape. Fix: while over, let the ring change shape (2 → 5 px or a second concentric ring), neutral and still. Command: bolder.

## Closed since the Pen 調整 1 critique (05-20)

- P0 unknown door solid → dashed again (but see P2: still no word).
- P1 type regression (Inter numeral, merged units, clipped 12.4km/64%) → closed: Barlow tnum numeral identical to gC, units split.
- P2 status cluster split by the ring stroke and orphan 110 tick → closed (inline row, tick removed), replaced by the new overflow P1.
- Minor: tire reading-age line → added 「3 分鐘前」; P R N D cell 18 → 26.
- Still open: drive density (now P1 look-alike numbers) and night ring brighter than numeral (now P1).

## Persona Red Flags

- **Casey (phone on the dash):** reads 112; the next-biggest white numbers are 64 and 12. Parked paging relies on 4 px dots and a ⌄ that promises a dropdown.
- **Sam (low vision / VoiceOver):** aria labels good; wing text ignores the large-text setting (no `--as`) and would clip (nowrap + overflow hidden). Unknown glyph invisible.
- **Riley (stress tester):** four open parts + threshold collide with the battery line; a long destination is cut with an ellipsis.
- **Night-highway driver:** ring outshines the numeral; wing values glow at the numeral's level.
- **Model Y owner in midday glare:** labels and the 2 px ring wash out first, leaving bare numbers; dashed door and threshold line disappear.

## Minor Observations

- Wings are lopsided: the right wing starts 22 pt from the ring, the left content ends ~80 pt away.
- The threshold icon draws a needle-and-tick gauge the HUD no longer has.
- #CFD3D9 and #0F1013 need tokens with night and high-contrast values; P R N D 26 and wing value 24 differ from DESIGN.md (18 / 18).
- Shared tire time line for fresh readings differs from the shipped code (only stale) — DESIGN.md wording allows either; record the decision.
- SwiftUI handoff: SF Symbols instead of Lucide; map the large-text setting to Dynamic Type.

## Questions to Consider

- If the ring must stay bright, what one thing should it mean?
- Besides the numeral, the threshold and the trunk, what earns a place in drive?
- Is it still 「雙翼」 when every GPS drive leaves the right wing empty?
