import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../data/reading.dart';
import 'ble_transport.dart';
import 'gen/car_server.pb.dart' as cs;
import 'gen/keys.pbenum.dart' as keys;
import 'gen/signatures.pb.dart' as sig;
import 'gen/universal_message.pb.dart' as um;
import 'gen/vcsec.pb.dart' as vcsec;
import 'tesla_gcm.dart';
import 'tesla_key_store.dart';
import 'tesla_metadata.dart';
import 'tesla_reading_mapper.dart';
import 'tesla_session.dart';

/// Orchestrates the Tesla BLE handshake on top of the (tested) protocol core:
/// session-info exchange → key derivation → one-time enrollment → signed
/// GetVehicleData → Reading. UNTESTED end-to-end — meant to be run against a
/// real car during the #11 spike. Every frame is logged (raw hex) so that even
/// a partial/failed exchange yields captures we can turn into fixtures.
class TeslaBleClient {
  final String vin;
  final void Function(String) log;

  late final BleTransport _transport;
  TeslaKeyStore? _keys;

  // Session state from the most recent SessionInfo (per domain).
  Uint8List? _vehiclePublicKey;
  Uint8List? _epoch;
  int _counter = 0;
  int _clockTime = 0;
  Uint8List? _sessionKey;

  Completer<sig.SessionInfo>? _sessionInfoWaiter;

  TeslaBleClient({required this.vin, required this.log});

  Future<void> start() async {
    _transport = BleTransport(log);
    _transport.messages.listen(_onMessage);
    _keys = await TeslaKeyStore.loadOrCreate();
    log('Client key (public): ${_hex(_keys!.publicKey)}');
    await _transport.connectToVin(vin);
  }

