package co.tdevs.duplika.native

import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import co.tdevs.duplika.DuplikaApplication
import co.tdevs.duplika.native.gms.MicroGCheckinSeeder
import co.tdevs.duplika.native.gms.MicroGProvider
import java.util.concurrent.TimeUnit

/**
 * Reconnects microG's push receive channel while Duplika is in the background.
 *
 * A container's microG only holds its MCS connection to `mtalk.google.com` while its process
 * lives, and on aggressive OEM builds that process is killed (measured on an OnePlus CPH2605:
 * `exited due to signal 9`). A foreground clone re-opens the channel on launch, but a closed
 * clone cannot — so this worker wakes the same service every ~15 minutes. FCM stores
 * undelivered messages for the app (typically up to four weeks), so they arrive in a batch at
 * the next reconnect instead of instantly.
 *
 * Scope, deliberately narrow: it starts a service in containers that already have a virtual
 * user, does nothing when there are none, and touches no identity, permission or container
 * state. It exists because the alternative — holding a permanent socket — is what the
 * platform's background restrictions (and aggressive OEM killers) exist to prevent.
 *
 * Stated plainly, because it is the kind of thing that should not be discovered by
 * reading the code: this is background persistence. It is bounded to a periodic
 * reconnect, and it is the price of push in a container on these devices.
 */
class ClonePushRefreshWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {

    override fun doWork(): Result {
        // The mapping now refuses to answer rather than guessing when its storage is
        // unreadable, which is right for the clone lifecycle but must not take a periodic
        // background refresh down with it: no mapping simply means nothing to reconnect.
        val userIds = runCatching {
            VirtualProfileManager(applicationContext).allMappings().values
        }.getOrElse { error ->
            Slog.e(Slog.LAUNCH, "Background push refresh skipped: ${error.message}")
            return Result.success()
        }
        if (userIds.isEmpty()) {
            // Nothing cloned yet: no work, no wake-up cost beyond this check.
            return Result.success()
        }

        userIds.forEach { userId ->
            val started = DuplikaApplication.engine.startContainerService(
                packageName = MicroGCheckinSeeder.GMS_PACKAGE,
                serviceClassName = MicroGProvider.MCS_SERVICE,
                virtualUserId = userId,
                requireForeground = false,
                action = MicroGProvider.MCS_CONNECT_ACTION,
            )
            Slog.i(
                Slog.LAUNCH,
                "Background push refresh: user $userId → $started",
            )
        }
        return Result.success()
    }

    companion object {
        private const val NAME = "clone_push_refresh"

        /** Idempotent; safe to call from every app start. */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<ClonePushRefreshWorker>(
                15,
                TimeUnit.MINUTES,
            )
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build(),
                )
                .build()
            runCatching {
                WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                    NAME,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request,
                )
            }.onFailure {
                Slog.w(Slog.LAUNCH, "Could not schedule the push refresh worker: ${it.message}")
            }
        }
    }
}
