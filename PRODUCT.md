# Product

## Register

product

## Users

Tesla Model 3 / Model Y drivers (and other EV drivers) using their own phone as a dashboard heads-up display, propped on the dash while driving. Context is demanding and safety-critical: the driver's eyes are on the road, glancing for well under a second, in conditions that swing from bright midday glare through the windshield to a dark night highway. A secondary context is **mirror mode**, where the phone lies flat and the screen reflects off the windshield, so the image must stay legible when flipped. The job to be done: **know my current speed (and later battery % / range) without looking at the car's center touchscreen.** Tesla 3/Y have no instrument cluster behind the wheel, so this app fills that gap.

## Product Purpose

A native iOS / Android app (Flutter) that turns a phone into a glanceable speed HUD. Phase 1 shows real-time speed from the phone's GPS; Phase 2 adds battery % and range via the Tesla Fleet API; Phase 3 (power-user, opt-in) reads vehicle data over Bluetooth OBD. The product ships to the App Store and Google Play. Success looks like: a driver reads their speed in a ~0.3s peripheral glance, even as a windshield reflection, trusts that the number is valid, and stops needing to look at the center screen. Full requirements live in GitHub Issue #1 (the PRD).

## Brand Personality

Instrument-grade: precise, calm, trustworthy. The feel of a well-made automotive gauge or an aircraft primary flight display, not a gadget. Three words: **precise, glanceable, trustworthy**. The interface should disappear into the task; the speed reading is the hero and everything else recedes.

## Anti-references

- Cheap aftermarket HUD / speedometer apps with neon-cyan-on-pure-black "gamer" styling, glossy bevels, and ad clutter.
- Generic app-store "speedometer" apps that bury the number under widgets, maps, and chrome.
- Cloning Tesla's own white-on-black center-screen UI (it's the thing we're replacing, not imitating).
- Busy dashcam-style overlays where decoration competes with the one number that matters.
- All the shared absolute bans (gradient text, glassmorphism-as-default, hero-metric template, etc.).

## Design Principles

- **Glanceable above all.** Exactly one element (the speed numeral) must read in a sub-second peripheral glance, even reflected. If a second element competes with it, the second element is wrong.
- **Two states, one family.** A minimal `drive` mode is the default while moving; a rich instrument `parked` mode is available when stationary or on tap. Same color family, same gauge geometry across both.
- **Safety over richness.** Decoration never competes with the read. Secondary information is dimmed, deferred, or hidden until the car is stopped.
- **Trust through status.** The driver must always be able to tell whether the reading is valid (GPS fix vs searching), never guessing if "0" or a stale number is real.
- **Earned familiarity.** Lean on instrument metaphors drivers already know (dial, needle, ticks) and standard controls; do not reinvent toggles, units, or navigation for flavor.

## Accessibility & Inclusion

- Maximum contrast for both daylight glare and night driving; day / night brightness adaptation is a first-class setting, not an afterthought.
- The speed numeral and primary controls must be legible at a glance and when horizontally mirrored.
- Do not rely on color alone for state: GPS fix vs searching pairs color with a label and/or shape (color-blind safe).
- Large, forgiving touch targets (the user is in a car, possibly moving).
- Reduced-motion friendly: gauge/needle motion is subtle and eased, never bouncy or attention-grabbing.
