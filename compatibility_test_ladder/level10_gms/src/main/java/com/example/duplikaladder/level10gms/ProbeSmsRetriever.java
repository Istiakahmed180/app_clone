package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.auth.api.phone.SmsRetrieverClient;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.HasApiKey;
import com.google.android.gms.location.ActivityRecognition;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P8 — the cross-artifact discriminator, and the last one in this line of investigation.
 *
 * <p>Phases 8 and 9 both ended in a guest {@code DEVELOPER_ERROR}, but both failing APIs
 * ({@code LocationServices}, {@code ActivityRecognition}) ship in
 * {@code play-services-location:21.3.0}. Two readings fit that data equally well:
 *
 * <ul>
 *   <li><b>H9</b> — any GoogleApi whose access must be attributed to the calling package is
 *       refused for a containerised caller;</li>
 *   <li><b>H10</b> — something specific to {@code play-services-location}.</li>
 * </ul>
 *
 * <p>{@code SmsRetrieverClient} separates the artifact from the attribution property: a
 * different artifact ({@code play-services-auth-api-phone:18.0.2}, already on the compile
 * and runtime classpath — nothing was added), a different API namespace, a different GMS
 * service, and still a {@code GoogleApi} subclass so the client layer is held constant.
 *
 * <p>All three availability checks are made in this one probe, in the same process and the
 * same run, so the comparison is symmetric rather than assembled from separate sessions.
 *
 * <h2>Credentials: none</h2>
 *
 * No Google account, no OAuth, no API key, no attestation, and — unlike the Phase 9 API —
 * no runtime permission either.
 *
 * <h2>Interpretation caveat, recorded in code because it constrains the conclusion</h2>
 *
 * {@code SmsRetriever} is <b>caller-signature-scoped, not permission-gated</b>. So a guest
 * <em>failure</em> cleanly eliminates the artifact confound and confirms H9. A guest
 * <em>pass</em> does not symmetrically confirm H10: it would also fit "APIs needing
 * runtime-permission attribution are refused, APIs needing only signature scoping are
 * served", which is a refinement this probe cannot exclude. The verdict text says which of
 * those two situations was observed rather than asserting H10.
 *
 * <h2>Side effects</h2>
 *
 * The primary measurement is {@code checkApiAvailability}, which is read-only. The optional
 * end-to-end call, {@code startSmsRetriever()}, registers a self-expiring 5-minute listener
 * scoped to this app's own signature. It sends no SMS, reads no SMS, needs no incoming
 * message to return, and requires no permission. No message content is ever touched, and
 * nothing is recorded but the Task's status and elapsed time.
 */
final class ProbeSmsRetriever {

    private static final long TIMEOUT_MS = 8000;
    private static final String AVAILABLE = "available";

    private ProbeSmsRetriever() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P8 — cross-artifact discriminator (SmsRetriever vs location APIs)");
        StringBuilder detail = new StringBuilder();
        detail.append("API: com.google.android.gms.auth.api.phone.SmsRetrieverClient\n");
        detail.append("artifact: play-services-auth-api-phone:18.0.2 (transitive, already present)\n");
        detail.append("GoogleApi: extends GoogleApi<Api.ApiOptions.NoOptions>\n");
        detail.append("gate: caller SIGNATURE scoping — no runtime permission at all\n");
        detail.append("credentials: no account, no OAuth, no API key, no attestation\n\n");

