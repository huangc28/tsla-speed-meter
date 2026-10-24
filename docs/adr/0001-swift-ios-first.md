# 0001 — Native Swift, iPhone first

- Status: accepted (2026-10-22)
- Supersedes: the 2026-06 choice of Flutter for one iOS + Android codebase; "Android in v1" from the market research.
- Ruling: `docs/design/00-rulings.md` L59

## Context

The app reads speed, gear, battery, range and tire pressure from the car over Tesla's native BLE protocol, falls back to phone GPS speed, and shows one landscape gauge. A Flutter app exists (about 1,400 lines of Dart plus about 640 hand-written lines of BLE protocol code on `feature/goal-2-ble`). The owner asked whether native code would be smoother to build.

Facts gathered on 2026-10-21:

- iPhone is about 55–60% of phones in Taiwan and the US (StatCounter, GfK), and about 65% of US Tesla drivers (Strategic Vision via InsideEVs, 2025-11). Every competing app found is iOS-only.
- The hard parts lean native on iOS: long-running BLE and state restoration (CoreBluetooth), car-key storage (Keychain, optionally Secure Enclave), Live Activities / Picture-in-Picture, and trial gating with a Tier-0 non-consumable (StoreKit 2).
- `flutter_blue_plus` 2.x needs a paid licence for for-profit use; BSD alternatives exist (`flutter_reactive_ble`, `universal_ble`). Its iOS background support is unmaintained.
- Swift references exist: Moblin (MIT, shipping, reads Tesla drive and charge state over BLE) and `shoujiaxin/swift-tesla-ble` (MIT).

## Decision

Rewrite the app in native Swift (SwiftUI, CoreBluetooth, CryptoKit, StoreKit 2). Ship iPhone only in v1. Decide on an Android app in Kotlin after launch, based on traction.

## Consequences

- Android users (about 40%) are not served in v1. The Android local trial and pricing test are deferred.
- `docs/design/04-feasibility.md` assumes Flutter and needs an iOS version. `DESIGN.md` is mostly framework-neutral.
- The Flutter code and `feature/goal-2-ble` are kept as reference and not extended. Issues #23–#25 become acceptance tests in the Swift app (`HUDCore`) instead of Flutter fixes.
  - 2026-10-24 update: the Swift app has passed the Flutter app, so the owner had the Flutter code removed from `main`. It stays in git history (last present at `9e621ba`) and on `feature/goal-2-ble`.
- The Swift app lives in `ios-app/` (XcodeGen project, local packages `HUDCore` and `TeslaBLE`). Work is tracked in #27–#31.
- The car key is never kept in plain storage (the Flutter spike used `shared_preferences`); Keychain at minimum, Secure Enclave as a follow-up.
