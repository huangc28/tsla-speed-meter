---
target: D2 行駛模式
total_score: 33
p0_count: 0
p1_count: 0
timestamp: 2026-06-05T15-53-57Z
slug: design-index-html-d2-drive-mode
---
# Critique — D2 Drive Mode v2 (design/index.html)

Register: product. Re-critique after redesign (ticks + crimson current marker + speed-limit/over-speed + refined battery). Detector unavailable (bundled detector not found); browser visual evidence at 1400px. Independence degraded (sequential).

## Heuristic scores
1 Visibility 4 · 2 Match 4 · 3 Control 3 · 4 Consistency 4 · 5 ErrorPrev 4 · 6 Recognition 4 · 7 Flexibility 4 · 8 Aesthetic 3 · 9 Recovery 3 · 10 Help n/a. Total ~33/40 (up from 29).

## Anti-patterns verdict
- Category reflex largely escaped: crimson current marker, arc ticks, and over-speed warm shift make it recognizably this product, not a generic GPS speedo.
- Hero-metric template concern reduced: battery is now a real component, not a supporting-stat caption.
- Deterministic scan unavailable. Visual: clean, no breakage; limit and current markers sit close at the rim.

## Strengths
1. Over-speed is actively visualized (amber number + amber over-arc + limit marker) -> directly serves the core pain point and the trust/error-prevention principles.
2. Battery is a clear, refined EV-appropriate component (capsule fill + % + range).
3. Signature instrument motifs (crimson current marker, ticks) give it identity.

## Priority issues
- [P2] Amber overload in over-speed state: number + over-arc + limit label all amber, plus crimson marker. Redundant amber competes. Keep the number as the warning hero; neutralize the limit marker/label. -> quieter/colorize
- [P2] Limit (100) and current (120) markers sit close at the rim; near the limit they collide. Differentiate (limit outside, current inside) or enforce min separation. -> layout
- [P3] No visible "tap to parked / mode" affordance (carried from v1). -> onboard/clarify
- [P3] Demo shows only the over-speed state; calm under-limit default (white number, all-cyan) not verified. Add a normal-speed variant for coverage.
- Minor: battery has no low-charge (amber) state shown; add state coverage.

## Cognitive load
Slightly higher (more rim elements) but purposeful; number still dominates. Acceptable.

## Trend
29 -> 33.
