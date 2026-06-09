import 'package:flutter/material.dart';

import '../speed/speed_unit.dart';
import 'settings.dart';
import 'settings_store.dart';

/// Grouped settings (顯示 / 行為 / 外觀). Controls are >=44pt; the active accent
/// is marked with a check (not color alone).
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.store});

  final SettingsStore store;

  static const _bg = Color(0xFF0A101C);
  static const _row = Color(0xFFD6DEEA);
  static const _tertiary = Color(0xFF6E7E8C);
  static const _surface = Color(0xFF16202E);
  static const _segActive = Color(0xFF1E3C45);
  static const _accentText = Color(0xFF6FD8E2);
  static const _accent = Color(0xFF2BD4E0);

  static const _accentColors = {
    AccentColor.cyan: Color(0xFF2BD4E0),
    AccentColor.amber: Color(0xFFFFB638),
    AccentColor.indigo: Color(0xFF6E7BFF),
  };

  void _set(Settings next) => store.update(next);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final s = store.settings;
            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('設定',
                      style: TextStyle(
                          color: Color(0xFFF2F5FA),
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                ),
                _groupHeader('顯示'),
                _segRow('單位', [
                  _Seg('km/h', s.unit == SpeedUnit.kmh,
                      () => _set(s.copyWith(unit: SpeedUnit.kmh))),
                  _Seg('mph', s.unit == SpeedUnit.mph,
                      () => _set(s.copyWith(unit: SpeedUnit.mph))),
                ]),
                _segRow('畫面亮度', [
                  _Seg('自動', s.brightness == BrightnessMode.auto,
                      () => _set(s.copyWith(brightness: BrightnessMode.auto))),
                  _Seg('日', s.brightness == BrightnessMode.day,
                      () => _set(s.copyWith(brightness: BrightnessMode.day))),
                  _Seg('夜', s.brightness == BrightnessMode.night,
                      () => _set(s.copyWith(brightness: BrightnessMode.night))),
                ]),
                _toggleRow('鏡像 HUD 模式', '水平翻轉,投影到擋風玻璃時讀正',
                    s.mirror, () => _set(s.copyWith(mirror: !s.mirror))),
                _groupHeader('行為'),
                _toggleRow('行駛自動切換極簡', '行駛時自動隱藏次要資訊,只留車速',
                    s.autoMinimal, () => _set(s.copyWith(autoMinimal: !s.autoMinimal))),
                _toggleRow('螢幕恆亮', 'HUD 開啟時不自動鎖定螢幕', s.keepAwake,
                    () => _set(s.copyWith(keepAwake: !s.keepAwake))),
                _groupHeader('外觀'),
                _accentRow(s.accent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _groupHeader(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4, left: 2),
        child: Text(title,
            style: const TextStyle(
                color: _tertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6)),
      );

  Widget _segRow(String label, List<_Seg> options) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: _row, fontSize: 16, fontWeight: FontWeight.w500))),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: _surface, borderRadius: BorderRadius.circular(11)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map((o) => GestureDetector(
                          onTap: o.onTap,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 36),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: o.active ? _segActive : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(o.label,
                                style: TextStyle(
                                    color: o.active ? _accentText : _tertiary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );

  Widget _toggleRow(String label, String desc, bool on, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: _row, fontSize: 16, fontWeight: FontWeight.w500)),
                    if (desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(desc,
                            style: const TextStyle(
                                color: _tertiary, fontSize: 12, height: 1.4)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(value: on, activeThumbColor: _accent, onChanged: (_) => onTap()),
            ],
          ),
        ),
      );

  Widget _accentRow(AccentColor active) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            const Expanded(
                child: Text('強調色',
                    style: TextStyle(
                        color: _row, fontSize: 16, fontWeight: FontWeight.w500))),
            for (final entry in _accentColors.entries)
              GestureDetector(
                key: ValueKey('accent-${entry.key.name}'),
                onTap: () => _set(store.settings.copyWith(accent: entry.key)),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: entry.key == active
                            ? Border.all(color: const Color(0xFFF2F5FA), width: 2)
                            : null,
                      ),
                      child: entry.key == active
                          ? const Icon(Icons.check, size: 16, color: Color(0xFF06101A))
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _Seg {
  _Seg(this.label, this.active, this.onTap);
  final String label;
  final bool active;
  final VoidCallback onTap;
}
