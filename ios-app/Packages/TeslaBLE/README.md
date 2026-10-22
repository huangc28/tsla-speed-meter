# TeslaBLE

Protocol core for reading vehicle data from a Tesla over its native BLE
protocol (teslamotors/vehicle-command). Pure Swift + CryptoKit + SwiftProtobuf;
no CoreBluetooth, so `swift test` runs on a Mac. The app owns the transport
(GATT UUIDs are in `TeslaBLEConstants`).

Flow for one domain:

1. `TeslaRequests.sessionInfoRequest(...)`, send, keep its `uuid`.
2. `VehicleSession(sessionInfoResponse:requestUUID:vin:clientKey:)` verifies
   the session-info HMAC and derives the AES-GCM key.
3. `session.sign(payload: TeslaRequests.getVehicleDataAction().serializedData())`
   gives a `SignedRequest`; send `request.message`.
4. `session.openResponse(reply, to: &request)` authenticates and decrypts the
   reply (request hash + anti-replay counter); then
   `VehicleReading(responsePlaintext:)`.

Key enrollment (one time): `TeslaRequests.addKeyToWhitelist(publicKey:)`,
written as-is (not in a RoutableMessage); the owner taps a key card.

## Message layer

`TeslaVehicleClient` (an actor) runs the flow above over any `BLELink`
(the app's `CoreBluetoothLink`, or `MockLink` in tests) and a
`TeslaKeyStore` (the app's Keychain store):

- `connect(vin:)`, `enrollKey(onStateChange:)`, `startSessions()`,
  `fetchVehicleData() -> VehicleReading`, `disconnect()`.
- `events`: an `AsyncStream<TeslaClientEvent>` with connect, disconnect,
  handshake, request, response (with ms), fault, timeout and enrollment
  events; whole raw messages too when `captureRawFrames` is set. One
  consumer only; while nobody reads, the newest 1,000 events are kept.
- Framing (`TeslaFraming`, `FrameAssembler`) follows vehicle-command
  pkg/connector/ble: 2-byte big-endian length prefix, writes of at most
  MTU - 3 bytes, a > 1 s gap between notifications drops a partial message.
- Replies are matched by routing address (plus `request_uuid` outside
  VCSEC); a retriable fault is resynced once (session info in the fault,
  else a new handshake) and retried once. Every wait has a timeout.
- Vehicle public keys are pinned per VIN and domain on first session; the
  pins and the paired VIN are read once and kept in memory, so a
  re-handshake works while the phone is locked.
- One handshake per domain is in flight at a time, shared by all callers,
  and a session's counter never goes back within an epoch. Encrypted
  replies are authenticated before their fault is acted on. BUSY, TIMEOUT
  and INTERNAL are resent on the same session after 1 s. Requests end at
  once when their Task is cancelled.

Enrollment (`enrollKey`): VCSEC session info first (no answer:
`.vehicleUnreachable`, no card prompt); if VCSEC does not know the key,
send add-key, show the card prompt and poll VCSEC session info; then poll
Infotainment until it knows the key (vehicle-command security.go
`SendAddKeyRequest`), and only then store the paired VIN. WAIT, retriable
faults, replies without session info and timeouts are "not yet"; it ends on
success, a specific whitelist rejection code, or the timeout. Polling VCSEC
session info while the vehicle waits for the card tap is not verified on a
real car yet (vehicle-command does not poll; it only checks Infotainment).

## Generated code

`Sources/TeslaBLE/Generated/*.pb.swift` were generated once from `Protos/`
(the protos on `feature/goal-2-ble`, commit 1bab91b, copied from
teslamotors/vehicle-command) with protoc 35.0 and `protoc-gen-swift` built
from apple/swift-protobuf 1.38.1 (the pinned version):

```sh
cd Protos
protoc --plugin=protoc-gen-swift=<swift-protobuf-1.38.1>/.build/release/protoc-gen-swift \
  --swift_opt=Visibility=Public --swift_out=../Sources/TeslaBLE/Generated \
  -I . -I /opt/homebrew/include \
  car_server.proto common.proto errors.proto keys.proto managed_charging.proto \
  signatures.proto universal_message.proto vcsec.proto vehicle.proto
```

`google/protobuf/timestamp.proto` is not generated; SwiftProtobuf ships
`Google_Protobuf_Timestamp`. Regenerate whenever the swift-protobuf pin moves.

## Test vectors

From vehicle-command `pkg/protocol/protocol.md` and
`internal/authentication` tests, from the Dart port, and one response vector
produced by vehicle-command's own Verifier (`Tools/zz_emit_vector_test.go`).
