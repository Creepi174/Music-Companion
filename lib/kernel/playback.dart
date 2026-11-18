import 'package:media_kit/media_kit.dart' show Player, Media;
import 'core.dart';
import 'audio_pipeline.dart';

/// music_companion/kernel/playback.dart

class PlaybackEngine {
  final EventBus bus;
  final Player _player = Player();
  late final PlaybackPipeline pipeline;
  double _volume = 0.7;

  PlaybackEngine(this.bus) {
    pipeline = PlaybackPipeline(_player);

    _player.stream.position.listen(bus.emitPosition);
    _player.stream.duration.listen(bus.emitDuration);
    _player.stream.playing.listen(
          (p) => bus.emitState(p ? 'playing' : 'paused'),
    );
    _player.stream.completed.listen((done) {
      if (done) bus.emitEndOfTrack();
    });
    _player.setVolume(_volume * 100);
  }

  Player createSecondaryPlayer() => Player();

  Future<void> load(Track t) => _player.open(Media(t.path), play: false);
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();

  Future<void> toggle() async =>
      _player.state.playing ? await _player.pause() : await _player.play();

  Future<void> seek(Duration d) => _player.seek(d);

  Duration get position => _player.state.position;
  Duration get duration => _player.state.duration;
  bool get isPlaying => _player.state.playing;
  double get volume => _volume;

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume * 100);
  }

  void dispose() => _player.dispose();
}