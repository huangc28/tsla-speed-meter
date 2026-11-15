# Can we get road speed limit, Autopilot state, lane state and parking brake from the car some other way?

Date: 2026-11-16. Scope: native Swift iPhone app, Tesla BLE only, no Tesla account, no internet (the owner's own car, Taiwan market). "[unverified]" marks anything I could not confirm from a primary source. "Community" marks reverse-engineered or third-party work.

**Short answer.** We are not asking the wrong way for (a), (c) and (d). I found no BLE route, and no Tesla-published route of any kind except Fleet Telemetry (internet, server, account), that gives a live road speed limit, lane-departure state or parking-brake state.

- **(a) Road speed limit:** The car knows it (CAN signals `UI_mapSpeedLimit`, `DAS_fusedSpeedLimit`), but no Tesla API or BLE field exposes it. The only phone-only way is a map SDK, and the one fully checked (Google Navigation SDK) lists Taiwan speed limits as "not supported".
- **(b) Autopilot/TACC engaged:** Not found on BLE. A community-named field, `drive_state #25 = fsd_active`, sits in a message we already receive. It stayed 0 in run 2, so we cannot yet tell whether it never fires or whether run 2 simply did not use FSD. Fleet Telemetry has `CruiseSetSpeed` (live cruise set point) but needs a server and internet.
- **(c) Lane-keeping state:** None. Fleet Telemetry's two lane fields are settings (Off/Warning/Assist), not live state. Only CAN carries live state (`DAS_laneDepartureWarning`).
- **(d) Parking brake:** None by name anywhere on BLE or Fleet Telemetry (Semi trucks only). Live state exists only on CAN (`DI_parkBrakeState`). `charge_state #195` (1 exactly in P) remains unnamed in every source I found.
- **Our unknown fields are not mysteries.** A community proto (Teslemetry `tesla-protocol`) names nearly all of them. They are FSD statistics, low-power-mode flags and similar, none of them (a)-(d). See section 1.

## Sources
- U1 Upstream `teslamotors/vehicle-command`, `pkg/protocol/protobuf/{vehicle,car_server,vcsec}.proto` (raw.githubusercontent.com, main branch, fetched 2026-11-16). Diffed against our local copies.
- U2 GitHub API commit list for U1 `vehicle.proto` (api.github.com).
- T1 `teslamotors/fleet-telemetry` `protos/vehicle_data.proto` (main) and README. Commit list via GitHub API.
- T2 developer.tesla.com "Fleet Telemetry - Available Data" (`/docs/fleet-api/fleet-telemetry/available-data`).
- T3 developer.tesla.com "Vehicle endpoints" (`/docs/fleet-api/endpoints/vehicle-endpoints`).
- C1 Community: `Teslemetry/tesla-protocol` (GitHub, Apache-2.0, 4 stars, last push 2026-11-11), `proto/command/{vehicle,car_server}.proto`. A third-party fork of U1 with "TESLEMETRY-EXT" additions. Provenance of the additions is not stated.
- C2 Community, deprecated: tesla-api.timdorr.com `vehicle/state/vehiclestate` and `drivestate` pages.
- D1 Community: `commaai/opendbc` (MIT), `opendbc/dbc/tesla_model3_party.dbc`, `tesla_can.dbc`, `tesla_powertrain.dbc` (master, fetched).
- B1 Tesla service bulletin CD-20-17-001 R4 "Model 3/Y Third-Party CAN Bus Interface". **Not read.** The URL (service.tesla.com/docs/ServiceBulletins/External/CD/...) returned 404, and a Wayback fetch was blocked by the tool's permission check. I only have a search-tool summary of it.
- E1 Community, search summaries only: teslatap.com CAN pages, ScanMyTesla adapter page, vendor shops.
- A1 Apple docs `MKRoute` (developer.apple.com/documentation/mapkit/mkroute.md, page footer "2026").
- G1 Google Navigation SDK for iOS, coverage page (developers.google.com/maps/documentation/navigation/ios-sdk/coverage-nav-sdk).
- G2 Google Roads API "Speed limits" (developers.google.com/maps/documentation/roads/speed-limits).
- M1 Mapbox Directions API reference (docs.mapbox.com/api/navigation/directions/), first 100k characters only.
- H1 HERE SDK for iOS coverage information (docs.here.com/here-sdk/docs/ios-coverage-information).
- O1 OpenStreetMap wiki Taiwan page (search hit only).

## 1. Other BLE requests, and what the unknown fields are

### 1a. VCSEC (the key/security channel) has no driving data
**Fetched (U1, same as our local `vcsec.proto`).**
- `InformationRequestType` has three values: `GET_STATUS`, `GET_WHITELIST_INFO`, `GET_WHITELIST_ENTRY_INFO`.
- `VehicleStatus` contains only `closureStatuses` (doors, trunks, charge port, tonneau), `vehicleLockState`, `vehicleSleepStatus`, `userPresence` and `detailedClosureStatus`.
- Nothing about speed, assist, lane or brake.

### 1b. Upstream CarServer has nothing more to ask
**Fetched (U1).**
- Our local `vehicle.proto` is byte-identical to upstream main. Upstream's last change to it was 2024-12-06 (U2, "BLE location support").
- Our local `vcsec.proto` is identical.
- Local `car_server.proto` differs only by upstream's five newer parental-control actions (#109-#113).
- Upstream `GetVehicleData` has exactly 12 groups and marks request numbers 5, 6, 12, 13 as `reserved`. So the "12 groups" probe was the whole published request.
- Upstream `DriveState` publishes only gear, speed, power, odometer, route fields. The car already sends more fields than the published proto (our unknown fields), so the published proto lags the firmware.

### 1c. A community proto names almost every unknown field
**Fetched (C1).** Teslemetry's `vehicle.proto` extends upstream with fields marked `TESLEMETRY-EXT`. Some carry the comment "UNCONFIRMED: not yet confirmed on a live vehicle", others "confirmed on a live vehicle". It says nothing about where the names came from [unverified: provenance]. The fit with your observed values is strong:

| Message / field | Teslemetry name (type) | Your observation | Fit |
|---|---|---|---|
| drive #16 | `fsd_user_total_miles_travelled` (float) | float, lifetime miles, changes | fits |
| drive #17 | `fsd_user_total_miles` (float) | 0.6872, constant | fits (type); meaning: lifetime FSD-user miles |
| drive #18, #19 | `fsd_user_miles_hands_free_current / _max` (float) | never seen | proto3 omits zeros; not contradictory |
| drive #20 | `fsd_total_miles_this_month` (float) | 0.0 | fits |
| drive #21 | `fsd_monthly_history` (repeated: `year_month` string #1, `fsd_miles` float #2, `total_miles` float #3) | #21[n].#1 "YYYY-MM", #3 per-month miles | fits; #2 (`fsd_miles`) not reported, plausibly omitted because 0 |
| drive #22 | `fsd_streak_days` (int32) | 0 | fits |
| drive #23 | `fsd_last_7_days_usage` (`day_usage` repeated bool #2) | #23.#2 = 7 zero bytes | fits exactly (7 packed false) |
| drive #24 | `rainbow_road_enabled` (bool) | 1 | fits |
| drive #25 | `fsd_active` (bool) | 0 in both runs | name fits; see 1d |
| charge #186 | `discharge_limit_soe` (int32) | 20 | fits |
| charge #190 | `paid_session_start_time` (Timestamp) | a timestamp | fits |
| charge #191, #192, #194, #198 | `low_power_mode`, `low_power_mode_forced_on`, `keep_accessory_power_mode`, `should_hide_range_info` (bool) | 0 | fits |
| charge #193 | `convenience_features` (uint32) | 8, then 12 after parking | fits (bitfield-like) |
| charge #195, #196, #197 | **not named** in `ChargeState` (196-198 appear only in other messages) | #195 = 1 only in P; #196 = 0; #197 = 100 | **no name** |
| climate #154 | `dog_mode_state` (enum) | 2 | fits |
| media_detail #8, #10 | `recent_theater_source` (enum), `theater_source_is_playing` (bool) | 1, 0 | fits |
| parental #10-#12 | `browser_blocked`, `theater_blocked`, `arcade_blocked` (bool) | 0 | fits |
| VehicleData #999 | `supports_optional_fields` (bool) | 1 | fits |
| location #122-#128 | `native_latitude_d`, `native_longitude_d`, `geo_latitude_d`, `geo_longitude_d`, `geo_hw_raw_*`, `geo_horizontal_accuracy` | extra coordinate pairs and an accuracy value | fits |

Mismatches to note: #195 (the possible parking brake) and #196/#197 have no name anywhere I looked. `drive #17`'s meaning is inferred from the name only. I did not check what #195 would be called in Tesla's own app.

**What this means.** Drive_state #16-#25 look like the Tesla mobile app's "FSD stats" screen. Those are mileage statistics, not a live "assist is on" flag (except possibly #25).

### 1d. Candidate for (b): `drive_state #25 fsd_active`
- **Fetched (C1):** `oneof optional_fsd_active { bool fsd_active = 25; }`, not marked UNCONFIRMED.
- **Observed:** 0 in run 1 (assist off) and run 2 (assist engaged for part).
- **Open question for the owner [needs answer]:** which feature was on in run 2: TACC only, Autosteer, or FSD (Supervised)? If it was not FSD, then #25 staying 0 is expected and says nothing about whether it works. A drive with FSD on would settle it.
- **Cheap test:** in run 2, `#17` (0.6872) and `#21[n].#2` did not change. If FSD had really been used for miles, these would likely move [inference, not verified]. That suggests run 2 was not FSD, or that these are updated only at the end of a drive or on the cloud side [unverified].
- **Limit:** I found nothing in C1 or U1 for plain Autopilot / Autosteer / TACC. A car without FSD may never set #25.

### 1e. Extra `GetVehicleData` groups and subscriptions (untested)
**Fetched (C1 only; no primary confirmation).** Teslemetry's `GetVehicleData` adds request fields that upstream marks reserved or lacks:
- 1 `getGuiSettings`
- 5 `getLegacyVehicleState`
- 6 `getVehicleConfig`
- 9 `getParkedAccessoryState`
- 12 `getSohState`
- 13 `getVehicleDetailState`
- 18 `getVehicleState`
- 20 `getAlertState`
- 21 `getLightShowState`
- 22 `getVehicleImageState`
- 23 `getSuspensionState`
- 25 `getChildPresenceDetectionState`
- 31 `getDisplayState`
- 34 `getKeepOnAccessoryPortsState` (UNCONFIRMED)

It also defines a `VehicleDataSubscription` action (rates for drive, vehicle, closures and other states; includes a PII-key exchange) and `VitalsSubscription` (just a `session_id`, no payload defined).

I read the field lists of the result messages:
- **`CurrentVehicleState` (group 18)** holds autopark state, headlights/hazards on, dashcam state, trailer mode, a `fsd_stats_supported` flag and similar. No speed limit, no Autopilot engaged, no lane, no parking brake.
- **`VehicleState` (group 5)** repeats `speed_limit_mode` (the owner's cap), `cruise_speed_limit_mph`, door/lock/sentry flags.
- **`VehicleDetailState` (13)** has `fsd_software_version`, `autopilot_hash`, `is_fsd_v14_or_above`. These are version strings.
- **`DisplayState`, `AlertState` (charging alerts only), `SuspensionState`** are unrelated.

So by name none of the extra groups carries (a), (c) or (d). Whether the car answers them over BLE is not established. A probe could still be tried (see Recommendations).

**Do not read `cruise_speed_limit_mph` as the road limit.** It sits in `ClosuresState` #30, and a Teslemetry action comment says it is set by `DrivingSetCruiseSpeedLimitAction`, so it is a user-set cruise cap [UNCONFIRMED in C1]. The Fleet Telemetry field with the same flavour, `SemiCruiseSpeedLimitMph`, is Semi-only (T2). You said closures #30 was never seen, consistent with it being absent or Semi-only.

### 1f. Other community decoders
I searched for Go, Python, Rust, JS and Swift BLE libraries that track newer `vehicle.proto`. Only C1 (Python/TS/Go packages generated from one proto set) showed named extra fields. I did not open any other repo. `acvigue/teslaprotobufs` was last pushed in 2023 (search summary) [unverified]. I did not read the TMC BLE thread or the TeslaBLEKeyKit Swift package source.

## 2. Fleet API `vehicle_data` (internet)
- **Needs:** a Tesla account, an OAuth token, and internet (T3). It is the wrong channel for a "no account, no internet" app.
- **What it returns:** developer.tesla.com (T3) lists the endpoint but **not** the response keys, so I could not check them there. T2 maps several streamed fields to a "Vehicle Data equivalent":
  - `Gear` -> `drive_state.shift_state`
  - `SpeedLimitMode` -> `vehicle_state.speed_limit_mode.active`
  - `CurrentLimitMph` -> `vehicle_state.speed_limit_mode.current_limit_mph`
  - `CruiseSetSpeed`, `LaneDepartureAvoidance`, `SpeedLimitWarning`, `SelfDrivingMilesSinceReset` and others show **no Vehicle Data equivalent**.
- **Community, deprecated (C2):** old `vehicle_state` keys include `speed_limit_mode`, `autopark_state_v2`, `smart_summon_available`, `is_user_present`. The old `drive_state` has gps, heading, power, `shift_state`, speed. No cruise, lane or park-brake key.
- **Verdict:** does not expose (a)-(d) per T2 and C2. "Does not expose" is [unverified] against a live response. Cached `vehicle_data_cached` never contains `drive_state` (T3).

## 3. Fleet Telemetry (car streams to a server)
**Fetched (T1 enum, T2 descriptions).** Matches in `Field`:

| Field (#) | Type | What T2 says | Matches |
|---|---|---|---|
| `CruiseSetSpeed` (101) | real | "Cruise control set point." | (b) partly: a live set point, presumably zero/absent when cruise is off [unverified] |
| `CruiseFollowDistance` (126) | enum | setting | no |
| `LaneDepartureAvoidance` (131) | `LaneAssistLevel` None/Warning/Assist | "The lane assist level selected in vehicle settings." | (c): **setting only**, not live state |
| `EmergencyLaneDepartureAvoidance` (132) | bool | setting | (c): setting only |
| `SpeedLimitWarning` (129) | `SpeedAssistLevel` None/Display/Chime | "The speed assist level selected in vehicle settings." | (a): setting only; no road limit |
| `SpeedLimitMode` (66), `CurrentLimitMph` (67) | bool, real | owner's cap | not the road limit |
| `SemitruckTractorParkBrakeStatus` (104), `...TrailerParkBrakeStatus` (105) | enum | "The state of the Semi's tractor park brake." | (d): **Semi only** (field comment in T1: "Semi-truck only") |
| `Gear` (10), `BrakePedal` (13), `BrakePedalPos` (106) | enum, bool, real | gear, foot brake | (d) stand-in only; not the parking brake |
| `AutomaticEmergencyBrakingState` (274) | enum | AEB state | no |
| `SelfDrivingMilesSinceReset` (259) | real | FSD miles; HW4 and firmware 2025.44.25.5+; needs `minimum_delta` >= 1 | (b) indirect, via miles that grow while FSD runs |
| `SelfDrivingSoftwareVersion` (278) | string | FSD version string; firmware 2026.44.3+ | no |

There is no Autopilot or Autosteer engaged field, and no "road speed limit" field. T2 states it does not use the word "Autopilot".

**Requirements (T1 README, fetched):**
- You host the server (public hostname, TLS, mTLS) that the car connects to.
- A Tesla developer application, Fleet API registration, and your app's virtual key paired to each car.
- Firmware 2023.20.6 or later; some older Model S/X are not supported.
- The car needs its own network connection (it streams out over the cellular/Wi-Fi link).
- The README never mentions phone apps.

**Could a phone-only app use it?** No. It is a car-to-server stream. The data would reach a server, not the phone over BLE. The phone could read it back from that server, but that needs internet and an account, which we have ruled out.

## 4. CAN bus via OBD or third-party hardware
**Fetched (D1: opendbc, community reverse engineering, MIT-licensed).** Signals found in `tesla_model3_party.dbc` and `tesla_can.dbc`:

| Need | Message (ID) / signal | Values |
|---|---|---|
| (a) road limit | `DAS_status` (923) `DAS_fusedSpeedLimit` (5-bit, step 5 kph/mph; 31 = NONE, 0 = UNKNOWN_SNA); `DAS_visionOnlySpeedLimit`; in `tesla_can.dbc` also `UI_mapSpeedLimit`, `UI_mppSpeedLimit`, `UI_baseMapSpeedLimitMPS` | units flag: `UI_mapSpeedLimitUnits` |
| (b) engaged | `DAS_status` (923) `DAS_autopilotState` | 0 DISABLED, 1 UNAVAILABLE, 2 AVAILABLE, 3 ACTIVE_NOMINAL, 4 ACTIVE_RESTRICTED, 5 ACTIVE_NAV, 6 ACTIVE_FSD, 8 ABORTING, 9 ABORTED, 14 FAULT, 15 SNA |
| (b) cruise | `DI_state` (646) `DI_cruiseState`; `DAS_control` (697) `DAS_accState` | `DI_cruiseState`: 0 UNAVAILABLE, 1 STANDBY, 2 ENABLED, 3 STANDSTILL, 4 OVERRIDE, 5 FAULT, 6 PRE_FAULT, 7 PRE_CANCEL |
| (c) lane | `DAS_status` (923) `DAS_laneDepartureWarning` | 0 NONE, 1 LEFT_WARNING, 2 RIGHT_WARNING, 3 LEFT_WARNING_SEVERE, 4 RIGHT_WARNING_SEVERE, 5 SNA; also `DAS_autoLaneChangeState`, `DAS_autopilotHandsOnState` |
| (d) park brake | `DI_state` (646) `DI_parkBrakeState`; also `DI_epbRequest`, `MCU_parkBrakeRequest` | 0 UNAVAILABLE, 1 RELEASED, 2 REQUESTED, 3 APPLIED, 4 FAULTED, 5 PANIC_EPB, 6 PANIC_SKID, 7 RELEASING, 15 SNA |

**This is the only place where all four exist.** The car does know them. They are not exposed by any Tesla API I found.

**Whether we can reach them is not established:**
- `DAS_status` is labelled on the `PARTY` bus in the DBC. Which bus the diagnostic connector reaches, and whether it carries `DAS_status`, I could not confirm. E1 (search summaries) says Model 3/Y expose a "Vehicle" bus on the 26-pin connector, and TeslaTap says "Party" is an alternate [unverified].
- **Taiwan.** B1 (a search summary of a Tesla bulletin that I could not open) says the third-party CAN interface is provided for Europe and Asia-Pacific "except Korea and Taiwan" [unverified; summary only, source page 404]. If true, it is a direct blocker for a Taiwan car. It needs confirming against the real bulletin or with the owner's service centre.
- **Hardware:** a harness or adapter (26-pin to OBD-II), plus an adapter an iPhone can talk to. E1 says ScanMyTesla pairs with OBDLink LX/MX Bluetooth adapters, and one ELM327 clone "does not work on iOS". Whether iOS BLE CAN adapters can sniff these frames at full rate is [unverified]. ScanMyTesla's data is battery/motor; I found no evidence it shows Autopilot data [unverified].
- **Alternatives named in the community:** comma.ai panda (hardware that plugs into the Autopilot camera connector, supports Tesla) for sniffing the Autopilot bus; I did not research it beyond the DBC.
- **Risk:** adding hardware to the car is outside "BLE only", touches safety systems, and may affect warranty. This is not for the shipped app. It could be a one-off truth-finding experiment for the owner.

## 5. Map-based speed limit for Taiwan
- **Apple MapKit / Core Location (A1).** `MKRoute` (page footer 2026) has no speed-limit property: its properties are polyline, steps, name, highways/tolls flags, advisory notices, distance, travel time and transport type. A forum thread says Apple has no such API (undated). iOS 27 Maps news results covered Flyover, Local Lists and a Parked Car widget, with no MapKit speed-limit item. I did not read any WWDC25 or WWDC26 session, so "still none" is [unverified]. The iOS Maps app shows limits, but that is not an API.
- **Google (G1, G2).**
  - Navigation SDK for iOS, coverage table row for Taiwan: Traffic = supported, Driving Directions = supported, **Speed Limits = "---"**, which the legend defines as "not available in the area, or with low data quality or availability". That is a direct negative for Taiwan.
  - Roads API Speed Limits: needs an Asset Tracking licence; billed per entry; data "not real-time, and may be estimated, inaccurate, incomplete, or outdated"; sends coordinates to Google; country list not on the page.
- **Mapbox (M1).** Directions API `maxspeed` annotation exists (beta; driving profiles; with `overview=full`; may return "unknown"). The page lists no countries and does not mention Taiwan. It is a route-based request (internet, key, sends location). Pricing was not read. Taiwan coverage [unverified].
- **HERE (H1 + search).** The Navigate SDK exposes `LatestSpeedLimit` (page title only; the page 404'd on fetch). The iOS coverage page does not mention Taiwan or speed limits. HERE's own ISA map one-pager (search summary) lists worldwide coverage excluding Korea, China and Japan, which does not exclude Taiwan [unverified]. Licence, offline map download ("almost all areas can be downloaded", Navigate only) and cost were not checked. Taiwan coverage [unverified].
- **TomTom.** Two attempts to read the coverage page failed (redirect, then 404). A search hit shows a `SpeedLimitSection` in the iOS route API, which is route-based. Taiwan [unverified].
- **OpenStreetMap `maxspeed` for Taiwan.** No statistic found. The OSM Taiwan wiki's "Coverage rate" heading is empty (search summary). A 2022 OSM diary says `maxspeed` coverage is limited even for motorways and trunk roads (global, not Taiwan). I did not compute anything.
- **What a map route needs, in general.** Current position matched to a road (GPS is available on the phone, no car data needed), a source of limits (online API or offline data pack), a key, and possibly billing. This is the only family of routes that works with a phone alone, but Taiwan coverage is checked and negative for only one of five vendors.

## Recommendations
1. **Tell the owner:** the car holds these signals but does not offer them over BLE in anything published or community-documented, apart from the one open question on `fsd_active`.
2. **Ask which assist feature run 2 used** (TACC, Autosteer or FSD). If FSD was not on, repeat with FSD and watch `drive #25`, `#17` and `#21[n].#2`.
3. **Optional low-cost probe:** log-only `GetVehicleData` requests using the Teslemetry-only group numbers (5, 6, 13, 18 first). Expect an error or empty answer; no change to shipped behaviour. Per the names, it will not reveal (a), (c) or (d). Its value is only to complete the picture.
4. **(d) Parking brake:** keep treating charge #195 as "in P". If you label it, say "shift state P" not "parking brake". Using gear P as a stand-in for the brake is my judgement, not a sourced equivalence.
5. **(a) Speed limit:** if wanted, evaluate HERE and TomTom Taiwan coverage with a real key before committing. Google is ruled out for Taiwan by its own table.

## What I did not check
- Real Fleet API `vehicle_data` response (no account).
- Fleet Telemetry availability in Taiwan, or whether any Taiwan car supports it.
- The Tesla CAN bulletin B1 itself.
- Which CAN bus a Taiwan car's connector reaches.
- iOS-compatible CAN hardware behaviour.
- WWDC25/26 MapKit session content.
- Pricing and Taiwan coverage for HERE, TomTom and Mapbox.
- Other BLE decoder repos beyond C1, and whether C1's extra BLE groups work on a real car.
- Tesla's own app or release notes for any change in how the speed limit is shown.

## Summary table

| Signal | Route | Available? | Needs internet or account | Needs hardware | Confidence |
|---|---|---|---|---|---|
| (a) road limit | BLE `GetVehicleData` (12 groups) | No | no | no | High (asked and checked, both runs) |
| (a) | VCSEC `VehicleStatus` | No | no | no | High (proto read) |
| (a) | Extra BLE groups (Teslemetry names) | No field named | no | no | Medium (names only; untested) |
| (a) | Fleet API `vehicle_data` | No evidence | yes, account | no | Medium |
| (a) | Fleet Telemetry | Setting only (`SpeedLimitWarning`); no road limit | yes, server, developer account, virtual key | no | High (enum read) |
| (a) | CAN (`DAS_fusedSpeedLimit`, `UI_mapSpeedLimit`) | Yes, on the car | no | yes, CAN adapter | Medium (DBC community); Taiwan access [unverified] |
| (a) | Google Navigation SDK | No for Taiwan | yes, key and billing | no | High (table read) |
| (a) | Apple MapKit | No public API | n/a | no | Medium-high (MKRoute read; WWDC not read) |
| (a) | HERE / TomTom / Mapbox | Unknown for Taiwan | yes, key and billing | no | Low |
| (a) | OSM `maxspeed` | Unknown, no statistic found | no (if bundled) | no | Low |
| (b) Autopilot/TACC | BLE 12 groups | Only `drive #25 fsd_active` (community name), 0 in run 2 | no | no | Low-medium (undecided; depends on run 2 feature) |
| (b) | Extra BLE groups | No field named | no | no | Medium |
| (b) | Fleet API | No evidence | yes | no | Medium |
| (b) | Fleet Telemetry | `CruiseSetSpeed` (live); `SelfDrivingMilesSinceReset` (FSD miles, HW4); no Autopilot-engaged flag | yes, server and account | no | High (enum), cruise semantics [unverified] |
| (b) | CAN (`DAS_autopilotState`, `DI_cruiseState`) | Yes, on the car | no | yes | Medium (DBC community) |
| (c) lane state | BLE (all groups tried, plus extras by name) | No | no | no | High / Medium |
| (c) | Fleet Telemetry | Setting only (`LaneDepartureAvoidance`) | yes | no | High |
| (c) | CAN (`DAS_laneDepartureWarning`) | Yes, on the car | no | yes | Medium |
| (d) parking brake | BLE | No (gear P only; `charge #195` unnamed) | no | no | High (no field) / Medium (#195) |
| (d) | Fleet Telemetry | Semi only | yes | no | High |
| (d) | CAN (`DI_parkBrakeState`) | Yes, on the car | no | yes | Medium |
| (a)-(d) | CAN, Taiwan market | Unclear: a search summary says no third-party CAN interface in Taiwan | no | yes | Low ([unverified], source not read) |
