---
target: D2 行駛模式
total_score: 29
p0_count: 0
p1_count: 2
timestamp: 2026-06-05T15-44-04Z
slug: design-index-html-d2-drive-mode
---
# Critique — D2 Drive Mode (design/index.html)

Register: product. Target: drive-mode screen. Assessment B detector unavailable (bundled detector not found); browser visual evidence only at 1400px and 440px. Independence: degraded (sequential, no sub-agents).

## Heuristic scores
1 Visibility 3 · 2 Match 4 · 3 Control 3 · 4 Consistency 3 · 5 ErrorPrev 3 · 6 Recognition 3 · 7 Flexibility 3 · 8 Aesthetic 3 · 9 Recovery 3 · 10 Help n/a. Total ~29/40 (Good).

## Anti-patterns verdict
- Approaches the hero-metric template ban: big number + small unit + supporting stats (battery line "82% · 312 km").
- First-order category reflex: dark + big number + cyan arc reads as a generic GPS speedometer app. The product's distinctive instrument identity lives only in the parked cluster (D), but drive (D2) is the 95%-of-the-time screen.
- Deterministic scan unavailable. Visual: no layout breakage; arc tip dot collides with the "1" glyph.

## Strengths
1. Hierarchy: "120" is unmistakably dominant (glanceable above all).
2. Trust: GPS status uses color + label (color-blind safe).
3. Restrained color: single cyan accent on tinted dark, on-strategy.

## Priority issues
- [P1] Drive is the most generic screen (category reflex). Carry one signature cluster motif into drive (major ticks on the arc / crimson tip / hairline value marker). -> craft/colorize
- [P1] Battery line is glance noise and the hero-metric tail; remove battery in drive mode or shrink to a corner chip. -> distill
- [P2] No speed-limit / over-speed affordance, which is the core pain point. Add a limit marker or warm color shift past the limit. -> craft/colorize
- [P2] "km/h" too large/bright (20px), competes with the number; reduce. -> typeset
- [P3] Arc tip dot collides with numerals at high values; shrink arc radius or raise readout. -> layout

## Persona red flags
- Driver-in-motion: only "120" reads; battery line and unit are sub-glance noise.
- First-timer: no hint that tap -> parked cluster, or how to change units.

## Cognitive load
Low; 4 zones; number dominates; battery is the removable one.
