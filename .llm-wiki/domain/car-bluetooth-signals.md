# What the car's Bluetooth can and cannot report

## No signal for road speed limit, driver assistance, lane keeping or parking brake

The car's Bluetooth link does not report any of these:

- the speed limit of the road the car is on;
- whether Autopilot / Autosteer / traffic-aware cruise is engaged;
- lane-keeping or lane-departure state;
- the parking brake. One unnamed value follows gear `P` exactly, so in practice it means "in P".

Do not design or build a screen element that depends on one of them. A dashboard icon for any of these would have no data behind it. The road speed limit needs map data, which is why the over-speed feature is deferred (GitHub issue #2).

Look-alike fields that are not these signals:

- `speed_limit_mode` (`ClosuresState` / `VehicleState`) and the `ParentalControlsSettings` limits are owner-set top-speed caps, not the road's limit.
- The car sends fields the public proto does not name. The community proto `Teslemetry/tesla-protocol` names most of them:
  - `DriveState` #16–#25 are FSD mileage statistics; #25 is `fsd_active`, untested on a car with FSD.
  - `ChargeState` #186–#198 are low-power-mode and discharge-limit flags.
  - `ClimateState` #154 is dog mode.
  - `LocationState` #122–#128 are extra coordinates.
  - None of them is one of the four signals above.
- All four exist only on the car's CAN bus (`DAS_fusedSpeedLimit`, `DAS_autopilotState`, `DAS_laneDepartureWarning`, `DI_parkBrakeState`), which needs extra hardware.

- **Evidence:**
  - `ios-app/Packages/TeslaBLE/Protos/vehicle.proto` and `car_server.proto`. `GetVehicleData` lists 12 groups: charge, climate, drive, location, closures, two schedules, tire pressure, media, media detail, software update, parental controls.
  - Issue #92: two in-car drive-logger runs with every group asked and every decrypted field recorded, known and unknown. Every group answered in both runs. Basic Autopilot was on for part of the second run; the car has no FSD.
  - Desk research: `docs/research/car-signals-other-routes.md`.
- **Validated:** on paper 2026-11-13; on the owner's car 2026-11-15 and 2026-11-16 (issue #92). Owner decisions: 2026-11-12, icons with no car data are left out until a data source exists; 2026-11-16 (ruling L109), the round gauge drops its parking-brake and lane positions and keeps the speed-limit position empty for map data.
- **Decays when:**
  - a car firmware update adds such a field (re-run the #92 probe on branch `feature/92-car-data-probe`);
  - the car has FSD (then check `fsd_active`);
  - the app adds another data source (Fleet API, CAN hardware, map data).

Updated from issue #92 in-car probe 2026-11-16

## Music: the car reports it over Bluetooth

The car answers the media and media-detail groups of `GetVehicleData` over Bluetooth with no account or internet: `MediaState` (now-playing title, artist, playback status, volume) and `MediaDetailState` (now-playing station and more). During the second #92 run the now-playing title and artist changed between replies, so the values are live.

The app does not request these groups yet. A music card is now possible on data grounds; it still needs a design decision.

- **Evidence:** `vehicle.proto` (`MediaState`, `MediaDetailState`), `car_server.proto` (`GetMediaState`, `GetMediaDetailState`); issue #92 run 2, where the media groups answered and `now_playing_title`, `now_playing_artist`, `media_playback_status` and `audio_volume` changed.
- **Validated:** protocol 2026-11-13; on the owner's car 2026-11-16 (issue #92).
- **Decays when:** the app starts requesting media state (then the code is the source), or a firmware update changes what these groups return.

Updated from issue #92 in-car probe 2026-11-16
