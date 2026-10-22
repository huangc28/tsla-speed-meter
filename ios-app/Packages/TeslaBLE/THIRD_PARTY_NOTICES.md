# Third-party notices

## teslamotors/vehicle-command

https://github.com/teslamotors/vehicle-command — Apache License 2.0
(https://www.apache.org/licenses/LICENSE-2.0). The repository has no NOTICE
file.

- `Protos/*.proto` are copied from `pkg/protocol/protobuf/`, and
  `Sources/TeslaBLE/Generated/*.pb.swift` are generated from them.
- Adapted into Swift: the metadata serializer
  (`internal/authentication/metadata.go`), request/response metadata and the
  request hash (`internal/authentication/peer.go`), response decryption
  (`internal/authentication/signer.go`, `verifier.go`), the session-info HMAC
  (`internal/authentication/native.go`), the anti-replay sliding window
  (`internal/authentication/window.go`) and the key-enrollment envelope
  (`pkg/vehicle/security.go`).
- Test vectors are taken from `pkg/protocol/protocol.md`,
  `internal/authentication/protocol_doc_test.go`, `verifier_test.go` and
  `window_test.go`. `Tools/zz_emit_vector_test.go` calls this library to
  produce a further vector.

Changes: translated from Go to Swift and reduced to the client side.

## eerimoq/moblin

https://github.com/eerimoq/moblin — MIT License.

Copyright (c) 2023 Erik Moqvist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

`Moblin/Integrations/Tesla/TeslaVehicle.swift` was used as a cross-check for
the response metadata (`createResponseMetadata`), the CryptoKit ECDH/SHA1 key
derivation and the key-enrollment envelope (`addKeyRequestWithRole`).

## apple/swift-protobuf

https://github.com/apple/swift-protobuf — Apache License 2.0 with Runtime
Library Exception. Used as a SwiftPM dependency and to generate
`Sources/TeslaBLE/Generated/`.
