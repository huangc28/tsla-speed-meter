import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_constants.dart';

/// Thin transport over flutter_blue_plus that finds a Tesla by its VIN-derived
/// advertised name, connects, and frames messages per the vehicle BLE protocol
/// (2-byte big-endian length prefix; responses reassembled from notification
/// chunks). UNTESTED — exercised only against a real car.
class BleTransport {
  final void Function(String) log;
  BleTransport(this.log);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _tx;
  BluetoothCharacteristic? _rx;
  StreamSubscription<List<int>>? _rxSub;

  final List<int> _inputBuffer = [];
  final _messages = StreamController<Uint8List>.broadcast();

  /// Complete, de-framed inbound messages from the vehicle.
  Stream<Uint8List> get messages => _messages.stream;

  /// Scans for the car advertising the name derived from [vin] and connects.
  Future<void> connectToVin(String vin) async {
    final wanted = TeslaBle.localNameForVin(vin);
    log('Scanning for "$wanted" (VIN $vin)…');

    final completer = Completer<BluetoothDevice>();
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName;
        if (name == wanted && !completer.isCompleted) {
          log('Found ${r.device.remoteId} rssi=${r.rssi}');
          completer.complete(r.device);
        }
      }
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));
    final device = await completer.future
        .timeout(const Duration(seconds: 22), onTimeout: () {
      throw TimeoutException('No car advertising "$wanted" found');
    });
    await sub.cancel();
    await FlutterBluePlus.stopScan();

    log('Connecting…');
    await device.connect(timeout: const Duration(seconds: 20));
    _device = device;
    try {
      await device.requestMtu(512);
    } catch (_) {/* best effort */}
    log('MTU=${device.mtuNow}');

    await _discover(device);
    log('Connected and subscribed.');
  }

  Future<void> _discover(BluetoothDevice device) async {
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == Guid(TeslaBle.serviceUuid),
      orElse: () => throw StateError('Tesla BLE service not found'),
    );
    _tx = service.characteristics
        .firstWhere((c) => c.uuid == Guid(TeslaBle.txCharUuid));
    _rx = service.characteristics
        .firstWhere((c) => c.uuid == Guid(TeslaBle.rxCharUuid));

    await _rx!.setNotifyValue(true);
    _rxSub = _rx!.onValueReceived.listen(_onChunk);
  }

  void _onChunk(List<int> chunk) {
    log('RX chunk ${_hex(chunk)}');
    _inputBuffer.addAll(chunk);
    // Drain any complete framed messages.
    while (_inputBuffer.length >= 2) {
      final msgLength = 256 * _inputBuffer[0] + _inputBuffer[1];
      if (msgLength > TeslaBle.maxMessageLength) {
        log('!! bad frame length $msgLength; clearing buffer');
        _inputBuffer.clear();
        return;
      }
      if (_inputBuffer.length < 2 + msgLength) return; // wait for more
      final msg = Uint8List.fromList(_inputBuffer.sublist(2, 2 + msgLength));
      _inputBuffer.removeRange(0, 2 + msgLength);
      log('RX message (${msg.length}B) ${_hex(msg)}');
      _messages.add(msg);
    }
  }

  /// Length-prefixes [payload] and writes it to the vehicle in MTU-sized chunks.
  Future<void> send(Uint8List payload) async {
    final tx = _tx;
    if (tx == null) throw StateError('Not connected');
    final framed = Uint8List(2 + payload.length)
      ..[0] = (payload.length >> 8) & 0xff
      ..[1] = payload.length & 0xff
      ..setRange(2, 2 + payload.length, payload);

    final blockLength = (_device?.mtuNow ?? 23) - 3;
    log('TX message (${payload.length}B) ${_hex(payload)}');
    for (var i = 0; i < framed.length; i += blockLength) {
      final end = (i + blockLength).clamp(0, framed.length);
      await tx.write(framed.sublist(i, end), withoutResponse: true);
    }
  }

  Future<void> dispose() async {
    await _rxSub?.cancel();
    await _device?.disconnect();
    await _messages.close();
  }
}

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
