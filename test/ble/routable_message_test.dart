import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsla_speed_meter/src/ble/gen/universal_message.pb.dart';

void main() {
  // Verifies the generated Tesla protobuf bindings round-trip the BLE transport
  // envelope (RoutableMessage) the spike shell will send during key enrollment.
  group('RoutableMessage (generated protobuf)', () {
    test('round-trips a session-info-request enrollment envelope', () {
      final sent = RoutableMessage()
        ..toDestination = (Destination()..domain = Domain.DOMAIN_VEHICLE_SECURITY)
        ..fromDestination =
            (Destination()..routingAddress = Uint8List.fromList([1, 2, 3, 4]))
        ..sessionInfoRequest = (SessionInfoRequest()
          ..publicKey = Uint8List.fromList([4, 9, 9, 9])
          ..challenge = Uint8List.fromList([7, 7]))
        ..uuid = Uint8List.fromList([0xab, 0xcd]);

      final wire = sent.writeToBuffer();
      final got = RoutableMessage.fromBuffer(wire);

      expect(got.whichPayload(), RoutableMessage_Payload.sessionInfoRequest);
      expect(got.toDestination.domain, Domain.DOMAIN_VEHICLE_SECURITY);
      expect(got.fromDestination.whichSubDestination(),
          Destination_SubDestination.routingAddress);
      expect(got.fromDestination.routingAddress, [1, 2, 3, 4]);
      expect(got.sessionInfoRequest.publicKey, [4, 9, 9, 9]);
      expect(got.sessionInfoRequest.challenge, [7, 7]);
      expect(got.uuid, [0xab, 0xcd]);
    });
  });
}
