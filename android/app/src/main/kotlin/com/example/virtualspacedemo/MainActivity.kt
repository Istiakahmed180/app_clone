package com.example.virtualspacedemo

import com.example.virtualspacedemo.native.NativeBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var nativeBridge: NativeBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeBridge = NativeBridge(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nativeBridge?.detach()
        nativeBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
