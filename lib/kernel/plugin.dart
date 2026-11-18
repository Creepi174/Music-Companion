import 'package:flutter/widgets.dart';
import 'core.dart';
import 'playback.dart';
import 'audio_pipeline.dart';
import 'desktop_services.dart';

/// music_companion/kernel/plugin.dart

/// Ein Tab (oder Sub-Tab), den ein Plugin in die UI einhängt.
class UiContribution {
  final String title;
  final String iconKey;
  final Widget Function() builder;
  final List<UiContribution> subtabs;


  UiContribution({
    required this.title,
    required this.iconKey,
    required this.builder,
    this.subtabs = const [],
  });
}

class PluginContext {
  final Library library;
  final Playlist playlist;
  final PlaybackEngine engine;
  final EventBus bus;
  final AppHooks hooks;
  final PlaybackPipeline pipeline;
  final DesktopServices desktop;
  final void Function(UiContribution) _registerTab;

  PluginContext({
    required this.library,
    required this.playlist,
    required this.engine,
    required this.bus,
    required this.hooks,
    required this.pipeline,
    required this.desktop,
    required void Function(UiContribution) registerTab,
  }) : _registerTab = registerTab;

  void registerTab(UiContribution tab) => _registerTab(tab);

  void registerAudioEffect(AudioEffect effect) {
    pipeline.addEffect(effect);
  }

  void addTrayMenuItem(String label, VoidCallback onClick) {
    desktop.addTrayMenuItem(label, onClick);
  }

  Future<void> setAppIcon(String path) async {
    await desktop.setAppIcon(path);
  }

  void setKeepInTray(bool value) {
    desktop.keepInTray = value;
  }

  void log(String msg) => debugPrint('[plugin] $msg');
}

abstract class PluginBase {
  String get name;
  String get version => '0.1';
  String get description => '';
  String get author => 'unbekannt';

  late PluginContext context;
  void bind(PluginContext c) => context = c;
  Future<void> activate() async {}
  Future<void> deactivate() async {}
}

class PluginManager {
  final _plugins = <PluginBase>[];
  final _tabs = <UiContribution>[];

  List<PluginBase> get plugins => List.unmodifiable(_plugins);
  List<UiContribution> get tabs => List.unmodifiable(_tabs);

  void add(PluginBase p) => _plugins.add(p);

  Future<void> loadAll({
    required Library library,
    required Playlist playlist,
    required PlaybackEngine engine,
    required EventBus bus,
    required AppHooks hooks,
    required DesktopServices desktop,
  }) async {
    for (final p in _plugins) {
      p.bind(PluginContext(
        library: library,
        playlist: playlist,
        engine: engine,
        bus: bus,
        hooks: hooks,
        pipeline: engine.pipeline,
        desktop: desktop,
        registerTab: (t) => _tabs.add(t),
      ));
      try {
        await p.activate();
        debugPrint('[plugins] ${p.name} v${p.version}');
      } catch (e) {
        debugPrint('[plugins] failed ${p.name}: $e');
      }
    }
  }

  Future<void> disposeAll() async {
    for (final p in _plugins) {
      try {
        await p.deactivate();
      } catch (_) {}
    }
  }
}