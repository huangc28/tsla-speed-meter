---
name: ATELIER — Tesla Edition (round gauge)
description: Design guide for the round speed gauge and its four status icons, measured from the owner's dashboard image and the drawn prototype, with the owner's choices of 2026-11-13. Not yet the app's DESIGN.md.
colors:
  ground: "#0A0F15"
  ground-edge: "#070B11"
  numeral: "#FDFCFE"
  gear-active: "#FFFFFF"
  gear-inactive: "#7C828A"
  unit: "#969EA7"
  icon-normal: "#7F8790"
  icon-open: "#EF6A69"
  icon-warning: "#EFA83F"
  icon-unknown: "#A6ACB5"
  disc-fill: "#13191F"
  disc-rim: "#21272E"
  tick: "#48525C"
typography:
  numeral:
    fontFamily: "Hanken Grotesk, system-ui, sans-serif"
    fontSize: "103.2px"
    fontWeight: 500
  unit:
    fontFamily: "Hanken Grotesk, system-ui, sans-serif"
    fontSize: "17.2px"
    fontWeight: 500
  gear:
    fontFamily: "Hanken Grotesk, system-ui, sans-serif"
    fontSize: "14.35px"
    fontWeight: 500
rounded:
  disc: "18.55px"
components:
  icon-disc:
    backgroundColor: "{colors.disc-fill}"
    size: "37.1px"
---

<!-- DRAFT 2026-11-13: values come from the HTML prototype `frames/atelier-tesla-edition.html` (main frames `main-01…11`), which was measured from the owner's dashboard image and then changed by the owner's choices of 2026-11-13 (ruling L102). Nothing here is implemented in the app yet; re-run $impeccable document once the SwiftUI screen exists. -->

This guide covers the round speed gauge and its status icons only. The shipped app still follows the root `DESIGN.md`; this file replaces nothing until the owner says so. All sizes are points on the 844 × 390 landscape screen.

Sources: `frames/atelier-tesla-edition/reference/dashboard-2026-11-12.png` (authoritative), `icon-system-2026-11-12.png` (supporting), the owner's decisions of 2026-11-12 and 2026-11-13 (`00-brief-tesla-edition.md`, rulings L101 and L102), and the measurements in `18-tesla-edition-visual.md`. Reviews: `19-tesla-edition-critique.md`, `20-tesla-edition-safety.md`.

## Overview

A round instrument on a near-black, blue-tinted ground: one thin ring with a full circle of fine tick marks, the gear row `P R N D` inside the top of the ring, a large medium-weight numeral in the centre with `km/h` under it, and four status icons, each in its own dark disc, in one row along the lower arc under the numeral. It should feel like a quiet, precise instrument built into the car.

Scope: the speed gauge and the status icons. The side panels, top row and footer keep the previous design for now, except that the footer's odometer label reads `ODO`.

**The Fixed Ring Rule.** The ring has one size and one position in every state: one, two or three digits, parked, no speed, unknown. Nothing makes it grow, shrink or move. The same holds for the gear row, the unit and the four icon discs.

**The Three-Digit Rule.** The ring and the icon positions are set so every speed fits with clearance, checked for each value from 0 to 250. The tight case is a corner of one digit near a disc (a last digit 2 against the tire disc), not the widest number, so clearance is always measured for every value. The numeral never shrinks to make room.

**The No-Horizon Rule.** There is no long curve, glow band or ground gradient under the gauge.

## Colors

Strategy: restrained. A cold near-black ground, grey-white ink, and colour only where it carries a state.

