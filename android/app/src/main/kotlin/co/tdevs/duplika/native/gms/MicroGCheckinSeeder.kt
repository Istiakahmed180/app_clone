package co.tdevs.duplika.native.gms

import co.tdevs.duplika.native.VirtualizationEngineAdapter

/**
 * Turns on microG's checkin and GCM (push) services inside a freshly provisioned container.
 *
 * microG stores these two switches in its own default `SharedPreferences`, and both default
 * to **off**. With checkin off, `PushRegisterService.ensureCheckinIsUpToDate` throws
 * `Checkin disabled` and no app can obtain a push token. Measured on the emulator.
 *
 * Writing the file before the container's microG ever starts is safe: the guest's
 * SharedPreferences are read at process start, so the values take effect on first launch.
 * The file is located through the engine's own
 * [VirtualizationEngineAdapter.guestSharedPreferencesFile] rather than by hard-coding the
 * container layout.
 *
 * This configures microG; it does not spoof anything. The values written are the same ones
 * microG's own settings screen writes when the user enables "Device registration" and
 * "Cloud messaging".
 */
object MicroGCheckinSeeder {

    const val GMS_PACKAGE: String = "com.google.android.gms"
    const val PREFS_NAME: String = "com.google.android.gms_preferences"

    /** microG's `SettingsContract.CheckIn.ENABLED`. */
    const val CHECKIN_ENABLED: String = "checkin_enable_service"

    /** microG's `SettingsContract.Gcm.ENABLE_GCM`. */
    const val GCM_ENABLED: String = "gcm_enable_mcs_service"

    /**
     * microG's checkin service. Starting it once after provisioning lets checkin complete
     * *before* the user's first launch, which is what stops the first push registration from
     * racing it (`No checkin available` → the app has to be reopened).
     */
    const val CHECKIN_SERVICE: String = "org.microg.gms.checkin.CheckinService"

    /** Returns true when the preferences file was written. */
    fun seed(adapter: VirtualizationEngineAdapter, virtualUserId: Int): Boolean = runCatching {
        val file = adapter.guestSharedPreferencesFile(GMS_PACKAGE, virtualUserId, PREFS_NAME)
            ?: return false
        file.parentFile?.mkdirs()
        file.writeText(preferencesXml())
        true
    }.getOrDefault(false)

    private fun preferencesXml(): String = buildString {
        appendLine("<?xml version='1.0' encoding='utf-8' standalone='yes' ?>")
        appendLine("<map>")
        appendLine("    <boolean name=\"$CHECKIN_ENABLED\" value=\"true\" />")
        appendLine("    <boolean name=\"$GCM_ENABLED\" value=\"true\" />")
        appendLine("</map>")
    }
}
