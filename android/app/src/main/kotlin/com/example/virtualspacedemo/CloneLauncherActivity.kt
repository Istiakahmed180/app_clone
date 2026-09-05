package com.example.virtualspacedemo

import android.app.Activity
import android.os.Bundle
import android.widget.Toast
import com.example.virtualspacedemo.native.EngineResult
import com.example.virtualspacedemo.native.RealVirtualizationEngine
import com.example.virtualspacedemo.native.Slog

/**
 * Opens one clone straight from a home-screen shortcut.
 *
 * Deliberately has no UI of its own: the point of a shortcut is to reach the guest app
 * without passing through Virtual Space, so this starts the container and finishes.
 */
class CloneLauncherActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val profileId = intent?.getStringExtra(EXTRA_PROFILE_ID)
        val packageName = intent?.getStringExtra(EXTRA_PACKAGE_NAME)

        if (profileId.isNullOrBlank() || packageName.isNullOrBlank()) {
            Slog.w(Slog.LAUNCH, "Shortcut carried no profile; ignoring")
            finish()
            return
        }

        val engine = RealVirtualizationEngine(applicationContext, VirtualSpaceApplication.engine)
        when (val result = engine.launchProfile(profileId, packageName)) {
            is EngineResult.Success ->
                Slog.i(Slog.LAUNCH, "Shortcut launched $packageName")

            is EngineResult.Failure -> {
                // A shortcut can outlive the clone it points at, so say why rather than
                // failing silently on the home screen.
                Slog.w(Slog.LAUNCH, "Shortcut launch failed: ${result.code}")
                Toast.makeText(this, result.message, Toast.LENGTH_LONG).show()
            }
        }

        finish()
    }

    companion object {
        const val EXTRA_PROFILE_ID = "profileId"
        const val EXTRA_PACKAGE_NAME = "packageName"
    }
}
