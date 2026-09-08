package co.tdevs.duplika.diagnostics

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import java.io.File

/**
 * The storage probe, run only when a developer asks for it.
 *
 * On demand rather than continuously, and that is a design decision, not laziness.
 * Duplika's storage behaviour is a per-launch question — a guest's `getExternalFilesDir`
 * resolves differently inside a container than outside one — but instrumenting every
 * filesystem call would produce thousands of events per second during a media scan and
 * bury everything else.
 *
 * What it does:
 *  - reads the state of external storage and the paths the platform hands this process;
 *  - checks existence, read and write on each;
 *  - reports the storage-related permission and app-op state it can see.
 *
 * What it deliberately does not do:
 *  - request `MANAGE_EXTERNAL_STORAGE`, or any permission at all. A probe that prompted
 *    would change the thing it is measuring, and All-files access is granted only from
 *    Settings by the user;
 *  - write anywhere outside directories Duplika owns. The write test runs in
 *    `filesDir`, `cacheDir`, `getExternalFilesDir`, `getExternalCacheDir` and
 *    `getExternalMediaDirs` — all app-scoped — using a file it deletes again;
 *  - touch shared storage, MediaStore or another app's data.
 */
class StorageDiagnostics(private val context: Context) {

    private companion object {
        const val PROBE_FILE = ".duplika-diagnostics-write-test"

        val STORAGE_PERMISSIONS = listOf(
            "android.permission.READ_EXTERNAL_STORAGE",
            "android.permission.WRITE_EXTERNAL_STORAGE",
            "android.permission.MANAGE_EXTERNAL_STORAGE",
            "android.permission.READ_MEDIA_AUDIO",
            "android.permission.READ_MEDIA_VIDEO",
            "android.permission.READ_MEDIA_IMAGES",
            "android.permission.READ_MEDIA_VISUAL_USER_SELECTED",
        )
    }

    fun run(): ProbeReport {
        val report = ProbeReport("Duplika storage diagnostics")

        DiagnosticLogger.info(
            DiagSource.STORAGE,
            DiagCategory.STORAGE,
            "Storage diagnostics started",
        )

        environment(report)
        appDirectories(report)
        mediaDirectories(report)
        volumes(report)
        permissions(report)

        DiagnosticLogger.success(
            DiagSource.STORAGE,
            DiagCategory.STORAGE,
            "Storage diagnostics finished",
        )
        return report
    }

