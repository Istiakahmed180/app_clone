package com.example.virtualspacedemo.native

import android.app.Activity
import android.content.pm.PackageManager

/**
 * Requests, from the user, the runtime permissions a guest application needs.
 *
 * A guest runs inside the host's process and under the host's UID, so Android checks the
 * *host's* grants when the guest touches the camera, storage or location. Bridging is
 * therefore not a workaround — it is the only way those APIs can work, and it goes through
 * the ordinary system permission dialog so the user decides.
 *
 * Nothing here elevates privileges: only permissions the host already declares can be
 * requested, and a denial is respected.
 */
class PermissionBridge {

    /**
     * What happened to a request. A caller must be able to tell "the user answered" apart
     * from "we never asked" — reporting the latter as a completed request would leave the
     * UI claiming the user had decided when they had not.
     */
    sealed interface Outcome {
        data class Answered(val grants: Map<String, Boolean>) : Outcome

        /** Another request is still on screen. */
        data object Busy : Outcome

        /** The host went away before the user answered. */
        data object Cancelled : Outcome
    }

    private var pending: ((Outcome) -> Unit)? = null

    /**
     * Asks for [permissions]. [onResult] is invoked exactly once.
     *
     * Already-granted permissions are filtered out, so a request with nothing outstanding
     * completes at once without showing a dialog.
     */
    fun request(
        activity: Activity,
        permissions: List<String>,
        onResult: (Outcome) -> Unit,
    ) {
        val outstanding = permissions.filter {
            activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }

        if (outstanding.isEmpty()) {
            onResult(Outcome.Answered(permissions.associateWith { true }))
            return
        }

        if (pending != null) {
            Slog.w(Slog.PROFILE, "A permission request is already on screen")
            onResult(Outcome.Busy)
            return
        }

        pending = onResult
        Slog.i(Slog.PROFILE, "Requesting ${outstanding.size} permission(s) for a guest app")
        activity.requestPermissions(outstanding.toTypedArray(), REQUEST_CODE)
    }

    /**
     * Completes a request that can no longer be answered.
     *
     * Without this, an activity torn down while the dialog is up would leave the caller's
     * reply pending forever and the UI stuck waiting.
     */
    fun cancelPending() {
        val callback = pending ?: return
        pending = null
        Slog.w(Slog.PROFILE, "Permission request abandoned; host is gone")
        callback(Outcome.Cancelled)
    }

    /** Called from the host activity; returns true when this bridge consumed the result. */
    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) {
            return false
        }

        val callback = pending ?: return true
        pending = null

        val grants = permissions.mapIndexed { index, permission ->
            permission to (grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED)
        }.toMap()

        Slog.i(Slog.PROFILE, "Permission result: ${grants.count { it.value }}/${grants.size} granted")
        callback(Outcome.Answered(grants))
        return true
    }

    private companion object {
        const val REQUEST_CODE = 0x5150
    }
}
