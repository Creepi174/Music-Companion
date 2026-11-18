package com.example.music_companion

import android.content.res.Configuration
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "musiccompanion/samsung"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deviceInfo" -> result.success(deviceInfo())
                    else -> result.notImplemented()
                }
            }
    }

    private fun deviceInfo(): String {
        val isSamsung = Build.MANUFACTURER.equals("samsung", ignoreCase = true)
        val dex = (resources.configuration.screenLayout
                and Configuration.SCREENLAYOUT_SIZE_MASK) >=
                Configuration.SCREENLAYOUT_SIZE_LARGE
        return "Samsung=$isSamsung · Modell=${Build.MODEL} · " +
                "Android=${Build.VERSION.RELEASE} · LargeLayout=$dex"
    }
}