    private fun environment(report: ProbeReport) {
        report.section("Environment")
        report.probe("externalStorageState") { Environment.getExternalStorageState() }
        report.probe("externalStorageEmulated") {
            Environment.isExternalStorageEmulated().toString()
        }
        report.probe("externalStorageRemovable") {
            Environment.isExternalStorageRemovable().toString()
        }
        report.probe("externalStorageDirectory") {
            DiagRedactor.sanitizePath(Environment.getExternalStorageDirectory()?.absolutePath)
        }
        report.probe("isExternalStorageManager") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Environment.isExternalStorageManager().toString()
            } else {
                "n/a below API 30"
            }
        }

        val state = runCatching { Environment.getExternalStorageState() }.getOrNull()
        if (state != null && state != Environment.MEDIA_MOUNTED) {
            // Not an error on its own — a device with no external volume is a valid
            // device — but it is the first thing to check when a guest cannot find its
            // media, so it is worth a warning rather than a buried INFO row.
            DiagnosticLogger.warning(
                DiagSource.STORAGE,
                DiagCategory.STORAGE,
                "External storage is not mounted (state=$state)",
            )
        }
    }

    private fun appDirectories(report: ProbeReport) {
        report.section("Application directories")
        describe(report, "filesDir", runCatching { context.filesDir }.getOrNull(), writable = true)
        describe(report, "cacheDir", runCatching { context.cacheDir }.getOrNull(), writable = true)
        describe(
            report,
            "noBackupFilesDir",
            runCatching { context.noBackupFilesDir }.getOrNull(),
            writable = false,
        )
        describe(
            report,
            "externalFilesDir",
            runCatching { context.getExternalFilesDir(null) }.getOrNull(),
            writable = true,
        )
        describe(
            report,
            "externalCacheDir",
            runCatching { context.externalCacheDir }.getOrNull(),
            writable = true,
        )

        val statFsTarget = runCatching { context.filesDir }.getOrNull()
        if (statFsTarget != null) {
            report.probe("internal.freeBytes") { freeBytes(statFsTarget).toString() }
            report.probe("internal.totalBytes") { totalBytes(statFsTarget).toString() }
        }
    }

    private fun mediaDirectories(report: ProbeReport) {
        report.section("Multi-volume directories")
        try {
            val files = context.getExternalFilesDirs(null)
            report.field("externalFilesDirs.count", (files?.size ?: 0).toLong())
            files?.forEachIndexed { index, dir ->
                describe(report, "externalFilesDirs[$index]", dir, writable = true)
            }
        } catch (error: Throwable) {
            report.failure("externalFilesDirs", error)
            DiagnosticLogger.error(
                DiagSource.STORAGE,
                DiagCategory.STORAGE,
                "getExternalFilesDirs failed",
                error,
            )
        }

        try {
            val media = context.externalMediaDirs
            report.field("externalMediaDirs.count", (media?.size ?: 0).toLong())
            media?.forEachIndexed { index, dir ->
                describe(report, "externalMediaDirs[$index]", dir, writable = true)
            }
        } catch (error: Throwable) {
            report.failure("externalMediaDirs", error)
            DiagnosticLogger.error(
                DiagSource.STORAGE,
                DiagCategory.STORAGE,
                "externalMediaDirs failed",
                error,
            )
        }
    }

    private fun volumes(report: ProbeReport) {
        report.section("Storage volumes")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            report.field("storageVolumes", "n/a below API 24")
            return
        }
        try {
            val manager = context.getSystemService(StorageManager::class.java)
            val volumes = manager?.storageVolumes.orEmpty()
            report.field("storageVolumes.count", volumes.size.toLong())
            volumes.forEachIndexed { index, volume ->
                // Description only. The volume's own directory is not opened: a probe has
                // no business reading a removable card's contents.
                report.field(
                    "storageVolumes[$index]",
                    "primary=${volume.isPrimary} removable=${volume.isRemovable} " +
                        "emulated=${volume.isEmulated} state=${volume.state}",
                )
            }
        } catch (error: Throwable) {
            report.failure("storageVolumes", error)
        }
    }

    private fun permissions(report: ProbeReport) {
        report.section("Storage permissions (host)")
        // Guests run under the host's UID, so these are the grants that actually decide
        // what a cloned media app can reach.
        STORAGE_PERMISSIONS.forEach { permission ->
            report.probe(permission.substringAfterLast('.')) {
                when (context.checkSelfPermission(permission)) {
                    PackageManager.PERMISSION_GRANTED -> "GRANTED"
                    else -> "DENIED"
                }
            }
        }
    }

    /**
     * Reports one directory: where it is, whether it exists, and what this process can
     * actually do with it.
     *
     * `canWrite()` lies often enough on scoped-storage paths to be worth confirming with
     * a real create-and-delete, which is why [writable] directories get a probe file.
     */
    private fun describe(report: ProbeReport, label: String, directory: File?, writable: Boolean) {
        if (directory == null) {
            report.field(label, "null (the platform returned no path)")
            DiagnosticLogger.warning(
                DiagSource.STORAGE,
                DiagCategory.STORAGE,
                "$label is unavailable in process ${DiagnosticLogger.currentProcessName()}",
            )
            return
        }

        val details = StringBuilder(DiagRedactor.sanitizePath(directory.absolutePath))
        try {
            details.append("  exists=").append(directory.exists())
            details.append(" canRead=").append(directory.canRead())
            details.append(" canWrite=").append(directory.canWrite())
        } catch (error: Throwable) {
            details.append("  stat=EXCEPTION ").append(error.javaClass.simpleName)
        }

        if (writable) {
            details.append(" writeTest=").append(writeTest(label, directory))
        }
        report.field(label, details.toString())
    }

    private fun writeTest(label: String, directory: File): String {
        return try {
            if (!directory.exists() && !directory.mkdirs()) {
                return "FAILED (directory could not be created)"
            }
            val probe = File(directory, PROBE_FILE)
            probe.writeText("duplika-diagnostics")
            val readBack = probe.readText()
            val deleted = probe.delete()
            if (readBack != "duplika-diagnostics") {
                DiagnosticLogger.error(
                    DiagSource.STORAGE,
                    DiagCategory.STORAGE,
                    "Write test on $label wrote data that did not read back",
                )
                "FAILED (read-back mismatch)"
            } else {
                "OK${if (deleted) "" else " (probe file could not be deleted)"}"
            }
        } catch (error: Throwable) {
            DiagnosticLogger.error(
                DiagSource.STORAGE,
                DiagCategory.STORAGE,
                "Write test on $label failed",
                error,
                metadata = mapOf("directory" to DiagRedactor.sanitizePath(directory.absolutePath)),
            )
            "FAILED ${error.javaClass.simpleName}: ${error.message ?: "no message"}"
        }
    }

    private fun freeBytes(target: File): Long =
        StatFs(target.absolutePath).let { it.availableBlocksLong * it.blockSizeLong }

    private fun totalBytes(target: File): Long =
        StatFs(target.absolutePath).let { it.blockCountLong * it.blockSizeLong }
}