        SmsRetrieverClient client;
        try {
            client = SmsRetriever.getClient(context);
            DiagLog.line(DiagLog.TAG, "SmsRetrieverClient constructed: " + client.getClass().getName());
            detail.append("client constructed: ").append(client.getClass().getName()).append('\n');
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "SmsRetrieverClient could not be constructed", e);
            detail.append("construction threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.BLOCKED,
                    "client construction threw " + e.getClass().getSimpleName(), detail);
        }

        // ---- the three availability checks, one run, same process ----
        String smsAvailability = checkApiAvailability(client, "SmsRetriever");
        String activityAvailability = checkApiAvailability(
                ActivityRecognition.getClient(context), "ActivityRecognition");
        String locationAvailability = checkApiAvailability(
                LocationServices.getSettingsClient(context), "LocationServices/Settings");

        detail.append('\n');
        detail.append("checkApiAvailability(SmsRetriever  [auth-api-phone]) = ")
                .append(smsAvailability).append('\n');
        detail.append("checkApiAvailability(ActivityRecog [location])       = ")
                .append(activityAvailability).append('\n');
        detail.append("checkApiAvailability(LocationSvcs  [location])       = ")
                .append(locationAvailability).append('\n');

        boolean smsAvailable = AVAILABLE.equals(smsAvailability);
        boolean activityAvailable = AVAILABLE.equals(activityAvailability);
        boolean locationAvailable = AVAILABLE.equals(locationAvailability);

        // ---- end-to-end Task, for a status and a timing figure ----
        long started = System.currentTimeMillis();
        String taskOutcome;
        try {
            Tasks.await(client.startSmsRetriever(), TIMEOUT_MS, TimeUnit.MILLISECONDS);
            taskOutcome = "completed (self-expiring listener registered; no SMS read)";
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            taskOutcome = cause.getClass().getSimpleName()
                    + (cause instanceof ApiException
                            ? " statusCode=" + ((ApiException) cause).getStatusCode()
                            : "")
                    + ": " + cause.getMessage();
        }
        long elapsed = System.currentTimeMillis() - started;
        DiagLog.line(DiagLog.TAG, "startSmsRetriever outcome=" + taskOutcome
                + " elapsedMs=" + elapsed);
        detail.append("startSmsRetriever: ").append(taskOutcome)
                .append("  (").append(elapsed).append(" ms)\n");

        // ---- the reading ----
        boolean locationFamilyFails = !activityAvailable && !locationAvailable;
        detail.append('\n').append("DISCRIMINATION\n");

        if (!smsAvailable && locationFamilyFails) {
            DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: SmsRetriever is ALSO refused, and it"
                    + " lives in a different artifact. The play-services-location confound is"
                    + " eliminated: attribution-sensitive GoogleApis are refused for a"
                    + " containerised caller regardless of artifact. H9 CONFIRMED;"
                    + " H10 REJECTED as the primary explanation.");
            detail.append("SmsRetriever refused too, from a DIFFERENT artifact.\n");
            detail.append("=> artifact confound ELIMINATED.\n");
            detail.append("=> H9 CONFIRMED. H10 REJECTED as primary explanation.\n");
            detail.append("=> classify: UNSUPPORTED / SECURITY-BOUNDARY. Do not bypass.\n");
            return finish(Verdict.UNSUPPORTED,
                    "cross-artifact attribution-sensitive API also refused — H9 confirmed",
                    detail);
        }
        if (smsAvailable && locationFamilyFails) {
            DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: SmsRetriever IS available from a"
                    + " different artifact while both play-services-location APIs are refused."
                    + " H9 as stated is weakened. NOTE: SmsRetriever is signature-scoped, not"
                    + " permission-gated, so this equally fits a refinement -- permission-"
                    + " attributed APIs refused, signature-scoped APIs served -- which this"
                    + " probe cannot exclude. H10 is therefore supported but NOT established.");
            detail.append("SmsRetriever available; both location-artifact APIs refused.\n");
            detail.append("=> H9 as stated WEAKENED.\n");
            detail.append("=> H10 supported but NOT established: SmsRetriever is signature-\n");
            detail.append("   scoped, not permission-gated, so 'permission-attributed APIs\n");
            detail.append("   are refused' fits equally well and is not excluded here.\n");
            return finish(Verdict.PARTIAL,
                    "cross-artifact API available; discriminates artifact but not attribution kind",
                    detail);
        }
        if (smsAvailable && activityAvailable && locationAvailable) {
            // Expected on the host: the known-good control.
            detail.append("All three APIs available — the host control condition.\n");
            return finish(Verdict.PASS, "all three APIs available (host control)", detail);
        }
        DiagLog.line(DiagLog.TAG, "DISCRIMINATOR: mixed pattern; treat as inconclusive.");
        detail.append("Mixed pattern — inconclusive; see the three values above.\n");
        return finish(Verdict.PARTIAL, "mixed availability pattern; inconclusive", detail);
    }

    /**
     * The framework's own per-API verdict. Returned as a string because the informative part
     * is which exception and status come back, not a boolean.
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
        DiagLog.line(DiagLog.TAG, "P8 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P8", "Cross-artifact discriminator", verdict, summary,
                detail.toString());
    }
}
