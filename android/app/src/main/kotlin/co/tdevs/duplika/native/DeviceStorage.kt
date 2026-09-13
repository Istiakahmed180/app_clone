package co.tdevs.duplika.native

import android.content.Context
import android.os.StatFs

/**
 * How much room is left on the volume clone containers are written to.
 *
 * Measures `filesDir` rather than the external volume: a container lives in the app's
 * own internal storage, so that is the figure that decides whether an install fits.
 * The same pair of numbers already appears in the diagnostics report; this is the path
 * that puts them in front of a decision instead of a log.
 *
 * Free space is a moving number — another app can claim a gigabyte between this read
 * and the install — so callers should treat it as current, not reserved.
 */
class DeviceStorage(private val context: Context) {

    fun status(): Map<String, Any?> =
        StatFs(context.filesDir.absolutePath).let { stat ->
            mapOf(
                "freeBytes" to stat.availableBlocksLong * stat.blockSizeLong,
                "totalBytes" to stat.blockCountLong * stat.blockSizeLong,
            )
        }
}
