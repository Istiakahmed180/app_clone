package co.tdevs.duplika.native

import android.app.Activity
import android.content.Context
import com.google.android.ump.ConsentDebugSettings
import com.google.android.ump.ConsentInformation
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.FormError
import com.google.android.ump.UserMessagingPlatform

/**
 * The GDPR/TCF consent form, via Google's User Messaging Platform.
 *
 * Consent is advisory here, not a gate. Duplika shows no ads and sends no personal data
 * anywhere, so a consent failure -- no network, no configured message, an EEA form that
 * will not load -- must never stop the user reaching their clones. Every failure path
 * reports the reason and lets the caller continue.
 *
 * UMP requires the main thread and a real Activity. Callbacks arrive on the main thread.
 */
class ConsentManager(context: Context) {

    private val consentInformation: ConsentInformation =
        UserMessagingPlatform.getConsentInformation(context.applicationContext)

    /** Current state, without contacting the network. */
    fun status(): Map<String, Any?> = mapOf(
        "status" to consentInformation.consentStatus.asName(),
        "canRequestAds" to consentInformation.canRequestAds(),
        "privacyOptionsRequired" to
            (consentInformation.privacyOptionsRequirementStatus ==
                ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED),
        "formAvailable" to consentInformation.isConsentFormAvailable,
    )

    /**
     * Refreshes consent state and shows the form when UMP says one is required.
     *
     * [debugGeography] and [testDeviceHashedId] exist because the form only appears for
     * real EEA/UK users otherwise, which makes the flow untestable anywhere else. Both are
     * ignored by UMP in a release build signed with a release key.
     */
    fun request(
        activity: Activity,
        debugGeography: String?,
        testDeviceHashedId: String?,
        onDone: (Map<String, Any?>) -> Unit,
    ) {
        val parameters = ConsentRequestParameters.Builder()
            .apply {
                val debug = debugSettings(activity, debugGeography, testDeviceHashedId)
                if (debug != null) {
                    setConsentDebugSettings(debug)
                }
            }
            .build()

        consentInformation.requestConsentInfoUpdate(
            activity,
            parameters,
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { formError ->
                    if (formError == null) {
                        Slog.i(Slog.CONSENT, "Consent resolved: ${consentInformation.consentStatus.asName()}")
                        onDone(status() + mapOf("shown" to true))
                    } else {
                        // A form that will not load is not a reason to hold the app hostage.
                        Slog.w(Slog.CONSENT, "Consent form unavailable: ${formError.describe()}")
                        onDone(status() + errorOf(formError))
                    }
                }
            },
            { requestError ->
                Slog.w(Slog.CONSENT, "Consent info update failed: ${requestError.describe()}")
                onDone(status() + errorOf(requestError))
            },
        )
    }

    /**
     * Re-opens the form for a user who already answered.
     *
     * Required by the TCF: consent must stay withdrawable after it is given. Only
     * meaningful while [status] reports `privacyOptionsRequired`.
     */
    fun showPrivacyOptions(activity: Activity, onDone: (Map<String, Any?>) -> Unit) {
        UserMessagingPlatform.showPrivacyOptionsForm(activity) { formError ->
            if (formError == null) {
                onDone(status() + mapOf("shown" to true))
            } else {
                Slog.w(Slog.CONSENT, "Privacy options form failed: ${formError.describe()}")
                onDone(status() + errorOf(formError))
            }
        }
    }

    /** Clears the stored answer so the form can be seen again. Development only. */
    fun reset() {
        consentInformation.reset()
        Slog.i(Slog.CONSENT, "Consent state reset")
    }

    private fun debugSettings(
        activity: Activity,
        geography: String?,
        testDeviceHashedId: String?,
    ): ConsentDebugSettings? {
        val geographyCode = when (geography?.uppercase()) {
            "EEA" -> ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA
            "NOT_EEA" -> ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_NOT_EEA
            "REGULATED_US_STATE" ->
                ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_REGULATED_US_STATE
            "OTHER" -> ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_OTHER
            else -> null
        }
        if (geographyCode == null && testDeviceHashedId.isNullOrBlank()) {
            return null
        }

        return ConsentDebugSettings.Builder(activity)
            .apply {
                if (geographyCode != null) {
                    setDebugGeography(geographyCode)
                }
                if (!testDeviceHashedId.isNullOrBlank()) {
                    addTestDeviceHashedId(testDeviceHashedId)
                }
            }
            .build()
    }

    private fun errorOf(error: FormError): Map<String, Any?> = mapOf(
        "shown" to false,
        "errorCode" to error.errorCode,
        "errorMessage" to error.message,
    )

    private fun FormError.describe(): String = "$errorCode ${message.orEmpty()}"

    private fun Int.asName(): String = when (this) {
        ConsentInformation.ConsentStatus.REQUIRED -> "required"
        ConsentInformation.ConsentStatus.NOT_REQUIRED -> "notRequired"
        ConsentInformation.ConsentStatus.OBTAINED -> "obtained"
        else -> "unknown"
    }
}
