# DESIGN.md — tsla-speed-meter

Design tokens extracted from the locked Pencil design (`tsla-speed-meter.pen`). These feed the Flutter implementation (Dart constants / `ThemeData` / `CustomPainter`). Register: **product** (app UI, driver in-task). Family: **digital instrument cluster**, adapted for an EV phone HUD.

## Design principles
- **Glanceable first.** The speed numeral is the only thing that must read at a 0.3s peripheral glance and through a windshield reflection. Everything else is secondary and dimmed.
- **Two states.** `drive` (minimal, default while moving) and `parked` (rich cluster, when stationary / tapped). Same color family and gauge geometry across both.
- Dark, blue-tinted, high-contrast. No pure `#000`/`#fff` (tinted neutrals). One accent (cyan) carries state; crimson is reserved for the parked-mode needle.
- Mirror mode = horizontal flip (`Transform.scale(scaleX: -1)`) of the drive screen so the windshield reflection reads upright.

## Color tokens
Neutrals (blue-tinted):
- `bg.base` `#0A101C` — app surface; gauges sit on a radial gradient `#101B2E`→`#070B14` (center top).
- `surface.raised` `#16202E` — segmented-control track, inset controls.
- `divider` `#1A2433` — settings row separators.
- `dial.cap` `#26344C` · `dial.faceRing` `#1A2740` · `dial.face` gradient `#121C2E`→`#0A101C`.

Text:
- `text.primary` `#F2F5FA` — speed numeral, titles.
- `text.secondary` `#AEBCD4` (labels) · `#D6DEEA` (settings row label) · `#8A97AE` (unit).
- `text.tertiary` `#6E7E8C` · `text.dim` `#5A6675`.

Ticks:
- `tick.major` `#C2D2EA` · `tick.minor` `#44526A`.

Accent — cyan (primary / active state):
- `accent` `#2BD4E0` · `accent.bright` `#8FE6EE` · `accent.text` `#6FD8E2` · `accent.dim` `#3C7A82` · `accent.segActiveBg` `#1E3C45`.

Semantic:
- `needle` `#E8344F` (crimson; the current-value marker on the arc, both states) · `hub` `#D7DEEC` (legacy, now unused).
- `gps.fix` `#3DE0A8` (green) · `gps.searching` `#F5B53C`, label `#D7A23E`.
- `over` `#FFB638` (amber; over-speed numeral only) · `limit.marker` `#C2D2EA` (neutral) / label `#AEBCD4`.
- `battery.fill` linear `#2BBF86`→`#3DE0A8` · `battery.track` `#16202E` · `battery.icon` `#5A6B7A`.

Theme accents (accent picker / alternate explorations A–C):
- cyan `#2BD4E0` (default) · amber `#FFB638` · indigo `#6E7BFF`.

## Typography
Family: **Inter** (cross-platform; system fallback acceptable). One family, weight + scale for hierarchy.
| Role | Size | Weight | Tracking |
|---|---|---|---|
| Speed numeral — drive | 158 | 700 | -5 |
| Speed numeral — parked center | 158 (= drive) | 700 | -5 |
| Screen title | 24 | 700 | 0 |
| Unit (km/h) | 24 (drive) / 20 | 500 | 2–3 |
| Settings row label | 17 | 500 | 0 |
| Tick number labels / battery line | 16 | 500 | 1 |
| Segmented / control text | 14 | 600 | 0 |
| GPS status label | 12 | 600 | 2 |
| Caption / privacy hint | 12 | 400 | 0 (lineHeight 1.5) |

## Spacing & radius
- Spacing scale (base 4): `2, 4, 8, 12, 16, 18, 24, 28`.
- Screen padding `24`; settings row vertical padding `18`; section header bottom `28`.
- Radius: segmented `9–11`, toggle `15`, pill `16`, accent dot ring `15`.

