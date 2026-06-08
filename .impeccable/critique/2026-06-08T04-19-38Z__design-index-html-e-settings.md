---
target: E settings panel
total_score: 31
p0_count: 0
p1_count: 2
timestamp: 2026-06-08T04-19-38Z
slug: design-index-html-e-settings
---
# Critique — E · Settings panel (`design/index.html` → `screen-settings`)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Live-apply settings show current state via controls; no per-change confirmation, but acceptable for a settings list |
| 2 | Match System / Real World | 4 | Plain Chinese labels, standard chevron-back, km/h↔mph and 自動/日/夜 read naturally |
| 3 | User Control and Freedom | 3 | Back chevron present, all settings reversible; chevron is small and unlabeled |
| 4 | Consistency and Standards | 3 | Toggle vs segmented split is principled; swatch picker introduces a third control vocabulary |
| 5 | Error Prevention | 3 | Low-risk, all reversible, no destructive paths |
| 6 | Recognition Rather Than Recall | 3 | All options visible; active accent swatch is barely distinguishable |
| 7 | Flexibility and Efficiency | 3 | Fine for a mobile settings list; touch targets undersized for in-car use |
| 8 | Aesthetic and Minimalist Design | 4 | Clean, restrained, on-brand; genuinely native-feeling |
| 9 | Error Recovery | 3 | No error states possible here (n/a, scored neutrally) |
| 10 | Help and Documentation | 2 | One privacy hint only; terse settings get no explanation |
| **Total** | | **31/40** | **Good — solid foundation, fix the in-car ergonomics + color-only state** |

## Anti-Patterns Verdict

**LLM assessment:** This does **not** read as AI slop. It passes the product slop test: a user fluent in Linear/Stripe/iOS Settings would sit down and trust it. None of the tells are present — no gradient text, no glass, no card grid, no hero-metric template, no invented affordances. The toggle/segmented/swatch vocabulary is standard, the dark blue-tinted palette is consistent with the rest of the cluster, and the privacy hint at the bottom is a thoughtful, human touch. The weaknesses here are **functional**, not strangeness.

**Deterministic scan:** Unavailable. `detect.mjs` reported `bundled detector not found` (genuine failure after a real attempt), so the automated markup scan did not run.

**Visual overlays:** Not available. The chrome-devtools browser is profile-locked by an already-running Chrome instance, so no live page/overlay could be presented. Assessment is from full source.

## Overall Impression

A tasteful, restrained settings list that fits the instrument-grade brand. The biggest gap is that it was designed like a *phone* settings screen, not a *car* settings screen: the controls are small and edge-packed, and the one place state is communicated by color alone (accent picker) is exactly where PRODUCT.md says never to. Single biggest opportunity: make the controls in-car-sized and make selection legible without color.

## What's Working

1. **Principled control split.** Binary settings (mirror, auto-minimal, keep-screen-on) use toggles; enumerations (units, brightness) use segmented controls. That's the correct, learnable mapping, not random variety.
2. **On-brand restraint.** Tinted-neutral dark surface, cyan only on active states, 16px row labels, consistent dividers. It reads as one product with the gauge screens.
3. **The privacy hint.** "定位僅用於在裝置上計算車速,不上傳、不追蹤" is the right reassurance at the right place. Builds trust, which is core to this product.

## Priority Issues

**[P1] Touch targets are below the in-car minimum**
- **Why it matters:** PRODUCT.md makes "large, forgiving touch targets (the user is in a car, possibly moving)" a first-class principle. The toggle is 48×28px, the accent swatches are 30×30px, and the segmented options are ~28px tall — all under the 44pt floor, and all packed against the right edge where a thumb is least accurate. Settings get adjusted at red lights and while propped on the dash; small targets mean mis-taps in motion.
- **Fix:** Raise controls to ≥44pt hit area (swatches to 44×44 with the dot inside, toggle height to ~32 with a 44pt row hit zone, segmented options to ~40pt tall). Make the full row tappable for toggles, not just the knob.
- **Suggested command:** `/impeccable adapt` (then `/impeccable harden`)

