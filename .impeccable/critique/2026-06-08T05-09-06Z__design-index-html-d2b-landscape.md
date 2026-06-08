---
target: D2b 橫 (drive landscape)
total_score: 31
p0_count: 0
p1_count: 1
timestamp: 2026-06-08T05-09-06Z
slug: design-index-html-d2b-landscape
---
# Critique — D2b 橫 (drive landscape) — run 3 ("still feels weird")

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Chip clean |
| 2 | Match System / Real World | 4 | Metaphors clear |
| 3 | User Control and Freedom | 3 | n/a |
| 4 | Consistency and Standards | 3 | Scatter is inconsistent with the tight portrait drive |
| 5 | Error Prevention | 3 | n/a |
| 6 | Recognition Rather Than Recall | 4 | Labeled |
| 7 | Flexibility and Efficiency | 3 | n/a |
| 8 | Aesthetic and Minimalist Design | 2 | Two-island scatter, cramped left gauge, dead center |
| 9 | Error Recovery | 3 | n/a |
| 10 | Help and Documentation | 2 | n/a |
| **Total** | | **31/40** | **Number undersells it; the composition genuinely feels wrong** |

## Anti-Patterns Verdict

Deterministic scan: unavailable (bundled detector not present; reported, not skipped).

LLM assessment: This is on me. My run-2 "bracket to the right edge" recommendation traded one problem for a worse-feeling one. Pushing the data to the far edge turned a left-heavy frame into two disconnected islands with a dead center. The score barely moved (33 to 31) but the *feel* regressed, which is exactly what the user is reporting.

## Overall Impression — why it feels weird

Three things, seen only at full zoom:

1. **Two disconnected islands.** The gauge sits in the far-left third; gear + battery sit pinned to the far-right edge; the entire middle 40% is empty. The eye has no single place to land. There is no focal hierarchy, just two clusters flung to opposite edges.
2. **The hero is not central.** For a speed HUD the one rule is that the speed commands the glance. Here `64` is shoved into the left third while the right side and the whole center sit empty. The most important element is off in a corner.
3. **The gauge is cramped and the numeral bursts its ring.** The dial is jammed against the left edge / power bar, and the `64` at 86px nearly touches the arc on both sides, so the number looks like it is overflowing the dial.

The root cause is structural: **the left-hero / right-data split is wrong for drive.** That split earns its keep in *parked*, which has four rows of data to fill the right column. Drive has two thin items (gear, battery), far too light to balance a 210px gauge across a 224px gap. Forcing the split scatters a minimal screen.

## What's Working

- Status chip, legibility, component reuse, and the power-bar caption are all fine. The problem is purely composition.

## Priority Issues

- **[P1] Scattered, off-center composition.** Gauge far-left, data far-right, dead center, hero not central. *Fix:* abandon the split for drive. Center the speed as the singular hero (gear above it, battery below, exactly like portrait drive), with the power bar at the left edge and calm symmetric margins. Drive is minimal, so a dominant centered dial is the honest, confident answer; the two-zone landscape split should be reserved for parked.
- **[P2] Numeral overflows the dial.** `64` at 86px is too wide for the 210 ring. *Fix:* once centered, size the numeral to sit comfortably inside the arc (or enlarge the dial). The number should read as held by the dial, not escaping it.
- **[P3] Gauge crammed against the left edge / power bar.** Only ~28px between the power bar and the arc. *Fix:* re-centering resolves this automatically.

## Persona Red Flags

**Driver (0.3s glance):** the eye lands on empty center first, then hunts left for the speed. A HUD must put the number where the glance already goes: the middle.

## Minor Observations

- Parked (D橫) does NOT have this problem, because its right column is full. Whatever we change for drive should not touch parked.

## Questions to Consider

- Is the two-zone split worth keeping for drive at all, or is a centered hero simply the right answer for such a minimal screen?
- Should landscape drive read as "portrait, widened" (centered, consistent) rather than a bespoke landscape layout?
