//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import audio_session
import audio_service
import file_picker
import media_kit_libs_macos_video
import screen_retriever
import sqflite_darwin
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  AudioSessionPlugin.register(with: registry.registrar(forPlugin: "AudioSessionPlugin"))
  AudioServicePlugin.register(with: registry.registrar(forPlugin: "AudioServicePlugin"))
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  MediaKitLibsMacosVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosVideoPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