## Gauge spec (CustomPainter)
- Sweep: `startAngle = 215°`, total sweep `-250°` (CW). So 0 sits lower-left (215°), max lower-right (-35°). `valueFraction = speed / maxSpeed` → `activeSweep = -250 * fraction`. Default `maxSpeed` 240 km/h (label every 40).
- **Parked gauge** (same geometry as `drive`): the speed meter is **identical to drive** — thin track ring + cyan active arc + the few rim ticks (0/60/120/180/240) + crimson current-value marker inside the band, at the **same vertical level as drive** (stage top 196, screen-centered numeral) so the speed reading does not jump when toggling drive↔parked. The numeral is scaled down (drive 128 / parked 100 in preview px) only so it coexists with parked's data bands; the gauge geometry and position are the same. **No speed-limit marker** (no limit when stationary). The earlier radial-tick-dial-with-needle is retired; "one family, same gauge geometry across both states" is now literal, and parked's richness comes from the surrounding data bands, not a different gauge. Center numeral + `km/h`. **Resting state = 0** (arc empty, track only), consistent with gear `P`; a non-zero dial is only shown in an explicitly badged **demo / showcase** state (`示範模式 DEMO`), never as a normal parked reading. Battery uses the **same capsule vocabulary as `drive`** (mini capsule + fill) showing **% + remaining range** (e.g. `82% · 312 km`). Gear selector **just above the center numeral, inside the gauge** (`P R N D`, active gear in a filled `accent` chip, others dim; reads `P` when parked; same BLE data dependency, same treatment and position as drive). **Parked carries the same active-source chip as drive** (top-left `TESLA`/`GPS`) plus a settings gear (top-right), so the driver can always tell whether data is live and can reach settings. Bottom date/time/temp pill (cyan-bordered). **Additions (see Information architecture)**: a trip stat strip (distance / avg / max) below the dial, plus charging status (BLE) when plugged in. The 0–100 timer, energy (Wh/km) panel, and telltale row were **removed from the parked cluster (2026-06-08)** to keep it focused on speed + core status (battery, gear, trip).
- **Drive dial** (minimal, default while moving): thin track ring + cyan active arc to the current value. Signature motifs carried from the cluster so it is not a generic speedo: a few major ticks (0/60/120/180/240) on the rim; a crimson current-value marker (`needle` color) sitting just *inside* the arc band (echoes the parked needle). A neutral speed-limit marker (`limit.marker`) + numeric label sits just *outside* the arc band. **Over-speed = number is the sole warning**: when speed > limit the numeral turns `over` amber; the arc and markers stay neutral (no amber overload). Huge numeral + small dim `km/h`. Top-left GPS status, top-right settings gear. **Gear selector sits just above the speed numeral, inside the gauge** (`P R N D`, active gear in a filled `accent` chip with `bg.base` glyph, others `text.dim`) so it reads in the same glance as the speed. Same treatment and position in drive and parked. The gear selector needs vehicle `shift_state`, exposed over Tesla's native BLE infotainment channel (or OBD — see Data-source reality); on GPS fallback it is hidden. Battery is a capsule bar (`battery.track` + `battery.fill`) with a terminal nub, `82%`, and range, centered below the numeral (battery matters for an EV, so it is a clear component, not a caption). Two states to build: normal (white numeral, current marker before the limit) and over-speed (amber numeral, current marker past the limit). **BLE enrichment**: a thin peripheral power/regen bar may be added at the screen edge (see Information architecture); on GPS fallback the drive screen stays speed-only.
- **Mirror mode**: render the drive screen flipped horizontally.
- **Waiting/no-fix**: active arc + tip hidden; numeral shows dimmed `– –`; GPS dot → `gps.searching` amber with “搜尋 GPS 訊號…”; battery hidden.

### Hardened states (parked) — resilience, not the happy path
The HUD's core promise is *trust the reading*, so every non-live condition must be unambiguous, never a silently-stale number.
- **BLE-disconnected / stale**: BLE dropped or the car is asleep. Last-known cluster (dial, battery, stats) is **dimmed to ~38% opacity**; the source chip flips to **amber `連線中斷`** and a **`最後更新 · N 分鐘前`** timestamp appears, so the driver knows it is not live. Gear (live-only data) is hidden.
- **No-data / first-run**: paired but no reading yet. Values are **`—` placeholders** (battery `—%`, range `— km`, stats `—`), never `0` or blank; chip shows amber **`等待車輛`**.
- **Charging**: plugged in. Battery readout becomes a charge status — **`⚡ 48 kW`**, **`82% → 90%`**, **`約 25 分`** (rate / current→target / time-to-full), fill tinted toward `accent.bright`.
- **Reduced-motion**: under `prefers-reduced-motion: reduce`, needle/arc easing collapses to instant (no sweeping animation).
- **Boundary checks**: range strings must fit up to `1,015 km`; battery `0–100%`.

## Information architecture & data phasing
Every data element, its source/phase, and which state shows it. Governing rule: **`drive` stays minimal — on GPS fallback the only `drive` elements are speed, speed-limit / over-speed, and the source-status chip.** Everything richer needs BLE and lives in `parked` (the lone `drive` exception is the power bar). Elements added 2026-06-07 (driver-value brainstorm) are marked ⊕.

| Element | Source / Phase | State | Notes |
|---|---|---|---|
| Speed numeral | **BLE → GPS** | drive + parked | hero; the only sub-second read. BLE primary, GPS fallback |
| Speed-limit marker + over-speed numeral | BLE/GPS + map | drive | numeral is the sole warning |
| ⊕ Active-source / connection status | BLE / GPS | drive | top-left chip: `TESLA` (BLE, full cluster) vs `GPS` (fallback, speed only); color + label, color-blind safe |
| ⊕ Trip distance / avg speed / max speed | derived (BLE/GPS speed) | parked | trip stat strip; per-trip, resettable |
| ⊕ 0–100 km/h timer (last / best) | derived (BLE/GPS speed) | deferred | removed from parked cluster 2026-06-08; candidate for a future trip/stats view |
| Battery % + range | BLE | drive + parked | hidden on GPS-only |
| Gear `P R N D` (shift_state) | BLE | drive + parked | hidden on GPS-only; BLE infotainment exposes it |
| ⊕ Power / regen bar (kW) | BLE* / OBD | drive | the **one** energy element allowed in `drive`; *drive-power over BLE unconfirmed — verify in spike, else OBD; hidden on GPS-only |
| ⊕ Energy: instant + trip-avg Wh/km | BLE / OBD | deferred | removed from parked cluster 2026-06-08; candidate for a dedicated energy/trip view |
| ⊕ Charging status (kW, time-to-full, %→target) | BLE | parked | shown when plugged in; augments battery area |
| ⊕ Telltales: TPMS / doors / lights | BLE | deferred | removed from parked cluster 2026-06-08 |
| Outside/cabin temp, climate, sentry, SW update | BLE | parked | secondary cluster info |
| Heading / compass | GPS | deferred | omitted to keep `drive` clean |

