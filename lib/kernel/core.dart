import 'dart:async';
import 'package:path/path.dart' as p;

/// music_companion/kernel/core.dart
/// desktop + mobile musik app mit kernel+plugins architektur

// ---------------------------------------------------------------- Track
class Track {
  final String path;
  String title;
  String artist;
  String album;
  Duration duration;
  final Map<String, dynamic> extra;

  Track({
    required this.path,
    String? title,
    this.artist = '',
    this.album = '',
    this.duration = Duration.zero,
    Map<String, dynamic>? extra,
  })  : title = title ?? p.basenameWithoutExtension(path),
        extra = extra ?? {};

  String get displayName => artist.isEmpty ? title : '$artist – $title';

  Map<String, dynamic> toJson() => {
    'path': path,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration.inMilliseconds,
  };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
    path: j['path'],
    title: j['title'],
    artist: j['artist'] ?? '',
    album: j['album'] ?? '',
    duration: Duration(milliseconds: j['duration'] ?? 0),
  );
}

const kAudioExt = {
  '.mp3', '.wav', '.flac', '.ogg', '.m4a', '.aac', '.opus', '.wma'
};
const kVideoExt = {
  '.mp4', '.mkv', '.webm', '.mov', '.avi', '.flv', '.m4v'
};
bool isPlayable(String path) {
  final e = p.extension(path).toLowerCase();
  return kAudioExt.contains(e) || kVideoExt.contains(e);
}

// ---------------------------------------------------------------- EventBus
class EventBus {
  final _track = StreamController<Track?>.broadcast();
  final _state = StreamController<String>.broadcast();
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration>.broadcast();
  final _pl = StreamController<void>.broadcast();
  final _lib = StreamController<void>.broadcast();
  final _eot = StreamController<void>.broadcast();

  Stream<Track?> get trackChanged => _track.stream;
  Stream<String> get stateChanged => _state.stream;
  Stream<Duration> get positionChanged => _pos.stream;
  Stream<Duration> get durationChanged => _dur.stream;
  Stream<void> get playlistChanged => _pl.stream;
  Stream<void> get libraryChanged => _lib.stream;
  Stream<void> get endOfTrack => _eot.stream;

  void emitTrack(Track? t) => _track.add(t);
  void emitState(String s) => _state.add(s);
  void emitPosition(Duration d) => _pos.add(d);
  void emitDuration(Duration d) => _dur.add(d);
  void emitPlaylistChanged() => _pl.add(null);
  void emitLibraryChanged() => _lib.add(null);
  void emitEndOfTrack() => _eot.add(null);

  void dispose() {
    _track.close();
    _state.close();
    _pos.close();
    _dur.close();
    _pl.close();
    _lib.close();
    _eot.close();
  }
}

// ---------------------------------------------------------------- Library
class Library {
  final EventBus bus;
  final _tracks = <Track>[];
  Library(this.bus);

  List<Track> get tracks => List.unmodifiable(_tracks);

  void add(Track t) {
    if (_tracks.any((x) => x.path == t.path)) return;
    _tracks.add(t);
    bus.emitLibraryChanged();
  }

  void addAll(Iterable<Track> ts) {
    var changed = false;
    for (final t in ts) {
      if (!_tracks.any((x) => x.path == t.path)) {
        _tracks.add(t);
        changed = true;
      }
    }
    if (changed) bus.emitLibraryChanged();
  }

  void remove(String path) {
    _tracks.removeWhere((t) => t.path == path);
    bus.emitLibraryChanged();
  }

  void clear() {
    _tracks.clear();
    bus.emitLibraryChanged();
  }
}

// ---------------------------------------------------------------- Playlist
class Playlist {
  final EventBus bus;
  final _tracks = <Track>[];
  int _current = -1;
  Playlist(this.bus);

  List<Track> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _current;
  Track? get currentTrack =>
      _current >= 0 && _current < _tracks.length ? _tracks[_current] : null;

  void add(Track t) {
    _tracks.add(t);
    bus.emitPlaylistChanged();
  }

  void addAll(Iterable<Track> ts) {
    _tracks.addAll(ts);
    bus.emitPlaylistChanged();
  }

  void removeAt(int i) {
    if (i < 0 || i >= _tracks.length) return;
    _tracks.removeAt(i);
    if (_current >= _tracks.length) _current = _tracks.length - 1;
    bus.emitPlaylistChanged();
  }

  void clear() {
    _tracks.clear();
    _current = -1;
    bus.emitPlaylistChanged();
  }

  void setCurrent(int i) {
    if (i < 0 || i >= _tracks.length) return;
    _current = i;
    bus.emitTrack(_tracks[i]);
  }

  int nextIndex() => _tracks.isEmpty ? -1 : (_current + 1) % _tracks.length;
  int prevIndex() =>
      _tracks.isEmpty ? -1 : (_current - 1 + _tracks.length) % _tracks.length;
}

// ---------------------------------------------------------------- Hooks
typedef NextTrackPicker = int? Function(Playlist playlist, int defaultIndex);

class AppHooks {
  final _nextPickers = <NextTrackPicker>[];
  void registerNextPicker(NextTrackPicker fn) => _nextPickers.add(fn);

  int nextIndex(Playlist playlist) {
    final def = playlist.nextIndex();
    for (final picker in _nextPickers.reversed) {
      try {
        final r = picker(playlist, def);
        if (r != null) return r;
      } catch (_) {}
    }
    return def;
  }
}