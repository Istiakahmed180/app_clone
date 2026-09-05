package com.example.virtualspacedemo.native

/**
 * Starts the controlled application inside a virtual profile.
 *
 * This is the Phase 2 replacement for [AppLauncher], which starts the ordinary installed
 * application through the platform launcher intent. Both paths are kept so the two can be
 * compared during testing, but a profile launch always goes through the engine.
 */
class VirtualAppLauncher(private val adapter: VirtualizationEngineAdapter) {

    fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.launch(packageName, virtualUserId)

    fun stop(packageName: String, virtualUserId: Int): EngineResult<Unit> =
        adapter.stop(packageName, virtualUserId)

    fun isRunning(packageName: String, virtualUserId: Int): Boolean =
        adapter.isRunning(packageName, virtualUserId)
}
