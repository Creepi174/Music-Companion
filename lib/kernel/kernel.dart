import 'package:flutter/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'core.dart';
import 'playback.dart';
import 'plugin.dart';
import 'media_session.dart';
import 'desktop_services.dart';

/// music_companion/kernel/karnel.dart
/// desktop + mobile musik app mit kernel+plugins architektur

class AppKernel {
  final bus = EventBus();
  final hooks = AppHooks();
  final plugins = PluginManager();
  final desktop = DesktopServices();
  MediaSessionBridge? mediaSession;
  late final Library library;
  late final Playlist playlist;
  late final PlaybackEngine engine;


  AppKernel() {
    library = Library(bus);
    playlist = Playlist(bus);
    engine = PlaybackEngine(bus);
    bus.endOfTrack.listen((_) => next());
    _initServices();
  }

  Future<void> playIndex(int i) async {
    playlist.setCurrent(i);
    final t = playlist.currentTrack;
    if (t == null) return;
    await engine.load(t);
    await engine.play();
  }

  Future<void> next() async {
    if (playlist.tracks.isEmpty) return;
    await playIndex(hooks.nextIndex(playlist));
  }

  Future<void> prev() async {
    if (playlist.tracks.isEmpty) return;
    await playIndex(playlist.prevIndex());
  }

  Future<void> dispose() async {
    await plugins.disposeAll();
    engine.dispose();
    bus.dispose();
  }

  Future<void> _initServices() async {
    desktop.onAppQuit = () async {
      await dispose();
    };

    // 1. Desktop (Tray + Fenster)
    await desktop.init();

    // 2. Media Session für das Betriebssystem
    mediaSession = await AudioService.init(
      builder: () => MediaSessionBridge(this),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.musiccompanion.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );
  }
}

/// Stellt den Kernel allen Widgets zur Verfügung.
class KernelScope extends InheritedWidget {
  final AppKernel kernel;
  const KernelScope({super.key, required this.kernel, required super.child});

  static AppKernel of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<KernelScope>()!.kernel;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}