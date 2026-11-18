import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// music_companion/kernel/audio_pipeline.dart

/// Basisklasse für alle Audio-Effekte (DSP-Nodes).
abstract class AudioEffect {
  String get id;
  String get name;
  bool enabled = true;

  /// FFmpeg/mpv Audio-Filter, z.B. "equalizer=f=1000:t=q:w=1:g=5"
  /// Diese werden nativ berechnet (keine Dart-Latenz).
  String get mpvAudioFilters => '';

  /// Direkte mpv Eigenschaften, z.B. {"speed": "1.5", "crossfade": "3"}
  Map<String, String> get mpvProperties => {};

  VoidCallback? onChanged;
  void notifyChanged() => onChanged?.call();
}

class PlaybackPipeline {
  final List<AudioEffect> _effects = [];
  final Player _player;

  PlaybackPipeline(this._player);

  void addEffect(AudioEffect effect) {
    effect.onChanged = rebuild;
    _effects.add(effect);
    rebuild();
  }

  void removeEffect(String id) {
    _effects.removeWhere((e) => e.id == id);
    rebuild();
  }

  /// Baut die native Filter-Chain und wendet sie auf den Player an.
  Future<void> rebuild() async {
    final active = _effects.where((e) => e.enabled);
    final afList = <String>[];
    final props = <String, String>{};

    for (final e in active) {
      if (e.mpvAudioFilters.isNotEmpty) afList.add(e.mpvAudioFilters);
      props.addAll(e.mpvProperties);
    }

    final native = _player.platform as NativePlayer;

    // 1. Audio-Filter anwenden (EQ, Silence-Skip etc.)
    await native.setProperty('af', afList.join(','));

    // 2. Player-Eigenschaften anwenden (Speed, Crossfade etc.)
    for (final entry in props.entries) {
      await native.setProperty(entry.key, entry.value);
    }
  }
}