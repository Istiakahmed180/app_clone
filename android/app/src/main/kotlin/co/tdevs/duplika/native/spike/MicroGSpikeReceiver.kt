package co.tdevs.duplika.native.spike

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * SPIKE ONLY — see [MicroGSpike].
 *
 *   adb shell am broadcast -a co.tdevs.duplika.spike.MICROG --es op status
 *   adb shell am broadcast -a co.tdevs.duplika.spike.MICROG --es op wakegcm --es profileId digi-test
 *
 * Delivery may be skipped while the app is backgrounded (background execution limits); the
 * host is normally kept foreground by an open clone, which is when the spike runs.
 */
class MicroGSpikeReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        Log.e(TAG, "receiver invoked op=${intent.getStringExtra("op")}")
        MicroGSpike.run(
            context = context,
            op = intent.getStringExtra("op") ?: "status",
            onlyUser = intent.getIntExtra("userId", Int.MIN_VALUE),
            profileId = intent.getStringExtra("profileId") ?: MicroGSpike.DEFAULT_PROFILE,
            packageName = intent.getStringExtra("package") ?: MicroGSpike.DEFAULT_PACKAGE,
        )
    }

    companion object {
        const val ACTION = "co.tdevs.duplika.spike.MICROG"
        private const val TAG = "MicroGSpike"
    }
}
