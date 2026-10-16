package com.hevanto_it.swayriderapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CompassStreamHandler.CHANNEL)
            .setStreamHandler(CompassStreamHandler(this))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SpeechHandler.CHANNEL)
            .setMethodCallHandler(SpeechHandler(this))
    }
}
