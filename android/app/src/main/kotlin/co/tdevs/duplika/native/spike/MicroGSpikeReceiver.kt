package co.tdevs.duplika.native.spike

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** SPIKE ONLY — see [MicroGSpike]. Broadcast may be dropped by background limits; prefer [MicroGSpikeActivity]. */
class MicroGSpikeReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        Log.i(TAG, "receiver invoked")
        MicroGSpike.run(context, intent.getStringExtra("op") ?: "status", intent.getIntExtra("userId", Int.MIN_VALUE))
    }

    companion object {
        const val ACTION = "co.tdevs.duplika.spike.MICROG"
        private const val TAG = "MicroGSpike"
    }
}
