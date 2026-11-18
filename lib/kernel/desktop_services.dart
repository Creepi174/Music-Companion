import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// music_companion/kernel/desktop_services.dart

class DesktopServices with WindowListener {
  final List<MenuItem> _pluginMenuItems = [];

  TrayIcon? _trayIcon;
  Menu? _menu;

  /// Steuert, ob das Fenster beim Schließen in den Tray minimiert wird.
  bool keepInTray = true;

  Future<void> Function()? onAppQuit;

  Future<void> init() async {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1120, 740),
        minimumSize: Size(940, 620),
        center: true,
        title: 'Music Companion',
      );

      await windowManager.setPreventClose(true);
      windowManager.addListener(this);

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}

    try {
      // 1. TrayIcon erstellen
      _trayIcon = TrayIcon.create();
      if (_trayIcon == null) {
        debugPrint('TrayIcon.create() returned null');
        return;
      }

      // 2. Icon setzen
      _trayIcon!.icon = ImageAsset.fromAsset('assets/dev_icon.ico');
      _trayIcon!.setTooltip('Music Companion');

      // 3. Menü bauen
      _updateTrayMenu();

      // 4. Rechtsklick-Trigger aktivieren
      _trayIcon!.setContextMenuTrigger(ContextMenuTrigger.rightClicked);

      // 5. Tray-Icon sichtbar machen
      _trayIcon!.setVisible(true);

      // 6. Click-Listener für das Icon selbst (Linksklick → Fenster zeigen)
      _trayIcon!.addListener((event) {
        if (event is TrayIconClickedEvent) {
          windowManager.show();
          windowManager.focus();
        }
      });
    } catch (e) {
      debugPrint('Tray init failed: $e');
    }
  }

  /// Wird von Plugins aufgerufen, um das Menü zu erweitern
  void addTrayMenuItem(String label, VoidCallback onClick) {
    final item = MenuItem.createWithLabelAndType(
      label,
      MenuItemType.normal,
    );
    if (item != null) {
      item.addListener((event) {
        if (event is MenuItemClickedEvent) {
          onClick();
        }
      });
      _pluginMenuItems.add(item);
      _updateTrayMenu();
    }
  }

  void _updateTrayMenu() {
    try {
      _menu = Menu.create();
      if (_menu == null) return;

      // "Fenster anzeigen"
      final showItem = MenuItem.createWithLabelAndType(
        'Fenster anzeigen',
        MenuItemType.normal,
      );
      if (showItem != null) {
        showItem.addListener((event) {
          if (event is MenuItemClickedEvent) {
            windowManager.show();
            windowManager.focus();
          }
        });
        _menu!.addItem(showItem);
      }

      _menu!.addSeparator();

      // Von Plugins hinzugefügte Einträge
      for (final item in _pluginMenuItems) {
        _menu!.addItem(item);
      }

      _menu!.addSeparator();

      // "Beenden"
      final exitItem = MenuItem.createWithLabelAndType(
        'Beenden',
        MenuItemType.normal,
      );
      if (exitItem != null) {
        exitItem.addListener((event) {
          if (event is MenuItemClickedEvent) {
            quitApp();
          }
        });
        _menu!.addItem(exitItem);
      }

      _trayIcon?.setContextMenu(_menu!);
    } catch (e) {
      debugPrint('Menu update failed: $e');
    }
  }

  // ----------------------------------------------------- Window Interception

  @override
  void onWindowClose() async {
    if (keepInTray) {
      await windowManager.hide();
    } else {
      await quitApp();
    }
  }

  // ----------------------------------------------------- Lifecycle & Exit

  /// Fährt die App sauber herunter (verhindert Ghost-Tray-Bugs).
  Future<void> quitApp() async {
    if (onAppQuit != null) {
      await onAppQuit!();
    }

    try {
      _trayIcon?.dispose();
    } catch (_) {}

    try {
      await windowManager.destroy();
    } catch (_) {}

    exit(0);
  }

  /// Setzt das App-Icon (sowohl Fenster als auch Tray)
  Future<void> setAppIcon(String path) async {
    try {
      await windowManager.setIcon(path);
      _trayIcon?.icon = ImageAsset.fromAsset(path);
      _trayIcon?.setTooltip('Music Companion');
    } catch (e) {
      debugPrint('App Icon change not supported: $e');
    }
  }
}