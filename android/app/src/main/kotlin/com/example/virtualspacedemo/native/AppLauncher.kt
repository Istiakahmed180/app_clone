package com.example.virtualspacedemo.native

import android.content.Context
import android.content.Intent

/**
 * Launches the controlled test application through Android's official launcher intent.
 *
 * There is no virtualization here: the real, already-installed application is started in
 * its own normal process with its own normal data directory.
 */
class AppLauncher(private val context: Context) {

    fun launch(packageName: String): Map<String, Any?> {
        val intent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return failure(ERROR_NOT_INSTALLED)

        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return try {
            context.startActivity(intent)
            mapOf("success" to true, "packageName" to packageName)
        } catch (_: SecurityException) {
            failure(ERROR_LAUNCH_FAILED)
        } catch (_: android.content.ActivityNotFoundException) {
            failure(ERROR_LAUNCH_FAILED)
        }
    }

    private fun failure(error: String): Map<String, Any?> =
        mapOf("success" to false, "error" to error)

    companion object {
        const val ERROR_NOT_INSTALLED = "TEST_APP_NOT_INSTALLED"
        const val ERROR_LAUNCH_FAILED = "LAUNCH_FAILED"
    }
}
