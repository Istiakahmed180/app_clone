package co.tdevs.duplika.native.blackbox

import android.content.Context
import android.os.Build
import android.os.Process
import android.webkit.WebView
import co.tdevs.duplika.WebViewProcessIsolation
import co.tdevs.duplika.native.Slog
import java.io.File
import java.io.RandomAccessFile
import java.nio.channels.FileLock

/**
 * Keeps two host processes running one guest process out of the same WebView directory.
 *
 * Chromium allows exactly one live process per WebView data directory and throws when a
 * second one starts:
 *
 *     java.lang.RuntimeException: Using WebView from more than one process at once with
 *     the same data directory is not supported. https://crbug.com/558377 :
 *     Current process com.google.android.gms:ui (pid 18338),
 *     lock owner  com.google.android.gms:ui (pid 16794)
 *
 * Bcore names that directory after the *guest*, in `BActivityThread.handleBindApplication`:
 *
 *     WebView.setDataDirectorySuffix(getUserId() + ":" + packageName + ":" + processName);
 *
 * which is right only while one guest process lives in one host process. It does not: a
 * guest process that is started again while its previous host process is still alive gets
 * a fresh proxy slot (`:p3` → `:p11`), and both processes then claim the one directory.
 * Duplika's own [co.tdevs.duplika.WebViewProcessIsolation] does give each host process a
 * distinct suffix, but it runs in `attachBaseContext` and Bcore overwrites it later.
 *
 * microG's sign-in screen is the case that made this visible: it is a WebView, so the
 * second attempt at "Continue with Google" inside a clone threw during `onCreate`, the
 * activity never started, and the window sat there taking no input.
 *
 * The repair only acts when it has to. It asks the same question Chromium will — is
 * anything holding `webview_data.lock` in the directory the guest-named suffix points at —
 * and leaves Bcore's suffix alone when the answer is no, so a clone keeps its cookies and
 * local storage across launches exactly as before. Only when the directory is genuinely
 * taken does it add this host process to the name, which costs that one process a fresh
 * WebView directory and is the only alternative to failing to start at all.
 */
object GuestWebViewDataDirRepair {

    /** Chromium's lock file, inside the directory the suffix selects. */
    private const val LOCK_FILE = "webview_data.lock"

    /**
     * Runs in the guest, between Bcore setting the suffix and the app's `Application`
     * being made, which is the only window where the value can still be changed: WebView
     * has not been loaded yet, so `setDataDirectorySuffix` is still allowed.
     *
     * Never fatal. Every failure leaves Bcore's suffix in place, which is the behaviour
     * this build had before the repair existed.
     */
    fun install(context: Context?, packageName: String?, processName: String?, virtualUserId: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return
        if (context == null || packageName.isNullOrBlank() || processName.isNullOrBlank()) return

        try {
            val engineSuffix = "$virtualUserId:$packageName:$processName"
            if (isDirectoryFree(context, engineSuffix)) return

            val suffix = sanitize("$engineSuffix:${hostProcessQualifier()}")
            WebView.setDataDirectorySuffix(suffix)
            Slog.i(
                Slog.BCORE,
                "WebView directory for $processName was held by another process; " +
                    "this one uses $suffix",
            )
        } catch (error: Throwable) {
            // IllegalStateException means something already loaded WebView here, in which
            // case the suffix is fixed and there is nothing left to choose.
            Slog.w(Slog.BCORE, "Guest WebView directory repair unavailable: ${error.message}")
        }
    }

    /**
     * Whether the directory [suffix] selects is unclaimed.
     *
     * Asked by taking Chromium's own lock and giving it straight back, which is the only
     * check that agrees with the one that would otherwise throw: the file exists whether
     * or not anyone holds it, and a stale owner recorded inside it says nothing about
     * whether the lock is held now.
     *
     * A directory that has never been used has no lock file, and creating one to ask is
     * pointless — nothing can be holding it — so that answers free without touching disk.
     */
    private fun isDirectoryFree(context: Context, suffix: String): Boolean {
        // Chromium derives its data directory from the suffix as `app_webview_<suffix>`,
        // by way of `Context.getDir`, so asking the guest's own context is what resolves
        // the engine's IO redirection the same way Chromium's call will.
        val directory = runCatching {
            context.getDir("webview_$suffix", Context.MODE_PRIVATE)
        }.getOrNull() ?: return true

        val lockFile = File(directory, LOCK_FILE)
        if (!lockFile.exists()) return true

        var lock: FileLock? = null
        return try {
            RandomAccessFile(lockFile, "rw").use { file ->
                lock = file.channel.tryLock()
                lock != null
            }
        } catch (error: Throwable) {
            // Could not ask. Treating that as taken is the safe way round: a needlessly
            // separate directory costs one process its WebView storage, where a wrong
            // "free" costs the activity its launch.
            false
        } finally {
            runCatching { lock?.release() }
        }
    }

    /**
     * What tells this host process apart from the other one running the same guest.
     *
     * Not `Application.getProcessName()`: by the time this runs, Bcore has renamed the
     * process to the guest's own name, so every host process running `com.google.android.gms:ui`
     * answers `com.google.android.gms:ui` and the qualifier would distinguish nothing. It was
     * measured doing exactly that — two processes, one repaired suffix, still identical.
     *
     * [WebViewProcessIsolation] read the real name in `attachBaseContext`, before the
     * rename, and kept it. The pid is the fallback: unique for certain, but new on every
     * launch, so a process that has to use it gets a fresh WebView directory each time.
     */
    private fun hostProcessQualifier(): String =
        WebViewProcessIsolation.configuredSuffix ?: "pid${Process.myPid()}"

    /** `setDataDirectorySuffix` rejects a path separator; nothing else here can appear. */
    private fun sanitize(suffix: String): String = suffix.replace(File.separatorChar, '_')
}
