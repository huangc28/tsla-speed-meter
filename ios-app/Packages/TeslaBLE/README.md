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
