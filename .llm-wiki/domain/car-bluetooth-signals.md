# What the car's Bluetooth can and cannot report

## No signal for road speed limit, driver assistance, lane keeping or parking brake

The car's Bluetooth protocol has no field for any of these:

- the speed limit of the road the car is on;
- whether Autopilot / Autosteer is engaged;
- lane-keeping or lane-departure state;
- the parking brake.

Do not design or build a screen element that depends on one of them. A dashboard icon for any of these would have no data behind it. The road speed limit needs map data, which is why the over-speed feature is deferred (GitHub issue #2).

Two fields look related but are not:

- `speed_limit_mode` (`VehicleState`) is the owner-set top-speed cap, not the road's limit.
- `ParentalControlsSettings` limits are also owner-set caps.

- **Evidence:** `ios-app/Packages/TeslaBLE/Protos/vehicle.proto` and `car_server.proto`. A search of both for speed limit, autopilot, autosteer, lane and parking brake finds only the two owner-set caps above. `GetVehicleData` (`car_server.proto`) lists every state the car can be asked for: charge, climate, drive, location, closures, schedules, tire pressure, media, software update, parental controls.
- **Validated:** 2026-11-13, by reading the proto files. Owner decision of 2026-11-12: icons with no car data are left out until hardware exists.
- **Decays when:** the proto files are updated from upstream and gain such a field, or the app adds another data source (Fleet API, OBD, map data).

## Music is in the protocol but unverified on the car

The protocol defines media state: `GetMediaState` and `GetMediaDetailState` requests, and `MediaState` / `MediaDetailState` replies with now-playing title, artist, source, playback status, duration and elapsed time. The app does not request them yet, and nobody has checked that the owner's car answers over Bluetooth.

Treat a music card as possible but unproven. Verify in the car before designing around it.

- **Evidence:** `ios-app/Packages/TeslaBLE/Protos/vehicle.proto` (`MediaState`, `MediaDetailState`) and `car_server.proto` (`GetMediaState`, `GetMediaDetailState`). No Swift source outside generated code refers to them.
- **Validated:** 2026-11-13, protocol only. Not validated on the car.
- **Decays when:** an in-car run shows whether the car returns media state, or the app starts requesting it.
