import '../speed/speed_unit.dart';

/// Day/night brightness adaptation mode.
enum BrightnessMode { auto, day, night }

/// Accent color choices (cyan default).
enum AccentColor { cyan, amber, indigo }

/// Persisted user preferences. Immutable; mutate via [copyWith].
class Settings {
  const Settings({
    this.unit = SpeedUnit.kmh,
    this.mirror = false,
    this.autoMinimal = true,
    this.brightness = BrightnessMode.auto,
    this.keepAwake = true,
    this.accent = AccentColor.cyan,
  });

  final SpeedUnit unit;
  final bool mirror;
  final bool autoMinimal;
  final BrightnessMode brightness;
  final bool keepAwake;
  final AccentColor accent;

  Settings copyWith({
    SpeedUnit? unit,
    bool? mirror,
    bool? autoMinimal,
    BrightnessMode? brightness,
    bool? keepAwake,
    AccentColor? accent,
  }) {
    return Settings(
      unit: unit ?? this.unit,
      mirror: mirror ?? this.mirror,
      autoMinimal: autoMinimal ?? this.autoMinimal,
      brightness: brightness ?? this.brightness,
      keepAwake: keepAwake ?? this.keepAwake,
      accent: accent ?? this.accent,
    );
  }

  Map<String, Object?> toMap() => {
        'unit': unit.name,
        'mirror': mirror,
        'autoMinimal': autoMinimal,
        'brightness': brightness.name,
        'keepAwake': keepAwake,
        'accent': accent.name,
      };

  /// Builds settings from a (possibly partial) stored map, falling back to
  /// defaults for any missing or unrecognized key.
  factory Settings.fromMap(Map<String, Object?> map) {
    const defaults = Settings();
    return Settings(
      unit: _enumByName(SpeedUnit.values, map['unit'], defaults.unit),
      mirror: map['mirror'] as bool? ?? defaults.mirror,
      autoMinimal: map['autoMinimal'] as bool? ?? defaults.autoMinimal,
      brightness:
          _enumByName(BrightnessMode.values, map['brightness'], defaults.brightness),
      keepAwake: map['keepAwake'] as bool? ?? defaults.keepAwake,
      accent: _enumByName(AccentColor.values, map['accent'], defaults.accent),
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
