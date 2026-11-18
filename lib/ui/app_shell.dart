import 'package:flutter/material.dart';
import '../kernel/kernel.dart';
import '../kernel/plugin.dart';
import 'library_tab.dart';
import 'playback_panel.dart';

/// music_companion/ui/app_shell.dart

enum TabBarSide { left, right, top, bottom }

class AppShell extends StatefulWidget {
  final AppKernel kernel;
  const AppShell({super.key, required this.kernel});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  TabBarSide _side = TabBarSide.left;
  int _main = 0;
  int _sub = 0;
  late List<UiContribution> _tabs;

  @override
  void initState() {
    super.initState();
    final kernel = widget.kernel;
    _tabs = [
      // Kernel-Tab: Bibliothek + Wiedergabe als Sub-Tab
      UiContribution(
        title: 'Bibliothek',
        iconKey: 'library',
        builder: () => LibraryTab(kernel: kernel),
        subtabs: [
          UiContribution(
            title: 'Alle Titel',
            iconKey: 'list',
            builder: () => LibraryTab(kernel: kernel),
          ),
          UiContribution(
            title: 'Wiedergabe',
            iconKey: 'queue',
            builder: () => PlaylistView(kernel: kernel),
          ),
        ],
      ),
      // Alle Plugin-Tabs
      ...kernel.plugins.tabs,
    ];
  }

  IconData _icon(String k) => switch (k) {
    'library' => Icons.library_music,
    'list' => Icons.queue_music,
    'queue' => Icons.playlist_play,
    'play' => Icons.play_circle,
    'history' => Icons.history,
    'plugin' => Icons.extension,
    _ => Icons.tab,
  };

  @override
  Widget build(BuildContext context) {
    final main = _tabs[_main.clamp(0, _tabs.length - 1)];
    final subs = main.subtabs;
    final current = subs.isEmpty ? null : subs[_sub.clamp(0, subs.length - 1)];
    final content = (current?.builder ?? main.builder)();
    final vertical = _side == TabBarSide.left || _side == TabBarSide.right;

    final tabStrip = _buildTabStrip(vertical);
    final subStrip = subs.isEmpty ? null : _buildSubStrip(subs);

    final mainArea = Column(
      children: [
        if (!vertical) tabStrip,
        if (subStrip != null) subStrip,
        Expanded(child: content),
        const PlaybackPanel(),
      ],
    );

    final body = vertical
        ? Row(
      children: _side == TabBarSide.left
          ? [tabStrip, Expanded(child: mainArea)]
          : [Expanded(child: mainArea), tabStrip],
    )
        : mainArea;

    return Scaffold(
      body: Column(
        children: [
          _TopBar(side: _side, onSide: (s) => setState(() => _side = s)),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildTabStrip(bool vertical) {
    final children = [
      for (int i = 0; i < _tabs.length; i++)
        _tabButton(
          icon: _icon(_tabs[i].iconKey),
          label: _tabs[i].title,
          selected: i == _main,
          vertical: vertical,
          onTap: () => setState(() {
            _main = i;
            _sub = 0;
          }),
        ),
    ];
    if (vertical) {
      return Container(
        width: 88,
        color: const Color(0xFF08080B),
        child: Column(children: children),
      );
    }
    return Container(
      height: 64,
      color: const Color(0xFF08080B),
      child: Row(children: children),
    );
  }

  Widget _tabButton({
    required IconData icon,
    required String label,
    required bool selected,
    required bool vertical,
    required VoidCallback onTap,
  }) {
    final color = selected ? const Color(0xFFA5A8FF) : const Color(0xFF9A9AAC);
    final bg = selected ? const Color(0x2E6366F1) : Colors.transparent;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: vertical ? 22 : 20),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(color: color, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubStrip(List<UiContribution> subs) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D12),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A24))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: subs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(subs[i].title),
          selected: i == _sub,
          onSelected: (_) => setState(() => _sub = i),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final TabBarSide side;
  final ValueChanged<TabBarSide> onSide;
  const _TopBar({required this.side, required this.onSide});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF08080B),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A24))),
      ),
      child: Row(
        children: [
          const Text('♪  MusicCompanion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          PopupMenuButton<TabBarSide>(
            tooltip: 'Tab-Position',
            icon: const Icon(Icons.dock),
            onSelected: onSide,
            itemBuilder: (_) => const [
              PopupMenuItem(value: TabBarSide.left, child: Text('Links')),
              PopupMenuItem(value: TabBarSide.right, child: Text('Rechts')),
              PopupMenuItem(value: TabBarSide.top, child: Text('Oben')),
              PopupMenuItem(value: TabBarSide.bottom, child: Text('Unten')),
            ],
          ),
        ],
      ),
    );
  }
}