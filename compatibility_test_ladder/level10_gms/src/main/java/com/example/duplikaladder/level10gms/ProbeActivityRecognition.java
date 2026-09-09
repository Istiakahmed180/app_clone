package com.example.duplikaladder.level10gms;

import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.HasApiKey;
import com.google.android.gms.location.ActivityRecognition;
import com.google.android.gms.location.ActivityRecognitionClient;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P7 — the Phase 9 cross-API discriminator.
 *
 * <p>Phase 8 left two hypotheses standing for why {@code LocationServices} returns
 * {@code DEVELOPER_ERROR} in a container:
 *
 * <ol>
 *   <li><b>H9</b> — a general containerised-caller attribution problem: Play services
 *       refuses any API whose access it must attribute to the calling package, because the
 *       calling UID it sees belongs to the host app rather than to the guest package.</li>
 *   <li><b>H10</b> — something specific to {@code play-services-location}'s own
 *       client-side per-API availability decision.</li>
 * </ol>
 *
 * <p>Those are indistinguishable from one probe, because Phase 8's only permission-gated
 * API <em>was</em> LocationServices. This probe adds a second one:
 * {@code ActivityRecognition}. It is a distinct {@code Api} with its own GMS service, gated
 * by the <b>non-location</b> {@code ACTIVITY_RECOGNITION} runtime permission, reached
 * through the identical {@code GoogleApi} framework, and needs no account, no OAuth, no API
 * key and no attestation.
 *
 * <p>The primary measurement is deliberately the <em>same</em> one Phase 8 used —
 * {@code GoogleApiAvailability.checkApiAvailability(client)} — asked of both clients in the
 * same run, on the same device, from the same process. Comparing like with like is what
 * makes this a discriminator rather than two unrelated observations:
 *
 * <ul>
 *   <li>ActivityRecognition <b>unavailable</b> too → H9 strongly supported (a second
 *       attribution-sensitive API refuses a containerised caller) → likely security
 *       boundary → stop.</li>
 *   <li>ActivityRecognition <b>available</b> while LocationServices is not → H9 cannot be
 *       the explanation, because a permission-gated GoogleApi works for the very same
 *       caller → H10 supported, fault isolated to {@code LocationServices.API}.</li>
 * </ul>
 *
 * <p>Read-only and side-effect free. {@code checkApiAvailability} needs no granted
 * permission and starts no tracking. The one call attempted beyond it,
 * {@code removeActivityUpdates} on a PendingIntent that was never registered, is a no-op
 * that exists only to obtain an end-to-end Task status and a timing figure. Nothing here
 * requests activity updates, and nothing is spoofed or bypassed.
 */
final class ProbeActivityRecognition {

    private static final long TIMEOUT_MS = 8000;

    private ProbeActivityRecognition() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P7 — cross-API discriminator (ActivityRecognition vs LocationServices)");
        StringBuilder detail = new StringBuilder();
        detail.append("API: com.google.android.gms.location.ActivityRecognition\n");
        detail.append("artifact: play-services-location:21.3.0 (already declared)\n");
        detail.append("gate: android.permission.ACTIVITY_RECOGNITION (runtime, non-location)\n");
        detail.append("credentials: no account, no OAuth, no API key, no attestation\n\n");

        // Permission and app-op state, recorded because the point of this API is that it is
        // permission-gated. Not required for checkApiAvailability.
        String permState = "n/a below API 29";
        if (Build.VERSION.SDK_INT >= 29) {
            int granted = context.checkSelfPermission("android.permission.ACTIVITY_RECOGNITION");
            permState = granted == PackageManager.PERMISSION_GRANTED ? "GRANTED" : "DENIED";
        }
        DiagLog.line(DiagLog.TAG, "ACTIVITY_RECOGNITION permission=" + permState);
        detail.append("ACTIVITY_RECOGNITION granted: ").append(permState).append('\n');

