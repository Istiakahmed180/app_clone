package co.tdevs.duplika.diagnostics

import android.app.NotificationManager
import android.app.job.JobScheduler
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.PermissionInfo
import android.os.Build
import android.webkit.WebView
import co.tdevs.duplika.WebViewProcessIsolation

/**
 * What Duplika can observe about the WebView subsystem.
 *
 * Genuinely observable from here:
 *  - which WebView implementation the device uses, and its version;
 *  - whether this process managed to claim its own WebView data directory, which is the
 *    failure that takes a guest down with `IllegalStateException: Using WebView from
 *    more than one process`.
 *
 * Not observable, and not claimed:
 *  - a guest's renderer crash callbacks. `WebViewClient.onRenderProcessGone` is
 *    delivered to the client of the `WebView` instance that crashed, and those
 *    instances belong to the guest app's own code inside a stub process. Reaching them
 *    would mean rewriting guest classes, which is exactly the kind of hack this project
 *    does not add for logging.
 *  - browsing data. Nothing here reads a URL, a cookie or a cache entry.
 */
class WebViewDiagnostics(private val context: Context) {

    fun run(): ProbeReport {
        val report = ProbeReport("Duplika WebView diagnostics")
        DiagnosticLogger.info(DiagSource.WEBVIEW, DiagCategory.WEBVIEW, "WebView diagnostics started")

        report.section("Process isolation")
        report.field("process", DiagnosticLogger.currentProcessName())
        report.field("dataDirectorySuffix", WebViewProcessIsolation.configuredSuffix ?: "not set")
        report.field("suffixOutcome", WebViewProcessIsolation.outcome)
        report.field(
            "suffixSupported",
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) "yes" else "n/a below API 28",
        )

        report.section("WebView implementation")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            report.probe("currentWebViewPackage") {
                val info: PackageInfo? = WebView.getCurrentWebViewPackage()
                if (info == null) {
                    "null (no WebView provider resolved)"
                } else {
                    "${info.packageName} ${info.versionName}"
                }
            }
        } else {
            report.field("currentWebViewPackage", "n/a below API 26")
        }
        report.probe("webViewProviderInstalled") {
            val candidates = listOf(
                "com.google.android.webview",
                "com.android.webview",
                "com.android.chrome",
            )
            candidates.filter { candidate ->
                runCatching { context.packageManager.getPackageInfo(candidate, 0) }.isSuccess
            }.joinToString(", ").ifEmpty { "none of the known providers is visible" }
        }

        report.section("Known limitations")
        report.field(
            "guestRendererCrashes",
            "not observable — onRenderProcessGone is delivered to the guest's own WebViewClient",
        )
        report.field("browsingData", "never collected")

        DiagnosticLogger.success(
            DiagSource.WEBVIEW,
            DiagCategory.WEBVIEW,
            "WebView diagnostics finished",
        )
        return report
    }
}

/**
 * The host's permission state, read only.
 *
 * Guests run under the host's UID, so Android checks *these* grants when a cloned app
 * touches the camera, the microphone or shared storage. That makes this list the single
 * most useful answer to "why does the clone say permission denied".
 *
 * Nothing here requests anything. A probe that raised a system dialog would change the
 * state it was measuring, and the user would be asked for a permission they never chose
 * to be asked about.
 */
class PermissionDiagnostics(private val context: Context) {

    fun run(): ProbeReport {
        val report = ProbeReport("Duplika permission diagnostics")
        DiagnosticLogger.info(
            DiagSource.PERMISSION,
            DiagCategory.PERMISSION,
            "Permission diagnostics started",
        )

        val declared = declaredPermissions()
        report.section("Summary")
        report.field("declaredPermissions", declared.size.toLong())

        val dangerous = declared.filter(::isDangerous).sorted()
        report.field("dangerousPermissions", dangerous.size.toLong())
        report.field(
            "granted",
            dangerous.count { isGranted(it) }.toLong(),
        )

        report.section("Dangerous permissions")
        if (dangerous.isEmpty()) {
            report.field("(none)", "the merged manifest declares no dangerous permissions")
        }
        dangerous.forEach { permission ->
            report.field(
                permission.substringAfterLast('.'),
                if (isGranted(permission)) "GRANTED" else "DENIED",
            )
        }

        report.section("Special access")
        report.probe("MANAGE_EXTERNAL_STORAGE (declared)") {
            declared.contains("android.permission.MANAGE_EXTERNAL_STORAGE").toString()
        }
        report.probe("All-files access (granted)") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                android.os.Environment.isExternalStorageManager().toString()
            } else {
                "n/a below API 30"
            }
        }
        report.probe("POST_NOTIFICATIONS") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                if (isGranted("android.permission.POST_NOTIFICATIONS")) "GRANTED" else "DENIED"
            } else {
                "n/a below API 33"
            }
        }

        DiagnosticLogger.success(
            DiagSource.PERMISSION,
            DiagCategory.PERMISSION,
            "Permission diagnostics finished",
            metadata = mapOf(
                "dangerous" to dangerous.size.toString(),
                "granted" to dangerous.count { isGranted(it) }.toString(),
            ),
        )
        return report
    }

    private fun declaredPermissions(): List<String> = try {
        context.packageManager
            .getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
            .requestedPermissions
            ?.toList()
            .orEmpty()
    } catch (error: Throwable) {
        DiagnosticLogger.warning(
            DiagSource.PERMISSION,
            DiagCategory.PERMISSION,
            "Could not read the host's declared permissions",
            error,
        )
        emptyList()
    }

    private fun isDangerous(permission: String): Boolean = try {
        val info = context.packageManager.getPermissionInfo(permission, 0)
        val protection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.protection
        } else {
            @Suppress("DEPRECATION")
            info.protectionLevel and PermissionInfo.PROTECTION_MASK_BASE
        }
        protection == PermissionInfo.PROTECTION_DANGEROUS
    } catch (_: Throwable) {
        // A permission this Android build does not define. Not dangerous because it is
        // not anything: it can never be granted.
        false
    }

    private fun isGranted(permission: String): Boolean =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    fun logCheck(permission: String, granted: Boolean, reason: String) {
        DiagnosticLogger.log(
            level = if (granted) DiagLevel.SUCCESS else DiagLevel.WARNING,
            source = DiagSource.PERMISSION,
            category = DiagCategory.PERMISSION,
            message = "Permission ${permission.substringAfterLast('.')} " +
                if (granted) "is granted" else "is not granted",
            metadata = mapOf("permission" to permission, "reason" to reason),
        )
    }
}