- **Ground**: blue-black around the gauge (`ground`), slightly darker toward the screen corners (`ground-edge`).
- **Numeral** and the **active gear**: white (`numeral`, `gear-active`).
- **Inactive gears**: grey (`gear-inactive`, 4.96:1 on the ground; the owner's image had `#595E65` at 2.9:1). **Unit**: mid grey (`unit`, 7.1:1).
- **Icon, closed or normal**: dimmed grey (`icon-normal`, 4.5 to 5.2:1 on the disc; the owner's image had the lighter `#CCD0D9`), so a quiet state stays below the unit and the numeral.
- **Icon, open** (door, front trunk, rear trunk): red (`icon-open`).
- **Icon, tire pressure low**: amber (`icon-warning`).
- **Icon, state unknown**: grey dashes (`icon-unknown`).
- **Icon disc**: dark fill, a shade lighter than the ground, with a faint lighter rim (`disc-fill`, `disc-rim`; both are top-to-bottom gradients around these values).
- **Ticks**: dim blue-grey (`tick`).
- **Ring**: a line whose brightness changes around the circle as in the owner's image, bright across the top and almost black across the bottom, in one cool blue-white hue. The owner's image has an amber section on the right and a red one at the lower left; these are recoloured to the same blue-white at the same brightness (`coolRing` over `TE.ring`, sampled every 5°).

Icon colours are the median of the stroke pixels in the owner's dashboard image. The hex values printed on the icon-system sheet are not used.

**The State Colour Rule.** Red means open and amber means a warning. Nothing else in or on the ring uses them, the ring itself included.

## Typography

- **Speed numeral**: Hanken Grotesk 500, ink height 73.7, tabular digits, one fixed cell per digit (cell width 57.8), centred on the ring. Hanken Grotesk is the closest match to the owner's image and the owner chose it. It is under the SIL Open Font License 1.1, so it can be bundled with the app; ship the licence text with it.
- **Unit `km/h`**: the same face, 500, ink height about 12.8, its top 9.5 below the numeral's ink.
- **Gear row `P R N D`**: the same face, 500, cap height 10.0, letters 21.6 apart.
- Not chosen, kept for reference: SF Pro 500 with the straight-sided 6 and 9, cell width 60.

## Layout

- Screen: landscape 844 × 390.
- **Ring**: centre (422, 172), radius 156. It runs from y 16 to y 328 and stays about 20 clear of the left card and the right column.
- **Ticks**: 44 around the full circle, from 0.903 to 0.952 of the radius, line width 0.8.
- **Gear row**: centred 0.692 of the radius above the ring centre.
- **Numeral**: ink centre 8.9 above the ring centre.
- **Icon discs**: centres on a circle at 0.712 of the radius, in one row along the lower arc, 42° apart. Left to right: front trunk at 117° left of the top, door at 159° left, rear trunk at 159° right, tire pressure at 117° right. Centres: (323.0, 222.4), (382.2, 275.7), (461.8, 275.7), (521.0, 222.4). The space above and beside the numeral stays empty.
- **Clearances**, measured on ink at 1×: disc to numeral at least 9 (measured minimum 10.4 across 0 to 250, at three-digit numbers ending in 2 against the tire disc; 10.7 at 200 to 250 against the front-trunk disc); disc to unit at least 8 (measured 39.7); disc to ticks at least 6 (measured 11.9); disc to disc at least 8 (measured 42.5).
- Not chosen, kept for reference: the four-corner layout (front and rear trunk 49° either side of the top, door and tire 124°).
- **Top row**: the clock sits at the left, beside the source mark, so the top centre belongs to the ring.
- Portrait: not designed.

**The Centred Numeral Rule.** The numeral is centred. Within the same digit count no digit moves; the layout re-centres only when the count changes (at 10 and at 100).

## Elevation & Depth

Flat. Depth comes only from the icon discs sitting a shade lighter than the ground and from a soft light along the lit parts of the ring. No drop shadows.

## Shapes

- **Icons**: outline drawings redrawn as vector strokes from the owner's image, round caps and joins, line width about 1.7 at 1×, drawn inside a 37.1 disc. The open drawings overlay the owner's image within 0.29 to 0.51 px, except where noted below.
- **Closed and open differ in shape, not only in colour.** Closed front trunk and rear trunk: the car body with the lid down. Closed door: the door without the open leaf. Normal tire: the tire without the exclamation mark.
- **Front and rear are told apart by shape.** The open front trunk has its lid at the car's front, the open rear trunk at the rear. Closed, the front trunk has the nose section filled and the rear trunk has the tail section filled.
- **Open door**: the open leaf is drawn longer than in the owner's image so the open and closed doors differ by more than a few pixels at 1×.
- **Unknown state**: the closed outline in flat-capped dashes, no fills and no nose or tail mark, dash length about 4.4 to 6.7 at 1× with a real gap of at least 2 px at 1×. An unknown front trunk and rear trunk are told apart by position only.
- **Ring**: a thin circle, line width about 2.5 where lit.

## Components

### Icon disc
A 37.1 circle (`disc-fill`, rim 0.7 `disc-rim`) with one outline icon. Four fixed slots, always drawn. States: closed or normal (dimmed grey, closed shape), open or warning (red or amber, open shape), unknown (grey dashes). The slot never moves or disappears.

### Gear row
`P R N D`, the current gear white and heavier (600), the rest grey.

### Numeral and unit
The speed with `km/h` under it. With no valid speed the numeral is a dash (49.4 × 4.2) and the line 車速暫不可用 sits 12 below the dash in place of the unit; it never shows 0 unless the car reports 0.

## Do's and Don'ts

Do:
- Keep all four icon slots drawn at all times.
- Keep the standing safety rules of the root `DESIGN.md`: no valid speed shows a dash; an unknown state is the closed shape in grey dashes; door-unknown and tire-no-reading are separate states; values change instantly.
- Show only what the car's Bluetooth supplies.

Don't:
- Don't draw icons with no data behind them (steering wheel, lane, parking brake, speed-limit sign) until a data source exists.
- Don't draw the Tesla logo, weather, phone signal or Wi-Fi marks.
- Don't let the ring, the numeral, the gear row or the icon slots move between states.

Decided by the owner on 2026-11-13 (ruling L102):
- The safety-suggested version, all four points: closed icons use a different shape; the front-trunk lid is drawn at the front of the car; the ring's red and amber sections become blue-white; closed icons are dimmed and inactive gears raised.
- Numeral face: Hanken Grotesk.
- Icon layout: one row along the lower arc.
- The "long curve" removed from under the gauge is the old horizon line.
- Footer odometer label: `ODO`.

Added after review, not in the owner's image (shown on the page, the owner can reject them): the nose and tail marks on the closed front and rear trunk, and the longer open-door leaf.

Still open:
- Whether this guide later replaces the root `DESIGN.md`.
- Not designed: parked screen beyond `P` and 0, portrait, charging, night dimming, the side panels (the right column repeats the door states and shows a low tire in red while the gauge uses amber).
- Not measured: speeds above 250, a 0.3-second glance test, the in-car check, colour-vision simulation.