        ActivityRecognitionClient client;
        try {
            client = ActivityRecognition.getClient(context);
            DiagLog.line(DiagLog.TAG, "ActivityRecognitionClient constructed: "
                    + client.getClass().getName());
            detail.append("client constructed: ").append(client.getClass().getName()).append('\n');
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "ActivityRecognitionClient could not be constructed", e);
            detail.append("construction threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.BLOCKED,
                    "client construction threw " + e.getClass().getSimpleName(), detail);
        }

        // ---- the discriminating measurement, both APIs, same run ----
        String activityAvailability = checkApiAvailability(client, "ActivityRecognition");
        String locationAvailability =
                checkApiAvailability(LocationServices.getSettingsClient(context),
                        "LocationServices/Settings");

        detail.append('\n');
        detail.append("checkApiAvailability(ActivityRecognition) = ")
                .append(activityAvailability).append('\n');
        detail.append("checkApiAvailability(LocationServices)    = ")
                .append(locationAvailability).append('\n');

        boolean activityAvailable = AVAILABLE.equals(activityAvailability);
        boolean locationAvailable = AVAILABLE.equals(locationAvailability);

        // ---- end-to-end Task, for a status code and a timing figure ----
        long started = System.currentTimeMillis();
        String taskOutcome;
        try {
            PendingIntent unused = PendingIntent.getBroadcast(
                    context,
                    0,
                    new Intent("com.example.duplikaladder.level10gms.NEVER_REGISTERED"),
                    PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);
            Tasks.await(client.removeActivityUpdates(unused), TIMEOUT_MS, TimeUnit.MILLISECONDS);
            taskOutcome = "completed";
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            taskOutcome = cause.getClass().getSimpleName()
                    + (cause instanceof ApiException
                            ? " statusCode=" + ((ApiException) cause).getStatusCode()
                            : "")
                    + ": " + cause.getMessage();
        }
        long elapsed = System.currentTimeMillis() - started;
        DiagLog.line(DiagLog.TAG, "removeActivityUpdates outcome=" + taskOutcome
                + " elapsedMs=" + elapsed);
        detail.append("removeActivityUpdates: ").append(taskOutcome)
                .append("  (").append(elapsed).append(" ms)\n");

        // ---- the reading ----
        detail.append('\n').append("DISCRIMINATION\n");
        if (activityAvailable && !locationAvailable) {
            DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: ActivityRecognition IS available while"
                    + " LocationServices is NOT, in the same process and for the same caller."
                    + " A permission-gated GoogleApi therefore works for a containerised"
                    + " caller, so caller attribution alone cannot explain the LocationServices"
                    + " refusal. H9 weakened; H10 supported; fault isolated to"
                    + " LocationServices.API.");
            detail.append("ActivityRecognition available, LocationServices not.\n");
            detail.append("=> H9 (general containerised-caller attribution) WEAKENED.\n");
            detail.append("=> H10 (LocationServices-specific) SUPPORTED.\n");
            return finish(Verdict.PASS,
                    "permission-gated non-location GoogleApi IS available in this process",
                    detail);
        }
        if (!activityAvailable && !locationAvailable) {
            DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: neither permission-gated API is"
                    + " available. A second attribution-sensitive GoogleApi also refuses this"
                    + " caller, so H9 is strongly supported and a security boundary is likely."
                    + " Not conclusive: ActivityRecognition ships in the same artifact, so a"
                    + " library-wide cause is not excluded.");
            detail.append("Neither API available.\n");
            detail.append("=> H9 STRONGLY SUPPORTED (likely security boundary).\n");
            detail.append("=> H10 reduced likelihood, NOT eliminated (same artifact).\n");
            return finish(Verdict.FAIL,
                    "both permission-gated APIs unavailable to this caller", detail);
        }
        if (activityAvailable && locationAvailable) {
            // Expected on the host: this is the known-good control.
            detail.append("Both APIs available — the host control condition.\n");
            return finish(Verdict.PASS, "both permission-gated APIs available", detail);
        }
        DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: LocationServices available while"
                + " ActivityRecognition is not — unexpected; treat as inconclusive.");
        detail.append("LocationServices available but ActivityRecognition not — unexpected.\n");
        return finish(Verdict.PARTIAL, "inverted result; inconclusive", detail);
    }

    private static final String AVAILABLE = "available";

    /**
     * The framework's own per-API verdict. Returned as a string because the informative
     * part is which exception and status come back, not a boolean.
     */
    private static String checkApiAvailability(HasApiKey<?> client, String label) {
        try {
            Tasks.await(
                    GoogleApiAvailability.getInstance().checkApiAvailability(client),
                    TIMEOUT_MS,
                    TimeUnit.MILLISECONDS);
            DiagLog.line(DiagLog.TAG, "checkApiAvailability(" + label + ") = " + AVAILABLE);
            return AVAILABLE;
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            String answer = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            DiagLog.line(DiagLog.TAG, "checkApiAvailability(" + label + ") = " + answer);
            return answer;
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P7 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P7", "Cross-API discriminator", verdict, summary,
                detail.toString());
    }
}
