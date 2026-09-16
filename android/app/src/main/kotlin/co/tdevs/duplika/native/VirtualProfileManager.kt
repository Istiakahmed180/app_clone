package co.tdevs.duplika.native

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Maps a Flutter profile id (UUID) onto the engine's integer virtual user id.
 *
 * The mapping is owned natively because the engine's user ids are engine state: if Flutter
 * and the engine ever disagreed, a profile could silently launch another profile's data.
 * Ids are allocated as the smallest unused non-negative integer and are never reused while
 * the mapping still holds them.
 *
 * An id whose container could not be torn down is *quarantined* rather than freed. The
 * profile that owned it is gone, so nothing will ever ask for that id again — but its data
 * is still on disk underneath it, and handing it to the next clone would open somebody's
 * account in a space that was never theirs. A quarantined id is never allocated again.
 */
class VirtualProfileManager(context: Context) {

    private val prefs = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    @Synchronized
    fun virtualUserIdFor(profileId: String): Int? = readMapping()[profileId]

    /** Returns the existing id for [profileId], or allocates a new one. */
    @Synchronized
    fun getOrCreate(profileId: String): Int {
        val mapping = readMapping()
        mapping[profileId]?.let { return it }

        val used = mapping.values.toSet() + readQuarantine()
        var candidate = 0
        while (candidate in used) candidate++

        mapping[profileId] = candidate
        writeMapping(mapping)
        Slog.i(Slog.PROFILE, "Mapped profile $profileId to virtual user $candidate")
        return candidate
    }

    @Synchronized
    fun remove(profileId: String): Int? {
        val mapping = readMapping()
        val removed = mapping.remove(profileId) ?: return null
        writeMapping(mapping)
        Slog.i(Slog.PROFILE, "Unmapped profile $profileId from virtual user $removed")
        return removed
    }

    /**
     * Drops [profileId]'s mapping and reserves its id permanently.
     *
     * For a container the engine refused to delete: the profile is unreachable from here
     * on, but its data survives under that id, so the id must never be handed out again.
     * Returns the reserved id, or null when the profile had no mapping.
     */
    @Synchronized
    fun quarantine(profileId: String): Int? {
        val removed = remove(profileId) ?: return null
        val quarantined = readQuarantine()
        if (quarantined.add(removed)) {
            writeQuarantine(quarantined)
            Slog.w(
                Slog.PROFILE,
                "Quarantined virtual user $removed: its container could not be removed",
            )
        }
        return removed
    }

    @Synchronized
    fun allMappings(): Map<String, Int> = readMapping()

    /**
     * Remembers where an imported APK was stored, so a container whose install record the
     * engine lost can be rebuilt without asking the user to pick the file again.
     */
    @Synchronized
    fun rememberApkPath(profileId: String, apkPath: String) {
        val paths = readApkPaths()
        paths[profileId] = apkPath
        writeApkPaths(paths)
    }

    @Synchronized
    fun rememberApkPaths(profileId: String, apkPaths: List<String>) {
        val paths = readApkPathSets()
        paths[profileId] = apkPaths
        writeApkPathSets(paths)
    }

    @Synchronized
    fun apkPathsFor(profileId: String): List<String> =
        readApkPathSets()[profileId] ?: apkPathFor(profileId)?.let { listOf(it) }.orEmpty()

    @Synchronized
    fun apkPathFor(profileId: String): String? = readApkPaths()[profileId]

    @Synchronized
    fun forgetApkPath(profileId: String) {
        val paths = readApkPaths()
        if (paths.remove(profileId) != null) {
            writeApkPaths(paths)
        }
    }

    @Synchronized
    fun forgetApkPaths(profileId: String) {
        val paths = readApkPathSets()
        if (paths.remove(profileId) != null) writeApkPathSets(paths)
        forgetApkPath(profileId)
    }

