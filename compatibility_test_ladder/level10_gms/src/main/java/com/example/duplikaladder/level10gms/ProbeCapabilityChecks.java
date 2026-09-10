package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.HasApiKey;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P12 — capability checks for the two APIs that must never be exercised.
 *
 * <p>Google Sign-In and Play Integrity are both on the phase brief's minimum test list and
 * both are APIs where "test it" and "attempt it" have to be kept strictly apart. This probe
 * establishes <em>whether the API can be reached at all</em> and stops precisely there.
 *
 * <h2>Google Sign-In</h2>
 *
 * <p>{@code checkApiAvailability} on the sign-in client only asks the framework whether
 * {@code Auth.GOOGLE_SIGN_IN_API} can be connected for this caller. <b>No sign-in is
 * started, no silent sign-in, no token request, no {@code GoogleAuthUtil} call, no account
 * is read or created.</b> P5 separately observed (read-only) that there are no accounts and
 * no engine-fabricated account.
 *
 * <p>The measurement is worth making because sign-in has always been recorded as
 * UNSUPPORTED by classification rather than by evidence. If sign-in is refused by the same
 * mechanism as LocationServices and SmsRetriever, that is a stronger and more precise
 * statement than "account APIs need an identity a container cannot provide" — it says the
 * refusal happens at connection time, before authentication is even reachable, so no
 * credential question is ever posed.
 *
 * <h2>Play Integrity</h2>
 *
 * <p>Deliberately reduced to a reflective presence check. Play Integrity's purpose is to
 * attest the environment, and a virtualized caller <em>should</em> fail it — that is the
 * correct outcome and this project does not target it. Requesting a token additionally
 * requires a Google Cloud project number, which this fixture does not carry and must not:
 * a real request would put a real project's integrity verdicts on the line to measure
 * something already known.
 *
 * <p>So the probe records only whether the API surface is present on the classpath, which
 * is what "can it be invoked" honestly reduces to here, and states the rest as an untested
 * boundary rather than inferring a verdict.
 */
final class ProbeCapabilityChecks {

    /** Present only if a Play Integrity dependency is on the classpath. */
    private static final String INTEGRITY_MANAGER_FACTORY =
            "com.google.android.play.core.integrity.IntegrityManagerFactory";

    private ProbeCapabilityChecks() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P12 — capability checks (Google Sign-In, Play Integrity — never exercised)");
        StringBuilder detail = new StringBuilder();

        detail.append("GOOGLE SIGN-IN — availability only, no authentication attempted\n");
        String signIn = signInAvailability(context);
        detail.append("  checkApiAvailability(GoogleSignIn) = ").append(signIn).append('\n');
        detail.append("  signIn/silentSignIn/token request  = NOT ATTEMPTED (deliberate)\n");

        detail.append('\n').append("PLAY INTEGRITY — presence only, no token requested\n");
        boolean integrityPresent;
        try {
            Class.forName(INTEGRITY_MANAGER_FACTORY);
            integrityPresent = true;
        } catch (Throwable e) {
            integrityPresent = false;
        }
        DiagLog.line(DiagLog.TAG, "P12 PlayIntegrity apiOnClasspath=" + integrityPresent);
        detail.append("  API on classpath   = ").append(integrityPresent).append('\n');
        detail.append("  token request      = NOT ATTEMPTED and NOT TARGETED. A virtualized\n");
        detail.append("    caller should fail attestation; that is the correct outcome. A real\n");
        detail.append("    request also needs a Cloud project number this fixture does not carry.\n");
        detail.append("  verdict            = NOT TESTED (by design, not by omission)\n");

        boolean signInRefused = signIn.contains("DEVELOPER_ERROR");
        detail.append('\n').append("READING\n");
        if (signInRefused) {
            DiagLog.line(DiagLog.TAG, "P12 Google Sign-In is refused at CONNECTION time with the"
                    + " same DEVELOPER_ERROR as the other attribution-sensitive APIs — the"
                    + " refusal precedes authentication entirely.");
            detail.append("Google Sign-In is refused at connection time with the same\n");
            detail.append("DEVELOPER_ERROR as LocationServices and SmsRetriever. The container\n");
            detail.append("never reaches an authentication question, so sign-in is unsupported\n");
            detail.append("for the same reason as the others, not for a separate account reason.\n");
        } else {
            detail.append("Google Sign-In reports available for this caller (host control).\n");
            detail.append("Availability is not sign-in: nothing was authenticated.\n");
        }

        Verdict verdict = signInRefused ? Verdict.UNSUPPORTED : Verdict.PASS;
        String summary = signInRefused
                ? "sign-in refused at connection; integrity NOT TESTED by design"
                : "sign-in API available (host); integrity NOT TESTED by design";
        DiagLog.line(DiagLog.TAG, "P12 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P12", "Sign-In / Play Integrity capability", verdict, summary,
                detail.toString());
    }

    /**
     * Whether {@code Auth.GOOGLE_SIGN_IN_API} can be connected for this caller.
     *
     * <p>Built with {@code DEFAULT_SIGN_IN}, which requests only an ID and basic profile and
     * is the minimum a client can be constructed with. Constructing a client performs no
     * network call and no authentication; only {@code checkApiAvailability} is then asked.
     */
    private static String signInAvailability(Context context) {
        try {
            GoogleSignInOptions options = new GoogleSignInOptions.Builder(
                    GoogleSignInOptions.DEFAULT_SIGN_IN).build();
            GoogleSignInClient client = GoogleSignIn.getClient(context, options);
            if (!(client instanceof HasApiKey)) {
                DiagLog.line(DiagLog.TAG, "P12 checkApiAvailability(GoogleSignIn) = not askable"
                        + " (client does not implement HasApiKey)");
                return "not askable (client does not implement HasApiKey)";
            }
            Tasks.await(GoogleApiAvailability.getInstance()
                    .checkApiAvailability((HasApiKey<?>) client), 8000, TimeUnit.MILLISECONDS);
            DiagLog.line(DiagLog.TAG, "P12 checkApiAvailability(GoogleSignIn) = available");
            return "available";
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            String answer = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            DiagLog.line(DiagLog.TAG, "P12 checkApiAvailability(GoogleSignIn) = " + answer);
            return answer;
        }
    }
}
