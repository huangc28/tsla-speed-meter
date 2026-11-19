---
name: ATELIER — Tesla Edition (round gauge)
description: Design guide for the round speed gauge and its four status icons, measured from the owner's dashboard image and the drawn prototype, with the owner's choices of 2026-11-13, 2026-11-14 and 2026-11-15. In the app since 2026-11-19 (#97–#101); the root DESIGN.md points here for the main screen.
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

<!-- DRAFT 2026-11-13: values come from the HTML prototype `frames/atelier-tesla-edition.html` (main frames `main-01…11`), which was measured from the owner's dashboard image and then changed by the owner's choices of 2026-11-13 (ruling L102). Implemented in the app on 2026-11-19 (#97–#101, PRs #102–#106); the app's own measurements are in `ios-app/README.md`. -->

This guide covers the round speed gauge and its status icons only. The app implements it (#97–#101). With the owner's OK on 2026-11-19 (L110), the root `DESIGN.md` was updated to point here for the main screen. The root file still covers everything else. All sizes are points on the 844 × 390 landscape screen.

Sources: `frames/atelier-tesla-edition/reference/dashboard-2026-11-12.png` (authoritative), `icon-system-2026-11-12.png` (supporting), the owner's decisions of 2026-11-12 and 2026-11-13 (`00-brief-tesla-edition.md`, rulings L101 and L102), and the measurements in `18-tesla-edition-visual.md`. Reviews: `19-tesla-edition-critique.md`, `20-tesla-edition-safety.md`.

## Overview

A round instrument on a near-black, blue-tinted ground: one thin ring with a full circle of fine tick marks, the gear row `P R N D` inside the top of the ring, a large medium-weight numeral in the centre with `km/h` under it, and four status icons, each in its own dark disc, two either side of the numeral as on the owner's image (front and rear trunk above, door and tire level with the numeral). It should feel like a quiet, precise instrument built into the car.

Scope: the speed gauge and the status icons. On the design page, the left panel and the footer keep the previous design, except that the footer's odometer label reads `ODO`; the top row's clock moved left (L101) and the right column was redone (L104). The app ports them from the page (#100, #101; see `ios-app/README.md`).

**The Fixed Ring Rule.** The ring has one size and one position in every state: one, two or three digits, parked, no speed, unknown. Nothing makes it grow, shrink or move. The same holds for the gear row, the unit and the four icon discs.

**The Three-Digit Rule.** The ring and the icon positions are set so every speed fits with clearance, checked for each value from 0 to 250. The tight case is a corner of one digit near a disc (a last digit 2 against the tire disc), not the widest number, so clearance is always measured for every value. The numeral never shrinks to make room.

**The No-Horizon Rule.** There is no long curve, glow band or ground gradient under the gauge.

## Colors

Strategy: restrained. A cold near-black ground, grey-white ink, and colour only where it carries a state.

- **Ground**: blue-black around the gauge (`ground`), slightly darker toward the screen corners (`ground-edge`).
- **Numeral** and the **active gear**: white (`numeral`, `gear-active`).
- **Inactive gears**: grey (`gear-inactive`, 4.96:1 on the ground; the owner's image had `#595E65` at 2.9:1). **Unit**: mid grey (`unit`, 7.1:1).
- **Icon, closed or normal**: not drawn at all, disc included (ruling L108). `icon-normal` (dimmed grey, 4.5 to 5.2:1 on the disc; the owner's image had the lighter `#CCD0D9`) is kept only for the unchosen versions on the page.
- **Icon, open** (door, front trunk, rear trunk): red (`icon-open`).
- **Icon, tire pressure low**: amber (`icon-warning`). Low means the car's own tire warning; the app sets no threshold. The right column's low tire uses the same amber, so red means open and nothing else.
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
- **Icon discs**: centres on a circle 113 from the ring centre (0.724 of the radius), arranged as on the owner's image, a column either side of the numeral. Front trunk 50° left of the top, door 90.2° left, rear trunk 50° right, tire pressure 90.2° right. Centres: (335.44, 99.37), (309.00, 172.39), (508.56, 99.37), (535.00, 172.39). These are the owner's image positions moved just enough for three-digit speeds (all discs 1.9 further out, the top pair up from 56.2° to 50°).
- **Speed-limit slot, drawn as nothing**: the bottom of the ring (422, 281.82), kept empty for a road speed limit from map data (issue #2, not decided). The parking-brake and lane slots of 2026-11-14 are gone (ruling L109): two drives with the logger probe (issue #92) showed the car does not send them. The four icons above did not move. The main screens and the map preview read one shared definition.
- **Clearances**, measured on ink across 0 to 250, at 2× and at native 1×: disc to numeral at least 9 (measured minimum 9.50 at 2× and 9.00 at 1×, at three-digit numbers ending in 4 against the tire disc; 9.55 and 10.00 at three-digit numbers ending in 7 against the rear-trunk disc); disc to unit at least 8 (measured 82.8); disc to gear row at least 8 (measured 41.2); disc to ticks at least 6 (measured 9.6); disc to disc at least 8 (measured 40.5). The tire disc has no spare at 1×: re-measure whenever the rendering changes, including the native build.
- Not chosen, kept for reference: the four-corner layout (front and rear trunk 49° either side of the top, door and tire 124°); the lower-arc row (front trunk 117° left, door 159° left, rear trunk 159° right, tire 117° right at 0.712 of the radius), which was the main layout from 2026-11-13 until the owner changed it on 2026-11-14.
- **Top row**: the clock sits at the left, beside the source mark, so the top centre belongs to the ring.
- **Right column**: tire pressure only. A small title (tire mark and「胎壓」, centre y 98.2, level with the destination line of the left card) over a top-view car 130 high (ink y 116.5 to 247.5, centre x 683, line width 1.2), with one reading beside each tire in 15 / 500. The title's left edge lines up with the readings at x 598; the readings end at x 767.5. The block sits inside the height of the left card (y 79 to 260) and stays 20 clear of the ring. A low tire fills that tire and colours its reading amber (`icon-warning`). No reading shows a dash in place of each value. The column has no divider and no door or trunk rows; the gauge icons carry those states.
- Portrait: not designed.

**The Centred Numeral Rule.** The numeral is centred. Within the same digit count no digit moves; the layout re-centres only when the count changes (at 10 and at 100).

## Elevation & Depth

Flat. Depth comes only from the icon discs sitting a shade lighter than the ground and from a soft light along the lit parts of the ring. No drop shadows.

## Shapes

- **Icons**: outline drawings redrawn as vector strokes from the owner's image, round caps and joins, line width about 1.7 at 1×, drawn inside a 37.1 disc. The open drawings overlay the owner's image within 0.29 to 0.51 px, except where noted below.
- **Closed shapes appear only as the unknown outline.** Closed icons are not drawn (L108); the closed drawings (front and rear trunk with the lid down, the door without the open leaf) survive as the dashed outline of the unknown state.
- **Front and rear are told apart by shape.** The open front trunk has its lid at the car's front, the open rear trunk at the rear. (The closed versions with the nose or tail section filled belong to the unchosen always-drawn version.)
- **Open door**: the open leaf is drawn longer than in the owner's image so the open and closed doors differ by more than a few pixels at 1×.
- **Unknown state**: the closed outline in flat-capped dashes, no fills and no nose or tail mark, dash length about 4.4 to 6.7 at 1× with a real gap of at least 2 px at 1×. An unknown front trunk and rear trunk are told apart by position only.
- **Ring**: a thin circle, line width about 2.5 where lit.

## Components

### Icon disc
A 37.1 circle (`disc-fill`, rim 0.7 `disc-rim`) with one outline icon. Four fixed slots, each drawn only for an event: open (red, open shape), low tire (amber), unknown (grey dashes; front trunk, rear trunk and door only). Closed, normal, a tire with no reading, and every slot while the car is not connected: nothing, not even the disc. One more reserved slot, the speed-limit sign at the bottom (L109), stays undrawn until a source supplies its data (no empty disc, no dashed ring, no faint icon). A slot never moves and is never filled by another icon. One door icon stands for any of the four doors.

### Gear row
`P R N D`, the current gear white and heavier (600), the rest grey.

### Numeral and unit
The speed with `km/h` under it. With no valid speed the numeral is a dash (49.4 × 4.2) and the line 車速暫不可用 sits 12 below the dash in place of the unit; it never shows 0 unless the car reports 0.

## Do's and Don'ts

Do:
- Draw an icon only for an event, in its own fixed slot; leave the slot empty otherwise (L108).
- Keep the standing safety rules of the root `DESIGN.md`: no valid speed shows a dash; an unknown state is the closed shape in grey dashes; door-unknown and tire-no-reading are separate states; values change instantly.
- Show only what the car's Bluetooth supplies.

Don't:
- Don't draw steering-wheel, lane or parking-brake icons: the car does not send these (issue #92; parking brake cannot be told apart from gear `P`). Don't draw the speed-limit sign until a map source exists.
- Don't draw the Tesla logo, weather, phone signal or Wi-Fi marks.
- Don't let the ring, the numeral, the gear row or the icon slots move between states.

Decided by the owner on 2026-11-13 (ruling L102):
- The safety-suggested version, all four points: closed icons use a different shape; the front-trunk lid is drawn at the front of the car; the ring's red and amber sections become blue-white; closed icons are dimmed and inactive gears raised.
- Numeral face: Hanken Grotesk.
- Icon layout: one row along the lower arc. Replaced on 2026-11-14, see below.
- The "long curve" removed from under the gauge is the old horizon line.
- Footer odometer label: `ODO`.

Added after review, not in the owner's image: the nose and tail marks on the closed front and rear trunk, and the longer open-door leaf. The owner approved the page that shows them on 2026-11-13 (ruling L103).

Decided by the owner on 2026-11-13, afternoon (ruling L104):
- The right column drops the door and trunk list, because the gauge icons already show those states.
- The tire car is enlarged and aligned with the left card (layout 甲 of three; the other two are kept on the page as not chosen).

Decided by the owner on 2026-11-14 (ruling L107):
- Icon layout: the arrangement of the owner's image, in the version moved just enough for three-digit speeds. The main screens use it for the four icons that have data.
- The three positions with no data (parking brake, lane, speed-limit sign) stay empty for now. (Superseded by L109: parking brake and lane removed; the speed-limit position stays empty.)

Decided by the owner on 2026-11-15 (ruling L108):
- Car-status icons show only for an event: red when open, amber for a low tire (the car's own warning), grey dashes when unknown. Closed and normal draw nothing; same rule on the drive and parked screens; icons appear and disappear at once.
- One door icon for any door; the screen does not say which.
- The right column keeps its four readings at all times; a low tire there is amber, as in the gauge.
- Most of the time the ring holds only the numeral, unit, gears and ticks; nothing is added to fill it.
- The always-drawn version of 2026-11-14 is kept on the page as not chosen.

Decided by the owner on 2026-11-16 (ruling L109):
- Issue #92's two in-car drives found no road speed limit, no Autopilot or Autosteer state and no lane state in any of the 12 groups the car can be asked for; parking brake follows gear `P` exactly. The parking-brake and lane positions are removed; the speed-limit position stays empty, for map data later.
- The page's preview shows only the speed-limit sign, labelled as needing map data; the 2026-11-15 preview with parking brake and lane is kept on the page as not chosen.
- **Approved baseline (owner, 2026-11-16):** this version (page `d675d719`, artifact Version 10) is the design to implement in the app. Implementation is the next goal.

Still open:
- Whether this guide later replaces the root `DESIGN.md` entirely. Since 2026-11-19 the root file points here for the main screen.
- Not designed: parked screen beyond `P` and 0, portrait, charging, night dimming, the left panel.
- The four no-reading dashes in the right column can read as axles at 1×.
- Not measured: speeds above 250, a 0.3-second glance test, the in-car check, colour-vision simulation.
- Road speed limit from map data (issue #2): which source, coverage, and what to show when the map's limit is wrong or missing. Not designed: the sign's look when the limit is unknown (it is simply not drawn).
