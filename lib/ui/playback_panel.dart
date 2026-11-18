import 'package:flutter/material.dart';
import '../kernel/kernel.dart';

/// music_companion/ui/playback_panel.dart

class PlaybackPanel extends StatefulWidget {
  const PlaybackPanel({super.key});
  @override
  State<PlaybackPanel> createState() => _PlaybackPanelState();
}

class _PlaybackPanelState extends State<PlaybackPanel> {
  late final AppKernel _kernel;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _kernel = KernelScope.of(context);
    _kernel.bus.trackChanged.listen((_) => setState(() {}));
    _kernel.bus.stateChanged.listen((_) => setState(() {}));
    _kernel.bus.positionChanged.listen((_) => setState(() {}));
    _kernel.bus.durationChanged.listen((_) => setState(() {}));
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = _kernel.playlist.currentTrack;
    final pos = _kernel.engine.position;
    final dur = _kernel.engine.duration;
    final playing = _kernel.engine.isPlaying;
    final maxMs = dur.inMilliseconds.toDouble();
    final sliderValue = pos.inMilliseconds.toDouble().clamp(0.0, maxMs == 0 ? 1.0 : maxMs);

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF13131A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A24))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF40406E), Color(0xFF26283C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.music_note, color: Colors.white70),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t?.title ?? 'Kein Titel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(t?.artist.isEmpty ?? true ? '–' : t!.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ]),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: _kernel.prev),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF7074FF), Color(0xFF5B5EFF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: IconButton(
                        iconSize: 26,
                        icon: Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        onPressed: () => _kernel.engine.toggle(),
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: _kernel.next),
                  ],
                ),
                Row(children: [
                  Text(_fmt(pos),
                      style:
                      const TextStyle(fontSize: 10, color: Colors.grey)),
                  Expanded(
                    child: Slider(
                      value: sliderValue,
                      max: maxMs == 0 ? 1 : maxMs,
                      onChanged: (v) => _kernel.engine
                          .seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Text(_fmt(dur),
                      style:
                      const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Row(children: [
              Icon(
                  _kernel.engine.volume == 0
                      ? Icons.volume_off
                      : Icons.volume_up,
                  size: 18),
              Expanded(
                child: Slider(
                  value: _kernel.engine.volume,
                  onChanged: _kernel.engine.setVolume,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}