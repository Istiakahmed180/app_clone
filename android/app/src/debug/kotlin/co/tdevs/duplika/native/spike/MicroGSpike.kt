package co.tdevs.duplika.native.spike

import android.content.Context
import android.util.Log
import co.tdevs.duplika.BuildConfig
import co.tdevs.duplika.DuplikaApplication
import co.tdevs.duplika.native.BackgroundActivity
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.RealVirtualizationEngine
import co.tdevs.duplika.native.Slog
import co.tdevs.duplika.native.VirtualProfileManager
import java.io.File

/**
 * SPIKE ONLY — not production code. Lives on `spike/microg-container`.
 *
 * Drives a microG-in-container experiment from adb without the Flutter UI:
 *  - `clone`   install a target app into a synthetic profile
 *  - `install` install the bundled microG artefacts into that (or every) profile
 *  - `launch`  launch the cloned app so its FCM/Google behaviour can be observed
 *  - `uninstall` / `status`
 *
 * It bypasses `AppSecurityChecker` on purpose: microG's package name resolves to the host's
 * real Play services, which declares `REQUIRE_SECURE_ENV`, so the admission policy correctly
 * refuses it — the spike needs to measure what happens past that door.
 */
object MicroGSpike {

    private const val TAG = "MicroGSpike"
    const val DEFAULT_PROFILE = "spike-cabex"
    const val DEFAULT_PACKAGE = "com.moneyin.cabex.fx"

    fun run(
        context: Context,
        op: String,
        onlyUser: Int,
        profileId: String = DEFAULT_PROFILE,
        packageName: String = DEFAULT_PACKAGE,
    ) {
        if (!BuildConfig.DEBUG) {
            Log.w(TAG, "Ignoring spike request on a non-debug build")
            return
        }
        Log.i(TAG, "op=$op profile=$profileId package=$packageName onlyUser=$onlyUser")
        Slog.i(Slog.ENGINE, "MicroGSpike op=$op profile=$profileId package=$packageName")
        val engine = RealVirtualizationEngine(context, DuplikaApplication.engine)
        when (op) {
            "clone" -> clone(engine, profileId, packageName)
            "install" -> install(context, engine, profileId, onlyUser)
            "launch" -> launch(engine, profileId, packageName)
            "wakegcm" -> wakeGcm(context, profileId)
            "cleardata" -> clearData(engine, profileId, packageName)
            "uninstall" -> uninstall(context, onlyUser)
            "background" -> backgroundActivity(context)
            else -> status(context)
        }
    }

    // Internal files dir, not external: the emulator has no root, so APKs pushed to
    // /sdcard/Android/data/... stay shell-owned and the app cannot list them.
    private fun clone(engine: RealVirtualizationEngine, profileId: String, packageName: String) {
        when (val result = engine.installAppToProfile(profileId, packageName, provisionGms = false)) {
            is EngineResult.Success -> Log.i(TAG, "cloned $packageName into profile $profileId")
            is EngineResult.Failure -> Log.e(TAG, "clone failed: ${result.code} ${result.message}")
        }
    }

    /**
     * Starts microG's MCS service in the container so it opens its receive connection
     * (`mtalk.google.com:5228`). Without it no FCM message can be delivered.
     */
    private fun wakeGcm(context: Context, profileId: String) {
        val userId = VirtualProfileManager(context).virtualUserIdFor(profileId)
        if (userId == null) {
            Log.e(TAG, "Profile $profileId has no virtual user")
            return
        }
        val result = engine().startContainerService(
            packageName = "com.google.android.gms",
            serviceClassName = "org.microg.gms.gcm.McsService",
            virtualUserId = userId,
            requireForeground = false,
            action = "org.microg.gms.gcm.mcs.CONNECT",
        )
        Log.i(TAG, "wakegcm user=$userId -> $result")
    }

    private fun engine() = DuplikaApplication.engine

    private fun clearData(engine: RealVirtualizationEngine, profileId: String, packageName: String) {
        when (val result = engine.clearProfileData(profileId, packageName)) {
            is EngineResult.Success -> Log.i(TAG, "cleared data for $packageName")
            is EngineResult.Failure -> Log.e(TAG, "clear data failed: ${result.code} ${result.message}")
        }
    }

    private fun launch(
        engine: RealVirtualizationEngine,
        profileId: String,
        packageName: String,
    ) {
        when (val result = engine.launchProfile(profileId, packageName)) {
            is EngineResult.Success -> Log.i(TAG, "launched $packageName")
            is EngineResult.Failure -> Log.e(TAG, "launch failed: ${result.code} ${result.message}")
        }
    }

    /**
     * Provisions microG through the real provider layer — the bundled `assets/microg/`
     * artefact, [co.tdevs.duplika.native.gms.MicroGProvider] and the engine install path.
     * This is the code path a shipping build would use, driven from adb for the spike.
     */
    private fun install(
        context: Context,
        engine: RealVirtualizationEngine,
        profileId: String,
        onlyUser: Int,
    ) {
        if (onlyUser != Int.MIN_VALUE) {
            Log.w(TAG, "op=install ignores onlyUser; microG is provisioned per profile via the provider")
        }
        when (val result = engine.provisionMicroG(profileId)) {
            is EngineResult.Success -> Log.i(TAG, "provisioned microG into profile $profileId")
            is EngineResult.Failure ->
                Log.e(TAG, "microG provisioning failed for $profileId: ${result.code} ${result.message}")
        }
    }

    private fun uninstall(context: Context, onlyUser: Int) {
        val packages = listOf("com.google.android.gms", "com.google.android.gsf", "com.android.vending")
        val users = VirtualProfileManager(context).allMappings().values
            .filter { onlyUser == Int.MIN_VALUE || it == onlyUser }
        users.forEach { userId ->
            packages.forEach { pkg ->
                val result = DuplikaApplication.engine.uninstallPackage(pkg, userId)
                Log.i(TAG, "uninstall $pkg from user $userId -> $result")
            }
        }
    }

    /** Reports the state the Settings row reads, off the same class the row calls. */
    private fun backgroundActivity(context: Context) {
        val state = BackgroundActivity(context).state()
        Log.i(TAG, "background state: $state")
        Slog.i(Slog.POWER, "MicroGSpike background state: $state")
    }

    private fun status(context: Context) {
        val mappings = VirtualProfileManager(context).allMappings()
        Log.i(TAG, "profile mappings: $mappings")
        Slog.i(Slog.ENGINE, "MicroGSpike status: mappings=$mappings")
    }
}