    private fun readApkPathSets(): MutableMap<String, List<String>> {
        val raw = prefs.getString(KEY_APK_PATH_SETS, null) ?: return mutableMapOf()
        return try {
            val json = JSONObject(raw)
            val result = mutableMapOf<String, List<String>>()
            json.keys().forEach { key ->
                val values = json.getJSONArray(key)
                result[key] = List(values.length()) { index -> values.getString(index) }
            }
            result
        } catch (error: Exception) {
            Slog.e(Slog.PROFILE, "APK path-set map unreadable; starting empty", error)
            mutableMapOf()
        }
    }

    private fun writeApkPathSets(paths: Map<String, List<String>>) {
        val json = JSONObject()
        paths.forEach { (key, values) -> json.put(key, JSONArray(values)) }
        prefs.edit().putString(KEY_APK_PATH_SETS, json.toString()).commit()
    }

    private fun readApkPaths(): MutableMap<String, String> {
        val raw = prefs.getString(KEY_APK_PATHS, null) ?: return mutableMapOf()
        return try {
            val json = JSONObject(raw)
            val result = mutableMapOf<String, String>()
            json.keys().forEach { key -> result[key] = json.getString(key) }
            result
        } catch (error: Exception) {
            Slog.e(Slog.PROFILE, "APK path map unreadable; starting empty", error)
            mutableMapOf()
        }
    }

    private fun writeApkPaths(paths: Map<String, String>) {
        val json = JSONObject()
        paths.forEach { (key, value) -> json.put(key, value) }
        prefs.edit().putString(KEY_APK_PATHS, json.toString()).commit()
    }

    private fun readQuarantine(): MutableSet<Int> {
        val raw = prefs.getString(KEY_QUARANTINE, null) ?: return mutableSetOf()
        return try {
            val json = JSONArray(raw)
            MutableList(json.length()) { index -> json.getInt(index) }.toMutableSet()
        } catch (error: Exception) {
            // Same reasoning as readMapping: silently forgetting which ids are unsafe is
            // exactly how a reserved container gets handed to the next clone.
            Slog.e(Slog.PROFILE, "Quarantine list unreadable; refusing to allocate", error)
            throw IllegalStateException("The quarantined virtual user list is unreadable.", error)
        }
    }

    private fun writeQuarantine(ids: Set<Int>) {
        prefs.edit().putString(KEY_QUARANTINE, JSONArray(ids.toList()).toString()).commit()
    }

    private fun readMapping(): MutableMap<String, Int> {
        val raw = prefs.getString(KEY_MAPPING, null) ?: return mutableMapOf()
        return try {
            val json = JSONObject(raw)
            val result = mutableMapOf<String, Int>()
            json.keys().forEach { key -> result[key] = json.getInt(key) }
            result
        } catch (error: Exception) {
            // Never an empty map. Allocation hands out the lowest free id, so starting
            // empty re-issues 0, 1, 2... over containers that already hold other profiles'
            // data — the exact crossover this class exists to prevent. Failing the call
            // keeps every container shut, and NativeBridge turns it into an error the user
            // sees rather than a clone quietly opening the wrong account.
            Slog.e(Slog.PROFILE, "Profile mapping unreadable; refusing to allocate", error)
            throw IllegalStateException("The profile-to-virtual-user mapping is unreadable.", error)
        }
    }

    private fun writeMapping(mapping: Map<String, Int>) {
        val json = JSONObject()
        mapping.forEach { (key, value) -> json.put(key, value) }
        prefs.edit().putString(KEY_MAPPING, json.toString()).commit()
    }

    private companion object {
        const val PREFS_NAME = "duplika_profile_mapping"
        const val KEY_MAPPING = "profile_to_virtual_user"
        const val KEY_APK_PATHS = "profile_to_apk_path"
        const val KEY_APK_PATH_SETS = "profile_to_apk_paths"
        const val KEY_QUARANTINE = "quarantined_virtual_users"
    }
}
