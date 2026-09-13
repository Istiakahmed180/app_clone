package co.tdevs.duplika.native

import android.app.ActivityManager
import android.content.Context
import android.os.StatFs

/**
 * What this device has room for: space to keep containers in, and memory to run them in.
 *
 * Storage is measured on `filesDir` rather than the external volume, because that is
 * where a container lives and so the only figure that decides whether one fits. Memory
 * is here for a different question — an idle container costs storage, a running one
 * costs RAM — and the two answers travel together so a decision never has to make two
 * round trips to learn them.
 *
 * Both are moving numbers. Another app can claim a gigabyte, or half the memory, between
 * this read and the install, so callers should treat them as current, not reserved.
 */
class DeviceCapacity(private val context: Context) {

    fun read(): Map<String, Any?> {
        val stat = StatFs(context.filesDir.absolutePath)
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val memory = manager?.let { ActivityManager.MemoryInfo().also(it::getMemoryInfo) }
        return mapOf(
            "freeBytes" to stat.availableBlocksLong * stat.blockSizeLong,
            "totalBytes" to stat.blockCountLong * stat.blockSizeLong,
            "totalMemBytes" to memory?.totalMem,
            "availMemBytes" to memory?.availMem,
            // The manufacturer's own declaration, and the closest thing to a verdict the
            // platform offers on whether this device should be asked to run much at once.
            "isLowRamDevice" to manager?.isLowRamDevice,
        )
    }
}
