import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' show MediaKit;
import 'kernel/kernel.dart';
import 'plugins/plugins.dart';
import 'ui/app_shell.dart';

/// music_companion/main.dart
/// desktop + mobile musik app mit kernel+plugins architektur

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final kernel = AppKernel();
  registerBuiltinPlugins(kernel.plugins);
  kernel.plugins.loadAll(
    library: kernel.library,
    playlist: kernel.playlist,
    engine: kernel.engine,
    bus: kernel.bus,
    hooks: kernel.hooks,
    desktop: kernel.desktop,
  );

  runApp(MusicCompanionApp(kernel: kernel));
}

class MusicCompanionApp extends StatelessWidget {
  final AppKernel kernel;
  const MusicCompanionApp({super.key, required this.kernel});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Music Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        splashFactory: InkSparkle.splashFactory,
      ),
      home: KernelScope(kernel: kernel, child: AppShell(kernel: kernel)),
    );
  }
}