  /// Step 1 — request session info from a domain and derive the AES key.
  Future<void> requestSessionInfo(um.Domain domain) async {
    final waiter = _sessionInfoWaiter = Completer<sig.SessionInfo>();
    final msg = um.RoutableMessage()
      ..toDestination = (um.Destination()..domain = domain)
      ..fromDestination =
          (um.Destination()..routingAddress = _randomBytes(16))
      ..sessionInfoRequest = (um.SessionInfoRequest()
        ..publicKey = _keys!.publicKey
        ..challenge = _randomBytes(16))
      ..uuid = _randomBytes(16);

    log('→ SessionInfoRequest (domain ${domain.name})');
    await _transport.send(msg.writeToBuffer());

    final info = await waiter.future
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException('No SessionInfo response');
    });

    _vehiclePublicKey = Uint8List.fromList(info.publicKey);
    _epoch = Uint8List.fromList(info.epoch);
    _counter = info.counter;
    _clockTime = info.clockTime;
    _sessionKey = TeslaSession.deriveSessionKey(
      clientPrivateKey: _keys!.privateKey,
      vehiclePublicKey: _vehiclePublicKey!,
    );
    log('✓ Session: status=${info.status.name} epoch=${_hex(_epoch!)} '
        'counter=$_counter clock=$_clockTime');
    log('✓ Derived session key: ${_hex(_sessionKey!)}');
  }

  /// Step 2 — enroll this phone key (one-time). Unsigned; the vehicle authorizes
  /// it when the owner taps a paired NFC key card on the center console.
  Future<void> enrollKey() async {
    final unsigned = vcsec.UnsignedMessage()
      ..whitelistOperation = (vcsec.WhitelistOperation()
        ..addKeyToWhitelistAndAddPermissions = (vcsec.PermissionChange()
          ..key = (vcsec.PublicKey()..publicKeyRaw = _keys!.publicKey)
          ..keyRole = keys.Role.ROLE_DRIVER)
        ..metadataForKey =
            (vcsec.KeyMetadata()..keyFormFactor = vcsec.KeyFormFactor.KEY_FORM_FACTOR_IOS_DEVICE));

    final msg = um.RoutableMessage()
      ..toDestination =
          (um.Destination()..domain = um.Domain.DOMAIN_VEHICLE_SECURITY)
      ..fromDestination = (um.Destination()..routingAddress = _randomBytes(16))
      ..protobufMessageAsBytes = unsigned.writeToBuffer()
      ..uuid = _randomBytes(16);

    log('→ Enroll key (WhitelistOperation). TAP YOUR KEY CARD ON THE CONSOLE NOW.');
    await _transport.send(msg.writeToBuffer());
  }

  /// Step 3 — signed GetVehicleData (drive + charge). Returns a [Reading] if the
  /// response could be decrypted/decoded; otherwise null (raw frame is logged).
  Future<Reading?> readVehicleData() async {
    if (_sessionKey == null) {
      throw StateError('Call requestSessionInfo(DOMAIN_INFOTAINMENT) first');
    }
    final action = cs.Action()
      ..vehicleAction = (cs.VehicleAction()
        ..getVehicleData = (cs.GetVehicleData()
          ..getDriveState = cs.GetDriveState()
          ..getChargeState = cs.GetChargeState()));
    final plaintext = action.writeToBuffer();

    _counter += 1;
    final expiresAt = _clockTime + 30;
    final metadata = TeslaSignatureMetadata.serialize(
      signatureType: sig.SignatureType.SIGNATURE_TYPE_AES_GCM_PERSONALIZED.value,
      domain: um.Domain.DOMAIN_INFOTAINMENT.value,
      vin: vin,
      epoch: _epoch!,
      expiresAt: expiresAt,
      counter: _counter,
    );
    final nonce = _randomBytes(12);
    final enc = TeslaGcm(_sessionKey!).encrypt(nonce, plaintext, metadata);

    final msg = um.RoutableMessage()
      ..toDestination =
          (um.Destination()..domain = um.Domain.DOMAIN_INFOTAINMENT)
      ..fromDestination = (um.Destination()..routingAddress = _randomBytes(16))
      ..protobufMessageAsBytes = enc.ciphertext
      ..uuid = _randomBytes(16)
      ..signatureData = (sig.SignatureData()
        ..signerIdentity = (sig.KeyIdentity()..publicKey = _keys!.publicKey)
        ..aESGCMPersonalizedData = (sig.AES_GCM_Personalized_Signature_Data()
          ..epoch = _epoch!
          ..nonce = nonce
          ..counter = _counter
          ..expiresAt = expiresAt
          ..tag = enc.tag));

    log('→ Signed GetVehicleData (counter=$_counter)');
    await _transport.send(msg.writeToBuffer());
    return null; // decoded asynchronously in _onMessage; see logs
  }

  // --- inbound routing ------------------------------------------------------

  void _onMessage(Uint8List bytes) {
    um.RoutableMessage msg;
    try {
      msg = um.RoutableMessage.fromBuffer(bytes);
    } catch (e) {
      log('!! could not parse RoutableMessage: $e');
      return;
    }

    if (msg.hasSignedMessageStatus() &&
        msg.signedMessageStatus.signedMessageFault !=
            um.MessageFault_E.MESSAGEFAULT_ERROR_NONE) {
      log('!! vehicle fault: ${msg.signedMessageStatus.signedMessageFault.name}');
    }

    switch (msg.whichPayload()) {
      case um.RoutableMessage_Payload.sessionInfo:
        final info = sig.SessionInfo.fromBuffer(msg.sessionInfo);
        _sessionInfoWaiter?.complete(info);
        _sessionInfoWaiter = null;
        break;
      case um.RoutableMessage_Payload.protobufMessageAsBytes:
        _tryDecodeVehicleData(msg);
        break;
      default:
        log('· inbound payload=${msg.whichPayload().name}');
    }
  }

  /// Best-effort response decode. The AES-GCM *response* metadata layout is not
  /// yet verified against a real frame, so failure here is expected on the first
  /// car run — the encrypted payload + signature are logged for fixture capture.
  void _tryDecodeVehicleData(um.RoutableMessage msg) {
    final ct = Uint8List.fromList(msg.protobufMessageAsBytes);
    if (!msg.hasSignatureData() || !msg.signatureData.hasAESGCMResponseData()) {
      log('· response payload (unsigned/plain) ${_hex(ct)}');
      _tryParseResponse(ct);
      return;
    }
    final s = msg.signatureData.aESGCMResponseData;
    log('· encrypted response: nonce=${_hex(s.nonce)} counter=${s.counter} '
        'tag=${_hex(s.tag)} ct=${_hex(ct)}');
    log('  (capture above for response-decrypt fixture)');
  }

  void _tryParseResponse(Uint8List plain) {
    try {
      final resp = cs.Response.fromBuffer(plain);
      final data = resp.vehicleData;
      final reading = TeslaReadingMapper.fromVehicleData(
        timestamp: DateTime.now(),
        drive: data.driveState,
        charge: data.chargeState,
      );
      log('✓ Reading: speed=${reading.speedMs} m/s gear=${reading.gear} '
          'battery=${reading.batteryPercent}% range=${reading.rangeMiles}mi '
          'power=${reading.powerKw}kW');
    } catch (e) {
      log('· could not decode CarServer.Response: $e');
    }
  }

  Future<void> dispose() => _transport.dispose();
}

final _rng = Random.secure();
Uint8List _randomBytes(int n) =>
    Uint8List.fromList(List<int>.generate(n, (_) => _rng.nextInt(256)));

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
