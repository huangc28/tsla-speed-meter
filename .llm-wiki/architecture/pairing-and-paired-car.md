# Pairing and the paired car

## Only pairing decides which car is paired

The paired VIN lives in the Keychain (service `com.tslaspeedmeter.hud.tesla-ble`, account `paired-vin`). It is the one source of truth for which car is paired.

- **Who writes it:** only the pairing coordinator (`ios-app/App/Pairing/PairingFlow.swift`). It calls `CarFeed.storePairedVIN` after S17's read has returned drive data.
- **Who never writes it:** the Bluetooth client and the test page (行車紀錄). The test page's VIN field is only a testing override.
- **The commit point:** the write itself.
  - A cancel before the write stores nothing.
  - A cancel during the write leaves the new car paired, and the screen just closes.
- **Cancel and 稍後再說:** they always end on the paired car, or on no car. Whenever `CarFeed.targetVIN != pairedVIN`, they call `returnToPairedCar()`.

Evidence and status:
- **Evidence:** #55 (PR #64). `PairingFlowTests` covers `readMustComeBack`, `cancelDuringStore`, `cancelBeforeStore` and `cancelReturnsFromTestPageCar`.
- **Validated:** 2026-10-25 by an independent reviewer with mutation checks, plus a Codex cross-review.
- **Decays when:** a second way to pair is added, for example the camera VIN scan (#57) or a settings screen (#59), and it writes the VIN on its own.

## Reconnect by identifier only for the same car

`CoreBluetoothLink` reuses a known peripheral's identifier only when the target's local name (derived from the VIN) matches. Otherwise, a connect to car B could silently reuse car A's connection. After a state restoration, the restored peripheral's name stands in for the local name until the next connect.

- **Evidence:** `ios-app/App/BLE/CoreBluetoothLink.swift` (#55).
- **Not yet handled:** an auto-reconnect of the old car can still finish a new car's pending connect. Authentication fails, because the session HMAC includes the VIN, so no wrong car is paired. This is recorded on #60.
- **Decays when:** the link is rewritten, or the auto-reconnect issue on #60 is fixed.
