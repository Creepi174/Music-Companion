import 'package:audio_service/audio_service.dart';
import 'kernel.dart';

/// music_companion/kernel/media_session.dart

class MediaSessionBridge extends BaseAudioHandler {
  final AppKernel kernel;

  MediaSessionBridge(this.kernel) {
    // 1. Höre auf Änderungen im Kernel und sende sie ans Betriebssystem
    kernel.bus.trackChanged.listen((track) {
      if (track != null) {
        mediaItem.add(MediaItem(
          id: track.path,
          title: track.title,
          artist: track.artist.isEmpty ? 'Unbekannt' : track.artist,
          album: track.album,
        ));
      }
    });

    kernel.bus.stateChanged.listen((state) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (state == 'playing') MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        processingState: AudioProcessingState.ready,
        playing: state == 'playing',
      ));
    });
  }

  // 2. Klicks vom Betriebssystem (z.B. Bluetooth-Kopfhörer) an den Kernel senden
  @override
  Future<void> play() async => kernel.engine.play();
  @override
  Future<void> pause() async => kernel.engine.pause();
  @override
  Future<void> skipToNext() async => kernel.next();
  @override
  Future<void> skipToPrevious() async => kernel.prev();
  @override
  Future<void> seek(Duration position) async => kernel.engine.seek(position);
}