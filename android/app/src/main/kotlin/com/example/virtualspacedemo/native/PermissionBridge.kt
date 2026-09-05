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

    private var pending: ((Map<String, Boolean>) -> Unit)? = null

    /**
     * Asks for [permissions]. [onResult] receives the per-permission outcome.
     *
     * Already-granted permissions are filtered out, so an empty request completes at once
     * without showing a dialog.
     */
    fun request(
        activity: Activity,
        permissions: List<String>,
        onResult: (Map<String, Boolean>) -> Unit,
    ) {
        val outstanding = permissions.filter {
            activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }

        if (outstanding.isEmpty()) {
            onResult(permissions.associateWith { true })
            return
        }

        if (pending != null) {
            onResult(emptyMap())
            return
        }

        pending = onResult
        Slog.i(Slog.PROFILE, "Requesting ${outstanding.size} permission(s) for a guest app")
        activity.requestPermissions(outstanding.toTypedArray(), REQUEST_CODE)
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

        val outcome = permissions.mapIndexed { index, permission ->
            permission to (grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED)
        }.toMap()

        Slog.i(Slog.PROFILE, "Permission result: ${outcome.count { it.value }}/${outcome.size} granted")
        callback(outcome)
        return true
    }

    private companion object {
        const val REQUEST_CODE = 0x5150
    }
}
