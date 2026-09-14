package co.tdevs.duplika.native.spike

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log

/**
 * SPIKE ONLY — not production code. Lives on `spike/microg-container`.
 *
 * Visible-free, no-UI trigger so the spike can be driven from adb even when the app is in
 * the background and manifest-broadcast delivery is blocked by background execution limits:
 *
 *   adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op install
 *   adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op status
 *   adb shell am start -n co.tdevs.duplika/.native.spike.MicroGSpikeActivity --es op uninstall
 *
 * `launch` deliberately leaves the activity alive so the host stays foreground (Android 15
 * aborts a background activity launch), which means later commands arrive through
 * [onNewIntent] rather than [onCreate] — both are handled here.
 */
class MicroGSpikeActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handle(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        handle(intent)
    }

    private fun handle(intent: Intent?) {
        val op = intent?.getStringExtra("op") ?: "status"
        val onlyUser = intent?.getIntExtra("userId", Int.MIN_VALUE) ?: Int.MIN_VALUE
        val profileId = intent?.getStringExtra("profileId") ?: MicroGSpike.DEFAULT_PROFILE
        val packageName = intent?.getStringExtra("package") ?: MicroGSpike.DEFAULT_PACKAGE
        Log.i(TAG, "activity invoked op=$op")
        // Work off the main thread: installs are slow and must not block the launch.
        Thread(
            { MicroGSpike.run(applicationContext, op, onlyUser, profileId, packageName) },
            "microg-spike",
        ).start()
        // Keep the host app in the foreground for `launch`: Android 15 aborts a background
        // activity launch (BAL), which is what made the clone's ProxyActivity not start.
        if (op != "launch") {
            finish()
        }
    }

    companion object {
        private const val TAG = "MicroGSpike"
    }
}
