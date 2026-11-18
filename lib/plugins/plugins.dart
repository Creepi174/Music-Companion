import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:io';
import 'dart:math';
import '../kernel/core.dart';
import '../kernel/plugin.dart';

/// music_companion/plugins/plugins.dart

// ============================================================ Metadata
class MetadataPlugin extends PluginBase {
  @override
  String get name => 'Metadata Loader';
  @override
  String get version => '1.0';
  @override
  String get description =>
      'Liest ID3-Tags und Dauer aus Audiodateien.';
  @override
  String get author => 'Built-in';

  @override
  Future<void> activate() async {
    context.bus.libraryChanged.listen((_) {
      for (final t in context.library.tracks) {
        if (t.extra['_enriched'] != true) _enrich(t);
      }
    });
  }

  void _enrich(Track t) async {
    if (t.extra['_enriched'] == true) return;
    t.extra['_enriched'] = true;
    try {
      final meta = readMetadata(File(t.path), getImage: false);
      t.title = meta.title ?? t.title;
      t.artist = meta.artist ?? t.artist;
      t.album = meta.album ?? t.album;
      t.duration = meta.duration ?? t.duration;
    } catch (e) {
      context.log('meta failed ${t.path}: $e');
    }
  }
}

// ============================================================ Auto DJ
class AutoDjPlugin extends PluginBase {
  @override
  String get name => 'Auto DJ';
  @override
  String get version => '1.0';
  @override
  String get description =>
      'Nächster Titel: gleicher Künstler → Album → zufällig.';
  @override
  String get author => 'Built-in';

  final _rng = Random();

  @override
  Future<void> activate() async {
    context.hooks.registerNextPicker(_pick);
  }

  int? _pick(Playlist p, int def) {
    if (p.tracks.length < 2) return null;
    final cur = p.currentTrack;
    if (cur == null) return def;
    var cands = <int>[];
    for (var i = 0; i < p.tracks.length; i++) {
      if (i == p.currentIndex) continue;
      if (cur.artist.isNotEmpty && p.tracks[i].artist == cur.artist) {
        cands.add(i);
      }
    }
    if (cands.isEmpty) {
      for (var i = 0; i < p.tracks.length; i++) {
        if (i == p.currentIndex) continue;
        if (cur.album.isNotEmpty && p.tracks[i].album == cur.album) {
          cands.add(i);
        }
      }
    }
    if (cands.isEmpty) {
      cands = [
        for (var i = 0; i < p.tracks.length; i++)
          if (i != p.currentIndex) i
      ];
    }
    return cands.isEmpty ? def : cands[_rng.nextInt(cands.length)];
  }
}

// ============================================================ Samsung Bridge
class SamsungPlugin extends PluginBase {
  static const _ch = MethodChannel('musiccompanion/samsung');

  @override
  String get name => 'Samsung Integration';
  @override
  String get version => '1.0';
  @override
  String get description =>
      'Samsung-Geräte-Erkennung, DeX-Modus, Media-Session-Bridge via Kotlin.';
  @override
  String get author => 'Built-in';

  @override
  Future<void> activate() async {
    context.registerTab(UiContribution(
      title: 'Samsung',
      iconKey: 'plugin',
      builder: () => const _SamsungPage(),
    ));
  }
}

class _SamsungPage extends StatefulWidget {
  const _SamsungPage();
  @override
  State<_SamsungPage> createState() => _SamsungPageState();
}

class _SamsungPageState extends State<_SamsungPage> {
  String _info = 'lade …';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final s = await SamsungPlugin._ch.invokeMethod<String>('deviceInfo');
      if (mounted) setState(() => _info = s ?? 'unbekannt');
    } catch (e) {
      if (mounted) setState(() => _info = 'nicht verfügbar ($e)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Samsung Integration',
              style:
              TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Text('Status: $_info',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Aktualisieren'),
          ),
          const SizedBox(height: 24),
          const Text('Verfügbare Erweiterungen:'),
          const SizedBox(height: 8),
          const Text('• Samsung Media Session'),
          const Text('• DeX-Modus-Erkennung'),
          const Text('• One-UI-Edge-Panel-Anbindung'),
        ],
      ),
    );
  }
}

// ============================================================ Registry
void registerBuiltinPlugins(PluginManager m) {
  m.add(MetadataPlugin());
  m.add(AutoDjPlugin());
  m.add(SamsungPlugin());
}