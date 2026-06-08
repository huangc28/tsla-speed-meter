---
target: D2b 橫 (drive landscape)
total_score: 33
p0_count: 0
p1_count: 0
timestamp: 2026-06-08T04-45-24Z
slug: design-index-html-d2b-landscape
---
# Critique — D2b 橫 (drive landscape, BLE + power bar) — run 2 (post-fix)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Source chip now clean and legible |
| 2 | Match System / Real World | 4 | Gauge + gear + battery metaphors clear |
| 3 | User Control and Freedom | 3 | n/a (glance display) |
| 4 | Consistency and Standards | 4 | Reuses portrait components, aligned to dial center |
| 5 | Error Prevention | 3 | n/a |
| 6 | Recognition Rather Than Recall | 4 | Gear/battery labeled |
| 7 | Flexibility and Efficiency | 3 | Landscape is the efficiency win |
| 8 | Aesthetic and Minimalist Design | 3 | Clean now, but composition is left-heavy with an empty right third |
| 9 | Error Recovery | 3 | n/a |
| 10 | Help and Documentation | 2 | n/a |
| **Total** | | **33/40** | **Very good; the remaining issue is balance, not collision** |

## Anti-Patterns Verdict

Deterministic scan: unavailable (bundled detector not present in this install; reported, not skipped).

LLM assessment: Not AI-slop. The previous top-left pile-up is gone. The gauge/chip/label now hold clear separation, the numeral is anchored to the dial, and the power-bar caption reads as the bar's value. What remains is a composition problem, not a defect.

## Overall Impression

The frame went from broken to clean. The collision is fully resolved (chip ends y36, limit label starts y45). The one thing a design director still catches: all the visual mass lives in the left 55% (gauge + gear + battery clustered together), and the right ~40% is empty except the settings cog. The layout is balanced top-to-bottom but lopsided left-to-right.

## What's Working

- Top-left is now legible: `已連線 · TESLA` and the `100` limit label are cleanly separated.
- The gauge is correctly sized for the short frame, numeral centered on the dial, power bar centered and captioned. All the run-1 P1/P2/P3 items are resolved.
- Genuine landscape model preserved: gauge hero left, instrument data right.

## Priority Issues

- **[P2] Left-heavy composition / empty right third.** Measured: gear and battery render in a 342px-wide column (x286–628) but their content is left-aligned, hugging the gauge; everything sits in x48–410, leaving x410–650 empty. For an instrument-grade brand, an unbalanced frame reads as unfinished. *Fix:* bracket the composition. Either anchor the secondary data toward the right edge (gauge left, data right, center breathes) or, since drive carries so little, center the gauge and tuck gear/battery into a tight right gutter. `layout` is the right tool.
- **[P3] Numeral sits ~10px above the dial center.** Speed box centers at y153 vs gauge center y163; the `km/h` unit pushes the pair up. Barely perceptible, but on a precision gauge it's the kind of half-pixel that separates good from great. *Fix:* nudge the readout down ~8px or anchor the numeral (not the numeral+unit pair) to the dial center.

## Persona Red Flags

**Driver (0.3s glance):** no longer forced into a double-take; the speed reads instantly. Clean.

**First-timer:** the empty right third may read as "is something missing here?" on first encounter, though it won't block use.

## Minor Observations

- Drive is intentionally minimal, so sparseness is fine; the issue is distribution, not amount. The same right column carries four rows in parked (D橫), so the wide column is justified there but looks empty in drive.
- `+95 kW` now sits directly under the power bar and reads as its value. Good.

## Questions to Consider

- Should the secondary data bracket the gauge from the right edge, or should the gauge move toward center and the data tuck beside it?
- Does drive landscape want anything more in that right space (a peripheral trip readout?), or is committed minimalism the stronger statement?
