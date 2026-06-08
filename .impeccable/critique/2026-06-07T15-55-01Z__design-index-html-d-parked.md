---
target: screen D (parked cluster)
total_score: 25
p0_count: 0
p1_count: 2
timestamp: 2026-06-07T15-55-01Z
slug: design-index-html-d-parked
---
# Impeccable Critique — Screen D (parked cluster)

Target: `design/index.html` parked screen (`parkedInner`). Register: product. Family: digital instrument cluster.

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | No data-source/connection chip on parked (drive has one); gear `P` + 120 km/h contradicts each other |
| 2 | Match System / Real World | 3 | Strong instrument metaphor, but `P` gear with a 120 reading breaks real-world logic |
| 3 | User Control and Freedom | 2 | No visible way back to drive / no settings affordance on parked |
| 4 | Consistency and Standards | 3 | Battery shown as icon+text here vs a prominent capsule in drive |
| 5 | Error Prevention | 3 | Low-stakes display surface; little to get wrong |
| 6 | Recognition Rather Than Recall | 2 | Icon-only telltales (unlabeled, all one color); `BLE` jargon tag next to energy |
| 7 | Flexibility and Efficiency | 3 | Tap-to-toggle; appropriately minimal for a display |
| 8 | Aesthetic and Minimalist Design | 3 | Restrained, on-brand; perf row mixes two concepts, BLE tag adds noise |
| 9 | Error Recovery | 2 | No defined BLE-disconnected / stale / no-data state for parked (drive has waiting state) |
| 10 | Help and Documentation | 2 | None on-surface (acceptable for an instrument, but no privacy/source hint) |
| **Total** | | **25/40** | **Acceptable — solid bones, real trust/status gaps** |

## Anti-Patterns Verdict

**LLM assessment:** Does NOT look AI-generated. It reads as a deliberate instrument cluster: tinted dark-blue neutrals (no pure black), reserved crimson needle, single cyan accent, real radial tick geometry. Clears all shared absolute bans — no gradient text, no glassmorphism, no side-stripe borders, no hero-metric template, no identical card grid. On-brand with PRODUCT.md (precise / glanceable / trustworthy) and avoids the gamer-HUD anti-reference.

**Deterministic scan:** Unavailable — `detect.mjs` reports "bundled detector not found." No CLI findings, no browser overlay. Assessment B = manual browser inspection only (degraded).

## Overall Impression
The parked cluster is the strongest, most characterful screen in the set: hierarchy is clear, the dial is the unambiguous hero, secondary data recedes into well-grouped bands. The biggest opportunity is **trust/status**: parked silently dropped the source/connection indicator that drive has, and the demo state (P gear + 120 km/h) actively contradicts itself. For an app whose core promise is "trust that the number is valid," parked currently can't tell the driver whether its data is live.

## What's Working
1. **Instrument-grade hierarchy** — the radial dial + center numeral is the unmistakable focal point; ticks/needle are earned familiarity, not decoration. Exactly the brand's "aircraft PFD, not gadget" target.
2. **Disciplined layering** — battery, trip strip, perf row, time pill stack in dim, grouped bands below the dial; secondary info recedes without disappearing. Good proximity grouping, low cognitive load for a rich screen.
3. **Color restraint** — one cyan accent, crimson reserved strictly for the needle, blue-tinted neutrals. Reads premium and calm, dodges the neon-on-black cliché.

## Priority Issues

- **[P1] Parked has no data-source / connection status.** Drive shows a `TESLA`/`GPS` chip; parked shows none. With BLE-primary architecture, BLE can drop or the car can sleep — parked must tell the driver whether battery/gear/range are live or stale. Undermines the core "trust through status" principle.
  - **Fix:** add the same active-source chip (top-left) to parked; define a stale/disconnected treatment (dim values + "—").
  - **Suggested command:** `craft` (status chip on parked) then `harden` (stale/no-data states).

- **[P1] Gear `P` + 120 km/h is self-contradictory.** Parked = stationary = 0; showing a 120 reading with the needle deflected while `P` is lit breaks match-real-world and consistency. It's a preview/demo artifact, but the spec must pin parked's resting state.
  - **Fix:** parked default = 0 (needle at 0). If a separate "showcase/demo" mode is wanted, label it explicitly and don't light a contradictory gear.
  - **Suggested command:** `clarify` / `polish`.

- **[P2] `BLE` tag is developer jargon on a driver-facing surface.** It encodes data-source/phase for us; a driver won't parse "BLE" next to Wh/km.
  - **Fix:** remove from production UI (keep as a design annotation only), or replace with a meaningful state (e.g. live vs estimated).
  - **Suggested command:** `clarify`.

- **[P2] Telltale row is placeholder.** Four icons, one dim color, no active/inactive states or standard colors (green turn, blue high-beam). Meaning-by-color-alone risk; currently decorative.
  - **Fix:** define active/inactive states with standard automotive colors + shape; only render telltales that have data.
  - **Suggested command:** `craft` / `harden`.

- **[P2] Battery treatment is inconsistent across states.** Drive uses a prominent capsule + range; parked uses a small icon + `82% · 312 km`. Same datum, two vocabularies.
  - **Fix:** unify the battery component (or deliberately scale one), so battery reads the same way in both states.
  - **Suggested command:** `extract` (shared battery component) / `polish`.

## Persona Red Flags

**Casey (distracted in-car / glancing driver):** Parked is rich, which is fine when stopped, but the perf row crams 0–100 + Wh/km + a `BLE` tag into one line — too much to parse at a glance during the brief stop. No bottom-zone control to flip back to drive one-thumbed.

**Sam (accessibility / low vision / color-blind):** Telltales rely on color alone with no labels/shape. Needle crimson on dark + tick labels at 13px may fail contrast/zoom. No source chip means a screen-reader/again low-vision user gets no "data live" cue parked.

**Riley (stress tester / edge cases):** The P-gear-plus-120 contradiction is exactly the inconsistency Riley hunts. What does parked show when BLE disconnects mid-session? When range string is long ("1,015 km")? When charging? None are defined yet.

## Minor Observations
- Perf row mixes performance (0–100) and efficiency (Wh/km) concepts on one line; consider separating or relabeling.
- DESIGN.md mentions a battery "smile-arc" the preview doesn't render — spec/preview drift.
- `本趟 / 平均 / 最高` strip is clean and well-chunked; good.
- No charging state shown though it's in the IA — parked is where it belongs.

## Questions to Consider
- If parked's whole value is richness-when-stopped, what's the one thing a driver actually checks at a stop — and is it the most prominent thing after speed?
- Should "parked" and "demo/showcase" be two different states, so the resting state can honestly be 0?
- When BLE drops while parked, what is the trustworthy thing to show — last-known with a timestamp, or dimmed dashes?
