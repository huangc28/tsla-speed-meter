---
target: E settings panel
total_score: 35
p0_count: 0
p1_count: 0
timestamp: 2026-06-08T04-45-05Z
slug: design-index-html-e-settings
---
# Critique — E · Settings panel (`design/index.html` → `screen-settings`) — post-polish

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Live-apply, clear active states (toggle/segmented/swatch check); no explicit confirmation, which is fine here |
| 2 | Match System / Real World | 4 | 顯示/行為/外觀 sections and 青/琥珀/靛 color names read naturally |
| 3 | User Control and Freedom | 4 | Real 44pt back button (`role=button`, `aria-label`), everything reversible |
| 4 | Consistency and Standards | 4 | Toggle/segmented/swatch each consistent; roles applied uniformly |
| 5 | Error Prevention | 3 | Low-risk, all reversible, no destructive paths |
| 6 | Recognition Rather Than Recall | 4 | Active accent unmistakable (ring + check + label); descriptions remove guessing |
| 7 | Flexibility and Efficiency | 3 | In-car targets fixed; focus-visible added; no shortcuts (n/a for this surface) |
| 8 | Aesthetic and Minimalist Design | 4 | Grouping adds structure without clutter; descriptions are purposeful |
| 9 | Error Recovery | 3 | No error states possible here (scored neutrally) |
| 10 | Help and Documentation | 3 | Inline descriptions + privacy hint; no searchable/contextual help beyond that |
| **Total** | | **35/40** | **Good (top of band) — only polish-level items remain** |

## Anti-Patterns Verdict

**LLM assessment:** Still not AI slop, and now stronger. The grouped sections and labeled swatches read like a considered native settings screen, not a generated list. No banned patterns. The control vocabulary (toggle for binary, segmented for enum, labeled swatch for accent) is exactly what a category-fluent user expects, and the inline descriptions give it a human, explanatory voice.

**Deterministic scan:** Unavailable. `detect.mjs` again returned `bundled detector not found` (real attempt, genuine failure). No automated markup scan this run either.

**Visual overlays:** Not available. chrome-devtools is still profile-locked by a running Chrome; no live page/overlay. Assessment from full source.

## Overall Impression

The polish closed both P1s and both P2s. This now reads as an in-car-aware settings screen: thumb-sized targets, selection you can read without color, grouped concerns, and one-line explanations where behavior wasn't obvious. The remaining items are genuine polish, not UX gaps. Biggest residual: a borderline-contrast nit on the smallest text and a couple of structural nits worth a quick pass.

## What's Working

1. **Selection is now color-blind safe.** The active accent swatch carries a neutral white ring, an inset check, and a brightened label, three redundant signals, none hue-dependent. This was the sharpest a11y violation and it is fully resolved.
2. **In-car ergonomics.** Toggle rows are tappable as a whole (`role="switch"` on the 56px row), segmented options are ~36pt, swatches sit in 44px columns. The thumb has room now.
3. **Explanatory voice.** "行駛時自動隱藏次要資訊,只留車速" under the auto-minimal toggle is exactly the right amount of help, present only where behavior isn't self-evident, absent on units/brightness where it would be noise.

## Priority Issues

**[P3] Smallest text sits at borderline AA contrast**
- **Why it matters:** The 12px descriptions and the privacy hint use `--text-tertiary` (#6e7e8c). On the lighter center of the screen's radial gradient (#101b2e) that lands around 4.2:1, just under the 4.5:1 floor for normal text under 18px. Sam (low vision) and bright-daylight glare both lose it.
- **Fix:** Bump the 12px `.desc`/`.hint` color to `--text-secondary` (#aebcd4), or raise weight to 500. Cheap, closes the last contrast gap.
- **Suggested command:** `/impeccable harden`

**[P3] "外觀" is a section header over a single row**
- **Why it matters:** A group label for one setting (強調色) carries more structural weight than its content. Mild visual imbalance against the 3-row and 2-row groups above.
- **Fix:** Either fold 強調色 into 顯示, or add the (already-planned) future appearance settings so the group earns its header. Lowest priority.
- **Suggested command:** `/impeccable layout`

**[P3] Privacy hint still floats without an anchor**
- **Why it matters:** "定位僅用於…不上傳、不追蹤" reassures about location, but there is no location/GPS row near it, so the statement references something not on screen. Reads slightly orphaned.
- **Fix:** Either anchor it under a future "定位/隱私" row, or scope the copy to the app generally so it doesn't imply a nearby control.
- **Suggested command:** `/impeccable clarify`

## Persona Red Flags

**Sam (Accessibility-Dependent):** Major improvement, accent state no longer color-only, controls are labeled with `aria`, focus-visible outlines exist on every interactive element. Residual: the 12px `text-tertiary` descriptions sit at borderline AA contrast; a switch/screen-reader user is otherwise well served.

**Casey (Distracted, in-car, one-handed):** Targets are now thumb-sized and the whole toggle row is tappable. Controls still cluster top/right (inherent to a top-nav settings screen), but mis-tap risk is much lower. No remaining red flag worth blocking on.

**In-car first-timer (project persona):** The auto-minimal and keep-screen-on toggles now explain themselves before being touched. The first-timer can predict each setting's effect, the prior "toggle to discover" risk is gone.

## Minor Observations

- All toggles still render ON in the preview; spot-check the OFF knob (`--unit` on `--surface-raised`) contrast on a real device.
- Color names 青/琥珀/靛 are crisp; confirm they localize cleanly if an English build is added.
- Reduced-motion is handled globally; settings inherit it correctly.
- The single-stop-per-segmented-option tab order is acceptable; a roving-tabindex radiogroup would be the gold-standard keyboard pattern if you want it later.

## Questions to Consider

- Is there a future "定位/隱私" or "關於" row that would give the privacy hint a home, or should the copy stand alone?
- Will 外觀 grow (themes, dial style, font scale), or should accent collapse into 顯示 for now?
- Do any of these settings deserve a place on the HUD itself (quick mirror/brightness) so the driver rarely opens this panel at all?
