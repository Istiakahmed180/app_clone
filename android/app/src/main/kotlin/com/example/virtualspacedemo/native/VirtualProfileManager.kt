package com.example.virtualspacedemo.native

import android.content.Context
import org.json.JSONObject

/**
 * Maps a Flutter profile id (UUID) onto the engine's integer virtual user id.
 *
 * The mapping is owned natively because the engine's user ids are engine state: if Flutter
 * and the engine ever disagreed, a profile could silently launch another profile's data.
 * Ids are allocated as the smallest unused non-negative integer and are never reused while
 * the mapping still holds them.
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

        val used = mapping.values.toSet()
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

    @Synchronized
    fun allMappings(): Map<String, Int> = readMapping()

    private fun readMapping(): MutableMap<String, Int> {
        val raw = prefs.getString(KEY_MAPPING, null) ?: return mutableMapOf()
        return try {
            val json = JSONObject(raw)
            val result = mutableMapOf<String, Int>()
            json.keys().forEach { key -> result[key] = json.getInt(key) }
            result
        } catch (error: Exception) {
            Slog.e(Slog.PROFILE, "Profile mapping unreadable; starting empty", error)
            mutableMapOf()
        }
    }

    private fun writeMapping(mapping: Map<String, Int>) {
        val json = JSONObject()
        mapping.forEach { (key, value) -> json.put(key, value) }
        prefs.edit().putString(KEY_MAPPING, json.toString()).commit()
    }

    private companion object {
        const val PREFS_NAME = "virtual_space_profile_mapping"
        const val KEY_MAPPING = "profile_to_virtual_user"
    }
}
