// Kernel-Logik-Tests – keine Widgets, kein MediaKit nötig.

import 'package:flutter_test/flutter_test.dart';
import 'package:music_companion/kernel/core.dart';

void main() {
  group('Track', () {
    test('leerer title wird vom Dateinamen abgeleitet', () {
      final t = Track(path: '/music/song.mp3');
      expect(t.title, 'song');
    });

    test('displayName kombiniert artist und title', () {
      final t = Track(path: '/x.mp3', title: 'Hello', artist: 'World');
      expect(t.displayName, 'World – Hello');
    });

    test('displayName ohne artist ist nur der title', () {
      final t = Track(path: '/x.mp3', title: 'Hello');
      expect(t.displayName, 'Hello');
    });

    test('JSON round-trip erhält Felder', () {
      final t = Track(
        path: '/a.mp3',
        title: 'T',
        artist: 'A',
        album: 'Al',
        duration: const Duration(seconds: 42),
      );
      final copy = Track.fromJson(t.toJson());
      expect(copy.path, t.path);
      expect(copy.title, t.title);
      expect(copy.artist, t.artist);
      expect(copy.album, t.album);
      expect(copy.duration, t.duration);
    });
  });

  group('isPlayable', () {
    test('erkennt Audio- und Video-Endungen', () {
      expect(isPlayable('/a.mp3'), isTrue);
      expect(isPlayable('/a.flac'), isTrue);
      expect(isPlayable('/a.mp4'), isTrue);
      expect(isPlayable('/a.mkv'), isTrue);
      expect(isPlayable('/a.txt'), isFalse);
      expect(isPlayable('/a'), isFalse);
    });
  });

  group('Library', () {
    test('dedupliziert nach Pfad', () {
      final bus = EventBus();
      final lib = Library(bus);
      lib.add(Track(path: '/a.mp3'));
      lib.add(Track(path: '/a.mp3'));
      expect(lib.tracks.length, 1);
    });

    test('clear leert die Bibliothek', () {
      final bus = EventBus();
      final lib = Library(bus);
      lib.add(Track(path: '/a.mp3'));
      lib.clear();
      expect(lib.tracks, isEmpty);
    });
  });

  group('Playlist', () {
    test('nextIndex läuft um', () {
      final bus = EventBus();
      final pl = Playlist(bus);
      pl.add(Track(path: '/a.mp3'));
      pl.add(Track(path: '/b.mp3'));
      pl.setCurrent(1);
      expect(pl.nextIndex(), 0);
    });

    test('prevIndex läuft rückwärts um', () {
      final bus = EventBus();
      final pl = Playlist(bus);
      pl.add(Track(path: '/a.mp3'));
      pl.add(Track(path: '/b.mp3'));
      pl.setCurrent(0);
      expect(pl.prevIndex(), 1);
    });

    test('currentTrack folgt setCurrent', () {
      final bus = EventBus();
      final pl = Playlist(bus);
      pl.add(Track(path: '/a.mp3'));
      pl.setCurrent(0);
      expect(pl.currentTrack?.path, '/a.mp3');
    });

    test('removeAt korrigiert currentIndex am Ende', () {
      final bus = EventBus();
      final pl = Playlist(bus);
      pl.add(Track(path: '/a.mp3'));
      pl.add(Track(path: '/b.mp3'));
      pl.setCurrent(1);
      pl.removeAt(1);
      expect(pl.currentIndex, 0);
    });

    test('leere Playlist: next/prev liefern -1', () {
      final pl = Playlist(EventBus());
      expect(pl.nextIndex(), -1);
      expect(pl.prevIndex(), -1);
    });
  });
}