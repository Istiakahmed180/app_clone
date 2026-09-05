package com.example.virtualspacedemo

import android.app.Application
import android.content.Context
import com.example.virtualspacedemo.native.VirtualizationEngineAdapter
import com.example.virtualspacedemo.native.blackbox.BlackBoxEngineAdapter

/**
 * Host application entry point.
 *
 * The virtualization engine must be attached before any other component runs, because
 * it also runs inside the engine's own stub processes (`:p0`, `:p1`, ...) where this
 * same Application class is instantiated. [VirtualizationEngineAdapter.attachBaseContext]
 * is responsible for detecting that case.
 */
class VirtualSpaceApplication : Application() {

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        engine.attachBaseContext(this, base)
    }

    override fun onCreate() {
        super.onCreate()
        engine.onCreate(this)
    }

    companion object {
        /**
         * The single engine instance for this process. Swapping this line is the only
         * change needed to move Virtual Space onto a different virtualization backend.
         */
        @JvmStatic
        val engine: VirtualizationEngineAdapter = BlackBoxEngineAdapter()
    }
}
