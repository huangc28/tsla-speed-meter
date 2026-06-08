---
target: D2b 橫 (drive landscape)
total_score: 27
p0_count: 0
p1_count: 1
timestamp: 2026-06-08T04-27-15Z
slug: design-index-html-d2b-landscape
---
# Critique — D2b 橫 (drive landscape, BLE + power bar)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Source chip present but collides with the gauge label |
| 2 | Match System / Real World | 4 | Gauge + gear + battery metaphors are clear |
| 3 | User Control and Freedom | 3 | n/a (glance display) |
| 4 | Consistency and Standards | 2 | Collision breaks the tidiness the portrait frames hold |
| 5 | Error Prevention | 3 | n/a |
| 6 | Recognition Rather Than Recall | 3 | Gear/battery labeled |
| 7 | Flexibility and Efficiency | 3 | Landscape itself is the efficiency win |
| 8 | Aesthetic and Minimalist Design | 1 | Top-left is clogged: chip + "100" + arc stacked in one corner |
| 9 | Error Recovery | 3 | n/a |
| 10 | Help and Documentation | 2 | n/a |
| **Total** | | **27/40** | **Good base, one glaring local defect** |

## Anti-Patterns Verdict

Deterministic scan: unavailable (bundled detector not present in this install; reported, not skipped).

LLM assessment: not AI-slop in concept — the left-hero / right-column split is a real landscape rethink, not a rotated portrait. The failure is execution: the gauge was dropped into the top-left corner where its own overflowing labels fight the corner chrome.

## Overall Impression

The layout idea is right; the placement is wrong. A 246px gauge with labels that overflow *above* its box was pushed to top:27 / left:37, directly under a status chip at top:22. The result: the speed-limit "100" label and the chip occupy the same pixels. Biggest opportunity: give the gauge breathing room from the corner (move it down/in or shrink it) so the upper-left stops being a pile-up.

## What's Working

- The two-zone split (gauge hero left, instrument column right) is the correct landscape model and reuses the portrait components cleanly.
- The power bar on the far-left edge is mirror-safe and stays peripheral.

## Priority Issues

- **[P1] Status chip overlaps the speed-limit label.** Measured: "100" label at x103–122 / y11–25 sits inside the chip box at x20–123 / y22–36. They literally overlap. This is the "clogged" top-left the user sees. *Why it matters:* trust-through-status depends on the chip being legible; a number colliding with "TESLA" reads as a glitch. *Fix:* move the gauge inboard and down (e.g. center it vertically and shift right) or scale it to ~210 so its labels clear the corner; alternatively drop the chip to a non-overlapping spot.
- **[P2] Gauge is crammed into the top edge.** Its label overflow reaches y11 (11px from the frame edge) while the chip is at y22. The whole upper-left quadrant is congested. *Fix:* the gauge needs ~40px of clearance from the top and left chrome.
- **[P2] Speed numeral sits ~11px above the gauge center.** The numeral box centers at y139 vs gauge center y150 (the unit label pushes the pair up). At a glance the big number looks high in the dial. *Fix:* anchor the numeral to the gauge center, not the frame center.
- **[P3] "+95 kW" caption is orphaned bottom-left.** It sits at y244, detached from everything, in an otherwise empty corner. *Fix:* tie it to the power bar (top or inline) so it reads as that bar's value.

## Persona Red Flags

**Driver (0.3s glance, dash-mounted):** the top-left pile-up forces a second look to parse "is that TESLA, or 100?" — exactly the hesitation a HUD must not cause.

**First-timer:** sees a number jammed against the status text and assumes the app is buggy before trusting the speed read.

## Minor Observations

- Right column content (gear + battery) is centered as a pair, which is fine, but the large empty lower-right makes the column feel unbalanced against the busy left.
- Gauge and chip share the corner only when the gauge renders a value/limit label — which is why D (parked, value 0, no label) looks clean and D2b does not.

## Questions to Consider

- Should the gauge be smaller in landscape so it never fights the corners, accepting a less dominant dial?
- Does the speed-limit "100" label belong at the top of the arc in landscape, or should it move where it has room?
