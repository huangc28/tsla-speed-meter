import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../ble/gen/universal_message.pb.dart' as um;
import '../ble/tesla_ble_client.dart';

/// Guided harness for the #11 BLE feasibility spike. NOT part of the shipping
/// HUD — it is the throwaway tool the tester runs in/near the car to enroll a
/// key and probe which fields BLE exposes (and at what rate). Every step writes
/// to the on-screen log, which can be exported and sent back.
class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> {
  final _vinController = TextEditingController();
  final _log = <String>[];
  final _scroll = ScrollController();
  TeslaBleClient? _client;
  bool _busy = false;

  void _append(String line) {
    final stamped = '${DateTime.now().toIso8601String()}  $line';
    setState(() => _log.add(stamped));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _guard(String label, Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    _append('▶ $label');
    try {
      await action();
    } catch (e) {
      _append('✗ $label failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _guard('Connect', () async {
        final vin = _vinController.text.trim().toUpperCase();
        if (vin.length != 17) {
          throw 'Enter the full 17-character VIN first';
        }
        await _client?.dispose();
        final client = TeslaBleClient(vin: vin, log: _append);
        _client = client;
        await client.start();
      });

  Future<void> _sessionInfo() => _guard('Session info (infotainment)', () async {
        await _need().requestSessionInfo(um.Domain.DOMAIN_INFOTAINMENT);
      });

  Future<void> _enroll() => _guard('Enroll key', () async {
        // Enrollment is authorized by the vehicle-security domain.
        await _need().requestSessionInfo(um.Domain.DOMAIN_VEHICLE_SECURITY);
        await _need().enrollKey();
      });

  Future<void> _readOnce() =>
      _guard('Read vehicle data', () => _need().readVehicleData());

  Future<void> _pollSpeed() => _guard('Poll drive state ×20', () async {
        final start = DateTime.now();
        for (var i = 0; i < 20; i++) {
          await _need().readVehicleData();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final ms = DateTime.now().difference(start).inMilliseconds;
        _append('… 20 polls issued in ${ms}ms (~${(20000 / ms).toStringAsFixed(1)} req/s); '
            'check timestamps above for actual response cadence');
      });

  TeslaBleClient _need() {
    final c = _client;
    if (c == null) throw 'Connect first';
    return c;
  }

  Future<void> _export() async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/tesla_ble_spike_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(_log.join('\n'));
    await SharePlus.instance
        .share(ShareParams(files: [XFile(file.path)], text: 'Tesla BLE spike log'));
  }

  @override
  void dispose() {
    _client?.dispose();
    _vinController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesla BLE Spike'),
        actions: [
          IconButton(
            onPressed: _log.isEmpty ? null : _export,
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export log',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _vinController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'VIN (17 chars)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _btn('1. Connect', _connect),
                _btn('2. Enroll key', _enroll),
                _btn('3. Session info', _sessionInfo),
                _btn('4. Read data', _readOnce),
                _btn('5. Poll speed ×20', _pollSpeed),
              ],
            ),
            const SizedBox(height: 8),
            if (_busy) const LinearProgressIndicator(),
            const Divider(),
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Text(
                    _log[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) =>
      ElevatedButton(onPressed: _busy ? null : onTap, child: Text(label));
}