**[P1] Accent selection is signaled by color alone**
- **Why it matters:** The active swatch is a 2px border in the *same hue* as the fill (`border-color: active ? c : transparent`), so "cyan is selected" is a faint cyan ring around a cyan dot — nearly invisible, and there are no labels. This fails PRODUCT.md's explicit "do not rely on color alone for state (color-blind safe)" rule, and it's weak even for full-sighted users glancing.
- **Fix:** Add a non-color selected indicator (checkmark inside the active swatch, or a neutral high-contrast ring + a text label per color). Pair each swatch with its name.
- **Suggested command:** `/impeccable colorize` or `/impeccable clarify`

**[P2] Flat list of six unrelated settings, no grouping**
- **Why it matters:** Units, mirror, auto-minimal, brightness, keep-on, and accent are three different concerns (behavior, display, appearance) rendered at identical visual weight with no section breaks. Cognitive-load chunking fails (>4 in one group, no grouping). Scanning for the one setting you want takes longer than it should.
- **Fix:** Group into 2–3 labeled sections (e.g. 顯示 / 行為 / 外觀) with quiet section headers. Keep it to ≤4 rows per group.
- **Suggested command:** `/impeccable layout`

**[P2] Terse labels with no supporting description**
- **Why it matters:** "行駛自動切換極簡" and "螢幕恆亮" assume the user already knows what they change. A first-time driver can't predict the behavior before toggling, and the Help heuristic is the weakest score (2). The lone privacy hint covers only location.
- **Fix:** Add a one-line secondary description under settings whose effect isn't self-evident (especially auto-minimal). Keep it `text-dim`, small, so density stays low.
- **Suggested command:** `/impeccable clarify`

**[P3] Back affordance is a small unlabeled icon at the top**
- **Why it matters:** The 24px chevron at the top-left is the only way out, it's an undersized target, and top-of-screen is the hardest reach one-handed. Standard pattern, but under-built for this context.
- **Fix:** Enlarge the back hit area to ≥44pt; consider a labeled "完成/Done" given settings apply live.
- **Suggested command:** `/impeccable adapt`

## Persona Red Flags

**Sam (Accessibility-Dependent):** The accent picker conveys selection by color alone — a screen-reader/low-vision user cannot tell which is active, and swatches have no text labels. Several controls fall below the 44pt target. No visible focus indicators are defined for keyboard/switch access. Contrast of `text-dim` hint (#5a6675) on the dark surface is borderline for body text.

**Casey (Distracted, in-car, one-handed):** Every control sits at the top/right of the screen — the worst zone for a thumb on a dash-propped phone. Targets are small and tightly stacked at the right edge. This is precisely the "important actions at the top, tiny tap targets" red flag, made sharper because the user may be glancing while stopped in traffic.

**In-car first-timer (project persona — Tesla driver setting up the HUD):** Lands on six terse rows with no explanation of "auto-switch to minimal while driving." Toggles all read ON with no hint of what OFF does. Will toggle things to discover behavior rather than understanding before acting.

## Minor Observations

- The privacy hint floats — it reassures about location use, but there's no location/GPS row near it to anchor the statement.
- All toggles render ON in the preview; confirm the OFF visual (it exists in CSS) is checked on a real device for contrast of the `--unit` knob on `--surface-raised`.
- Brightness as 自動/日/夜 segmented is a good call and aligns with day/night being a first-class product concern.
- Header pairs chevron + "設定" so current location is clear; that's good even though the icon is unlabeled.

## Questions to Consider

- What would this look like if it were designed for a thumb reaching up from the bottom of a dash-mounted phone, rather than a hand holding the phone normally?
- Should the most-used in-car toggles (mirror, brightness) be reachable without opening full Settings at all?
- Does the accent picker need to exist in v1, or is it decoration competing with the few settings that actually matter while driving?
