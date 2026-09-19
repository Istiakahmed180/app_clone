package co.tdevs.duplika.native.blackbox

import android.app.Activity

/**
 * The activities this guest process is currently running.
 *
 * `ActivityThread` keeps them in a map of its own records, one per token, and there is no public
 * way to ask for them — `Application.registerActivityLifecycleCallbacks` would only see the ones
 * that start after it is installed, which is too late for a repair that has to know what is
 * already on screen. So the map is read directly, and read defensively: a shape this does not
 * recognise yields an empty list rather than an exception, which leaves the engine's own
 * behaviour in place.
 *
 * Only this process's activities are visible here. A clone's other processes keep their own, so
 * a caller that needs to reason about a whole task has to say so.
 */
internal object GuestActivities {

    /**
     * Every live instance of [className] in this process: not finishing, not destroyed, and so
     * still able to be shown or restarted. A component runs in exactly one process, so for a
     * component this process hosts, an empty list means there is no instance anywhere.
     */
    fun liveHere(className: String): List<Activity> = runCatching {
        val activityThread = Class.forName("android.app.ActivityThread")
        val current = activityThread.getDeclaredMethod("currentActivityThread")
            .apply { isAccessible = true }
            .invoke(null) ?: return emptyList()
        val records = activityThread.getDeclaredField("mActivities")
            .apply { isAccessible = true }
            .get(current) as? Map<*, *> ?: return emptyList()

        records.values.mapNotNull { record -> record?.let(::activityOf) }
            .filter { it.javaClass.name == className && !it.isFinishing && !it.isDestroyed }
    }.getOrDefault(emptyList())

    /** The `Activity` held by one of `ActivityThread`'s records, found by type rather than name. */
    private fun activityOf(record: Any): Activity? {
        var cursor: Class<*>? = record.javaClass
        while (cursor != null && cursor != Any::class.java) {
            for (field in cursor.declaredFields) {
                if (!Activity::class.java.isAssignableFrom(field.type)) continue
                return runCatching {
                    field.isAccessible = true
                    field.get(record) as? Activity
                }.getOrNull()
            }
            cursor = cursor.superclass
        }
        return null
    }
}
