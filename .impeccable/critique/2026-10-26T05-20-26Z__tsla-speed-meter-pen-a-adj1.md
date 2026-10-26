---
target: A 雙翼 · 調整 1 (tsla-speed-meter.pen), ref Dashla
total_score: 24
max_score: 36
na_heuristics: 10
p0_count: 1
p1_count: 2
timestamp: 2026-10-26T05-20-26Z
slug: tsla-speed-meter-pen-a-adj1
---
Method: dual-agent (A: design review sub-agent · B: detector sub-agent). B's report reached the parent before A finished, so isolation was partial.

Target: direction A「雙翼」· 調整 1 in tsla-speed-meter.pen (board 「第十二輪 主畫面改版」), reference Dashla screenshot supplied by the owner.

## Design Health Score

| # | Heuristic | Score | Key issue |
|---|-----------|-------|-----------|
| 1 | Visibility of system status | 3 | Chip and captions are good. The ④ unknown door is unclear, and the ③ tire panel has no reading-age line. |
| 2 | Match system / real world | 3 | In ①/④ the note「距離和車速由手機 GPS 計算」mentions speed, but no speed row is shown. The nav "18分・12km" has no label. |
| 3 | User control and freedom | 3 | Locked in drive, ⌄ selectors when parked. Right for a HUD. |
| 4 | Consistency and standards | 2 | The numeral font drifted to Inter, units are no longer smaller, the unknown door breaks L71, and icon viewpoints are mixed. |
| 5 | Error prevention | 2 | A solid gray door reads as "open". The mirrored 12.4km/12km and 0:18/18分 formats invite confusion. Units are clipped. |
| 6 | Recognition rather than recall | 3 | Captions use words. A caption is split from its icon by the ring stroke. |
| 7 | Flexibility and efficiency | 3 | Custom threshold, and the panel chosen while parked carries into drive. |
| 8 | Aesthetic and minimalist design | 2 | About 17 elements in ①. The ring, the brightest non-data element, carries no data. |
| 9 | Error recovery | 3 | 「藍牙資料過期」names the problem and drops car data with no leftover old values. |
| 10 | Help and documentation | n/a | A glance HUD carries no help. |
| **Total** | | **24/36** | **Good (67%, at the Acceptable/Good edge)** |

## Design Specificity Verdict

The rules are product-specific: the shape+word source chip, honest degradation on GPS, and the gear shown by weight and underline. The 調整 1 surface drifted generic. With no needle or arc, a bright full circle around a numeral is the stock "speedometer app" composition. It copied Dashla's shape, not its tone: Dashla's ring is a hairline at about 1.5:1 on a darker disc.

**Deterministic scan:** 90 hits on the Pen export, 4 on main-redesign.html. All are `overused-font` (Inter), which is one decision counted many times. Inter is pinned by DESIGN.md (L15), so the detection is real but kept by the brief.

**The key cross-finding:** the Pen export has no Barlow Semi Condensed at all. The import silently swapped the numeral, unit and P R N D to Inter. It also merged value and unit into one size, and dropped the dashed unknown-door outline and the hollow page dots. 原稿 and 調整 1 in the .pen are therefore lossy copies of the HTML source.

## Priority Issues

- **[P0] The unknown door lost its dashed mark (④).** The shape says "open", against L71/S12-06. Fix: restore the dashed outline. Suggested command: harden.
- **[P1] Type regression from the import.** The numeral, km/h and P R N D are in Inter instead of Barlow Semi Condensed. Values and units are merged, and "12.4km" and "64%" clip. Fix: restore Barlow (152/-6 for three digits, 176/-1 for one or two, unit 23/500 tracking 2), split the units, and use hug-width frames. Suggested command: typeset.
- **[P1] Drive density.** ①/④ show the top time, both wings and the status row. The label/value tables are flat. Fix: Dashla's label-above-value pattern, with fewer and larger values and a quieter title. Suggested command: distill + layout.
- **[P2] Status cluster semantics.** The icons sit inside the ring with captions outside, the stroke runs between them, and the ② 110 tick marks a scale that no longer exists. Fix: put each icon and its word inline below the ring, and drop the tick. Suggested command: clarify.
- **[P2] The ring is the loudest non-data element** (#CFD3D9, 11.35:1). The night numeral #C0C2C4 is darker than the ring. Fix: keep the owner's day color, but add a dark inner disc and specify a night ring value darker than the night numeral. Suggested command: quieter.

## Persona Red Flags

- **Driver glancing (Casey):** the status captions at y≈360 need a second fixation. Five white bold secondary values compete for the second glance.
- **Low vision / colour-blind (Sam):** the ④ door differs from "open" only by luminance. Units clip. The ③ hollow page dot is 1.8:1.
- **Stress tester (Riley):**
  - Long destination names have no truncation rule.
  - The camera alert borrows the right wing.
  - The case with every status at once is not drawn, and neither is "—" with the full ring.
- **Model 3/Y owner, night and glare:** the bright ring outshines the night numeral. The nav wing repeats the car's center screen.

## Minor Observations

- ③: the reading-age line required by DESIGN.md is missing.
- P R N D cells are 18 pt, against Dashla's ~34; 26 pt reads closer.
- The trunk icon is a side view and the door is top-down.
- Removing the needle makes L62 / #47 moot for A. This needs a ruling.

## Questions to Consider

1. With no needle or arc, is the ring an instrument or just a frame?
2. If the ring holds no data, why is it the second-brightest thing on screen?
3. Is "雙翼" worth two wings in drive when the car's own screen already shows nav?

## Applied in 調整 2 (owner said "finish and report")

- **Restored from the source:** Barlow numeral, unit and gear; split value/unit; dashed unknown door (image crop); hollow page dots.
- **Dashla moves:**
  - a dark disc #0F1013 inside the owner's #CFD3D9 2 px ring;
  - gear cells widened to 26 pt;
  - drive wings as label-above-value: values 24/600, labels 13/600 #A6ACB5, title 14/600 #CDD2D9;
  - both wings top-aligned at y 84.
- **Status:** each icon and its word inline below the ring. The ② 110 tick was removed, departing from L73 S12-08 because the scale it marked is gone.
- **Copy:** the drive note became「距離由手機 GPS 計算」. The nav row got the label「剩餘」.
- **③:** a shared time line「3 分鐘前」. The page dots were raised above the panel.
- **Kept per brief:** the top time and the owner's ring color.
- **Detector on 調整 2:** only `overused-font` (Inter, pinned).
