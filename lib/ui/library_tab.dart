import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../kernel/core.dart';
import '../kernel/kernel.dart';

/// music_companion/ui/library_tab.dart

class LibraryTab extends StatefulWidget {
  final AppKernel kernel;
  const LibraryTab({super.key, required this.kernel});
  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final _ctrl = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    widget.kernel.bus.libraryChanged.listen((_) => setState(() {}));
    widget.kernel.bus.playlistChanged.listen((_) => setState(() {}));
    _ctrl.addListener(
            () => setState(() => _filter = _ctrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (r == null) return;
    final paths = r.paths.whereType<String>().where(isPlayable);
    widget.kernel.library.addAll(paths.map((p) => Track(path: p)));
  }

  Future<void> _pickFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    final files = Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => isPlayable(f.path))
        .map((f) => Track(path: f.path));
    widget.kernel.library.addAll(files);
  }

  Future<void> _play(Track t) async {
    final i = widget.kernel.playlist.tracks.indexWhere((x) => x.path == t.path);
    if (i >= 0) {
      await widget.kernel.playIndex(i);
    } else {
      widget.kernel.playlist.add(t);
      await widget.kernel.playIndex(widget.kernel.playlist.tracks.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.kernel.library.tracks;
    final visible = _filter.isEmpty
        ? all
        : all
        .where((t) =>
    t.title.toLowerCase().contains(_filter) ||
        t.artist.toLowerCase().contains(_filter))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              const Text('Bibliothek',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Suchen nach Titel oder Künstler …',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                  onPressed: _pickFolder,
                  tooltip: 'Ordner hinzufügen',
                  icon: const Icon(Icons.folder)),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  onPressed: _pickFiles,
                  tooltip: 'Dateien hinzufügen',
                  icon: const Icon(Icons.add)),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Center(
              child: Text('Keine Titel – Dateien oder Ordner hinzufügen.',
                  style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: visible.length,
            itemBuilder: (_, i) => _tile(visible[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text('${visible.length} Titel',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _tile(Track t) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(t.title),
      subtitle: Text(t.artist.isEmpty ? '–' : t.artist),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () => _play(t),
      ),
      onTap: () => _play(t),
    );
  }
}

// ---------------------------------------------------------------- PlaylistView
class PlaylistView extends StatefulWidget {
  final AppKernel kernel;
  const PlaylistView({super.key, required this.kernel});
  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  @override
  void initState() {
    super.initState();
    widget.kernel.bus.playlistChanged.listen((_) => setState(() {}));
    widget.kernel.bus.trackChanged.listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final tracks = widget.kernel.playlist.tracks;
    if (tracks.isEmpty) {
      return const Center(
        child: Text('Wiedergabeliste leer.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              const Text('Wiedergabe',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => widget.kernel.playlist.clear(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Leeren'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (_, i) {
              final t = tracks[i];
              final cur = i == widget.kernel.playlist.currentIndex;
              return ListTile(
                selected: cur,
                selectedTileColor: const Color(0x1F6366F1),
                leading: cur
                    ? const Icon(Icons.play_arrow, color: Color(0xFFA5A8FF))
                    : SizedBox(
                  width: 24,
                  child: Center(child: Text('${i + 1}')),
                ),
                title: Text(t.title,
                    style: TextStyle(
                        color: cur ? const Color(0xFFA5A8FF) : null)),
                subtitle: Text(t.artist.isEmpty ? '–' : t.artist),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => widget.kernel.playlist.removeAt(i),
                ),
                onTap: () => widget.kernel.playIndex(i),
              );
            },
          ),
        ),
      ],
    );
  }
}