/**
 * Notification plumbing, as the host can see it.
 *
 * Channel identity is reported — a guest whose channel was never created cannot post,
 * and that is the usual cause of a silent clone. Notification *content* is never read:
 * a message body is user data, and a diagnostics report gets shared.
 */
class NotificationDiagnostics(private val context: Context) {

    fun run(): ProbeReport {
        val report = ProbeReport("Duplika notification diagnostics")
        DiagnosticLogger.info(
            DiagSource.NOTIFICATION,
            DiagCategory.NOTIFICATION,
            "Notification diagnostics started",
        )

        val manager = context.getSystemService(NotificationManager::class.java)

        report.section("Host state")
        if (manager == null) {
            report.field("notificationManager", "null (no notification service)")
            DiagnosticLogger.error(
                DiagSource.NOTIFICATION,
                DiagCategory.NOTIFICATION,
                "NotificationManager is unavailable in this process",
            )
            return report
        }

        report.probe("areNotificationsEnabled") { manager.areNotificationsEnabled().toString() }
        report.probe("importance") {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                manager.importance.toString()
            } else {
                "n/a below API 24"
            }
        }
        report.probe("currentInterruptionFilter") {
            manager.currentInterruptionFilter.toString()
        }

        report.section("Channels")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            report.field("channels", "n/a below API 26")
        } else {
            try {
                val channels = manager.notificationChannels
                report.field("channels.count", channels.size.toLong())
                channels.sortedBy { it.id }.forEach { channel ->
                    // Id, importance and blocked state only. Not the description, which
                    // an app author can put anything into.
                    report.field(
                        channel.id,
                        "importance=${channel.importance} group=${channel.group ?: "-"} " +
                            "blocked=${channel.importance == NotificationManager.IMPORTANCE_NONE}",
                    )
                }
            } catch (error: Throwable) {
                report.failure("channels", error)
            }
        }

        report.section("Known limitations")
        report.field(
            "guestNotifications",
            "a guest posts through the host UID; its channel appears above, its content is never read",
        )

        DiagnosticLogger.success(
            DiagSource.NOTIFICATION,
            DiagCategory.NOTIFICATION,
            "Notification diagnostics finished",
        )
        return report
    }
}

/**
 * JobScheduler state for this UID.
 *
 * Because guests run under the host UID, jobs a cloned app scheduled appear here too —
 * which is what makes this probe worth having: "the clone's background sync never runs"
 * becomes a question with an answer.
 */
class JobDiagnostics(private val context: Context) {

    fun run(): ProbeReport {
        val report = ProbeReport("Duplika JobScheduler diagnostics")
        DiagnosticLogger.info(DiagSource.JOBSCHEDULER, DiagCategory.JOB, "Job diagnostics started")

        val scheduler = context.getSystemService(JobScheduler::class.java)
        report.section("Scheduler")
        if (scheduler == null) {
            report.field("jobScheduler", "null (no job scheduler service)")
            DiagnosticLogger.error(
                DiagSource.JOBSCHEDULER,
                DiagCategory.JOB,
                "JobScheduler is unavailable in this process",
            )
            return report
        }

        try {
            val pending = scheduler.allPendingJobs
            report.field("pendingJobs.count", pending.size.toLong())

            report.section("Pending jobs")
            if (pending.isEmpty()) {
                report.field("(none)", "no job is currently scheduled for this UID")
            }
            pending.sortedBy { it.id }.forEach { job ->
                report.field(
                    "job#${job.id}",
                    buildString {
                        append("service=").append(job.service.className.substringAfterLast('.'))
                        append(" periodic=").append(job.isPeriodic)
                        append(" persisted=").append(job.isPersisted)
                        append(" requiresCharging=").append(job.isRequireCharging)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            append(" network=").append(job.requiredNetwork?.toString() ?: "none")
                        }
                    },
                )
            }
        } catch (error: Throwable) {
            report.failure("allPendingJobs", error)
            DiagnosticLogger.error(
                DiagSource.JOBSCHEDULER,
                DiagCategory.JOB,
                "Reading pending jobs failed",
                error,
            )
        }

        report.section("Known limitations")
        report.field(
            "jobExecution",
            "start and finish are only observable for jobs whose service Duplika hosts",
        )

        DiagnosticLogger.success(
            DiagSource.JOBSCHEDULER,
            DiagCategory.JOB,
            "Job diagnostics finished",
        )
        return report
    }
}