Source consequence: when **BLE is connected**, the full cluster is available (battery, gear, power, energy, charging). On **GPS fallback** (not paired / BLE dropped / car asleep) only speed + speed-derived stats show — which is exactly the existing GPS-only `drive` screen. The `DataSource` seam degrades the UI gracefully; `drive` stays minimal either way.

### Data-source reality (corrected 2026-06-07)
Earlier docs assumed battery/range/gear required the **Tesla Fleet API (cloud, billed, polling)** in Phase 2. That was wrong. Tesla's **native BLE** has two channels: **VCSEC** (lock/sleep/presence — pollable while asleep) and **Infotainment** (battery, range, gear `P R N D`, charging kW, TPMS, temp, odometer — available while the car is awake/active, i.e. always while driving). Shipping apps (e.g. DriveCluster) and community work (`esphome-tesla-ble`) read this **locally over BLE — no dongle, no cloud, no Tesla account, no developer fees**. So the chosen architecture (decided 2026-06-07) is **BLE-primary with a GPS speed-fallback** — not GPS-first, not BLE-only:

- **Primary — Tesla native BLE** (`TeslaBleSource`): the default source for *everything* — speed, battery, range, gear, charging, TPMS (possibly drive power). Local, near-real-time, free. Needs one-time key-pair enrollment into the car; protocol is community-reverse-engineered (Protobuf + ECDH/AES) → firmware-drift maintenance risk.
- **Fallback — GPS** (`GpsSource`): **speed only**, used when BLE is not paired / not connected / drops / the car is asleep. Zero auth/hardware — it guarantees a day-one experience and a safety net the reverse-engineered BLE path cannot. On GPS-only, battery/gear/energy are simply hidden (= the existing GPS-only `drive` screen).
- **Optional — Tesla Fleet API** (`TeslaFleetSource`): remote / away-from-car only (cloud, billed). Off the in-car path.
- **Power-user — OBD-II** (`ObdSource`): only the deepest data BLE can't give (cell temps, fine motor power). ~US$150–190 hardware, iOS MFi-limited.

A composite source coordinates them: **speed = freshest of {BLE, GPS}; every other field = BLE only.** The `DataSource` (`Stream<Reading>`) interface is the seam that keeps this swap invisible to the UI.

**Spikes before building:** (1) Flutter feasibility — `flutter_blue_plus` + porting Tesla's Protobuf/crypto BLE layer from the Go (`teslamotors/vehicle-command`) / Python (`python-tesla-fleet-api`) libs to Dart; (2) whether BLE speed is high-frequency enough (~5–10 Hz) for a smooth gauge and whether instantaneous *drive* power is exposed — if either fails, GPS covers speed and the power bar drops to OBD.

### New element specs
- **Trip stat strip (parked, P1)**: one horizontal row of three cells — `TRIP` (km) · `AVG` (km/h) · `MAX` (km/h). Label `text.tertiary` 12/600 tracking 2; value `text.secondary` 16/500. Thin `divider` between cells. Sits below the dial, above the date/time/temp pill.
- **0–100 timer (parked, P1)**: compact `0–100` label + best/last seconds (e.g. `5.9s`), same scale as trip cells. Interactive run (arm → auto-detect launch → stop at 100 km/h) is a P1 stretch; the static best/last readout is the baseline.
- **Power / regen bar (drive, P2)**: a thin vertical bar at the screen edge (mirror-safe). Center = 0 kW; fill up = power (`accent`/warm), fill down = regen (`battery.fill` green); range ~±250 kW. Peripheral and dim — must never pull the eye from the numeral. Hidden on GPS-only (no BLE).
- **Energy panel (parked, P2)**: instant `Wh/km` (live, `accent`) + trip-avg `Wh/km` beside it; optional tiny consumption sparkline. Hidden on GPS-only (no BLE).

## Screen inventory (frames in tsla-speed-meter.pen)
- `Bt6YY` D — Parked cluster · `za9HJ` D2 — Drive mode · `ZpCpT` D3 — Mirror preview · `Q62be` E — Settings · `bcZC0` F — Waiting GPS.
- `ztGMQ`/`PYNWq`/`7DS4v` A/B/C — earlier exploration directions (precision / typographic / ambient); kept for reference, not the chosen direction.

## Component states (build all per the PRD)
Toggle: off `surface.raised` knob `text.secondary` / on `accent` knob `bg.base`. Segmented: active `accent.segActiveBg` + `accent.text`, inactive transparent + `text.tertiary`. Every interactive control needs default / pressed / disabled at minimum.
