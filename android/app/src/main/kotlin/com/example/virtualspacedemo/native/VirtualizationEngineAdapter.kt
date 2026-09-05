package com.example.virtualspacedemo.native

import android.app.Application
import android.content.Context

/**
 * The seam between Virtual Space and whichever third-party virtualization backend is in
 * use. No type from the backend may appear in this file's signatures, so replacing the
 * backend never reaches [RealVirtualizationEngine], [NativeBridge] or the Flutter code.
 *
 * A virtual profile is addressed by an integer `virtualUserId`, which every known
 * container engine exposes in some form.
 */
interface VirtualizationEngineAdapter {

    /** Human-readable backend identity, surfaced for diagnostics only. */
    val backendName: String

    /** Called from the host `Application.attachBaseContext`, in every process. */
    fun attachBaseContext(application: Application, base: Context)

    /** Called from the host `Application.onCreate`, in every process. */
    fun onCreate(application: Application)

    /**
     * Whether the backend is usable on this device right now. Returns a typed reason
     * when it is not, so the UI can explain rather than silently disable itself.
     */
    fun checkAvailability(context: Context): EngineAvailability

    /** Idempotent; safe to call once the engine has already started. */
    fun initialize(context: Context): EngineResult<Unit>

    fun installPackage(packageName: String, virtualUserId: Int): EngineResult<Unit>

    /** Installs a standalone APK file (not necessarily installed on the host). */
    fun installApkFile(apkPath: String, virtualUserId: Int): EngineResult<Unit>

    fun uninstallPackage(packageName: String, virtualUserId: Int): EngineResult<Unit>

    fun isPackageInstalled(packageName: String, virtualUserId: Int): Boolean

    fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit>

    fun stop(packageName: String, virtualUserId: Int): EngineResult<Unit>

    fun isRunning(packageName: String, virtualUserId: Int): Boolean

    fun deleteVirtualUser(virtualUserId: Int): EngineResult<Unit>

    fun listVirtualUserIds(): List<Int>
}

/** Why the backend can or cannot run here. */
sealed interface EngineAvailability {
    data object Available : EngineAvailability
    data class Unavailable(val code: String, val message: String) : EngineAvailability
}

/**
 * A backend call outcome. Errors carry a stable code that [NativeBridge] forwards to
 * Flutter, so failures are never swallowed or reported as success.
 */
sealed interface EngineResult<out T> {
    data class Success<T>(val value: T) : EngineResult<T>
    data class Failure(val code: String, val message: String) : EngineResult<Nothing>

    companion object {
        fun ok(): EngineResult<Unit> = Success(Unit)
    }
}

/** Stable error codes shared by the adapter, the bridge and the Flutter error mapper. */
object EngineErrorCodes {
    const val VIRTUALIZATION_NOT_AVAILABLE = "VIRTUALIZATION_NOT_AVAILABLE"
    const val ENGINE_INITIALIZATION_FAILED = "ENGINE_INITIALIZATION_FAILED"
    const val ENGINE_UNSUPPORTED_ANDROID_VERSION = "ENGINE_UNSUPPORTED_ANDROID_VERSION"
    const val ABI_NOT_SUPPORTED = "ABI_NOT_SUPPORTED"
    const val APP_NOT_FOUND = "APP_NOT_FOUND"
    const val APP_NOT_SUPPORTED = "APP_NOT_SUPPORTED"
    const val SECURE_ENV_REQUIRED = "SECURE_ENV_REQUIRED"
    const val APP_INSTALL_FAILED = "APP_INSTALL_FAILED"
    const val APK_INVALID = "APK_INVALID"
    const val APK_UNREADABLE = "APK_UNREADABLE"
    const val APP_ALREADY_CLONED = "APP_ALREADY_CLONED"
    const val PROFILE_CREATE_FAILED = "PROFILE_CREATE_FAILED"
    const val PROFILE_DELETE_FAILED = "PROFILE_DELETE_FAILED"
    const val VIRTUAL_APP_NOT_INSTALLED = "VIRTUAL_APP_NOT_INSTALLED"
    const val VIRTUAL_APP_LAUNCH_FAILED = "VIRTUAL_APP_LAUNCH_FAILED"
}
