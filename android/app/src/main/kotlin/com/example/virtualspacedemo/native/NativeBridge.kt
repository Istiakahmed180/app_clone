package com.example.virtualspacedemo.native

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The single Flutter <-> Android entry point.
 *
 * Android types (Context, Intent, PackageManager) stay behind this boundary; Flutter only
 * ever receives plain maps of primitives.
 */
class NativeBridge(context: Context) : MethodChannel.MethodCallHandler {

    private val testAppManager = TestAppManager(context)
    private val appLauncher = AppLauncher(context)
    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also { it.setMethodCallHandler(this) }
    }

    fun detach() {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_PLATFORM_INFO -> result.success(testAppManager.getPlatformInfo())
            METHOD_IS_INSTALLED -> result.success(testAppManager.isTestAppInstalled())
            METHOD_TEST_APP_INFO -> result.success(testAppManager.getTestAppInfo())
            METHOD_LAUNCH -> result.success(appLauncher.launch(TestAppManager.TEST_APP_PACKAGE))
            else -> result.notImplemented()
        }
    }

    companion object {
        const val CHANNEL_NAME = "virtual_space/native_bridge"

        private const val METHOD_PLATFORM_INFO = "getPlatformInfo"
        private const val METHOD_IS_INSTALLED = "isTestAppInstalled"
        private const val METHOD_TEST_APP_INFO = "getTestAppInfo"
        private const val METHOD_LAUNCH = "launchTestApp"
    }
}
