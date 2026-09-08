package com.example.duplikaladder.level9gms;

import android.content.Context;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

/**
 * TEST B — what the official availability API says.
 *
 * <p>{@code isGooglePlayServicesAvailable} is the single call that decides, for a real
 * app, whether it takes its Google path or its "Play services missing" path. Its result
 * code is therefore the most transferable number Level 9 can produce: it maps directly
 * onto what any GMS-dependent app will do.
 *
 * <p>Reported only. {@code makeGooglePlayServicesAvailable} and the error-resolution
 * dialogs are deliberately not called — resolving an error would change the device state
 * and destroy the measurement.
 */
final class TestBAvailability {

    private TestBAvailability() {
    }

    static TestResult run(Context context) {
        DiagLog.section("TEST B — GoogleApiAvailability");
        StringBuilder detail = new StringBuilder();

        int code;
        try {
            GoogleApiAvailability availability = GoogleApiAvailability.getInstance();
            code = availability.isGooglePlayServicesAvailable(context);

            boolean userResolvable = availability.isUserResolvableError(code);
            String text = availability.getErrorString(code);

            detail.append("isGooglePlayServicesAvailable=").append(code)
                    .append(" (").append(name(code)).append(")\n")
                    .append("errorString=").append(text).append('\n')
                    .append("isUserResolvableError=").append(userResolvable).append('\n')
                    .append("resolution attempted: NO (reporting only)\n");

            DiagLog.line(DiagLog.TAG, "isGooglePlayServicesAvailable=" + code
                    + " name=" + name(code) + " errorString=" + text
                    + " userResolvable=" + userResolvable);
        } catch (Throwable e) {
            // Throwable, not Exception: a missing or shrunk client library surfaces as
            // NoClassDefFoundError, and that is a result worth recording rather than a
            // crash worth propagating.
            DiagLog.failure(DiagLog.TAG, "GoogleApiAvailability call failed", e);
            detail.append("threw ").append(e.getClass().getName()).append(": ")
                    .append(e.getMessage()).append('\n');
            return TestResult.of("B", "Play services availability", Verdict.BLOCKED,
                    "availability API threw " + e.getClass().getSimpleName(), detail.toString());
        }

        Verdict verdict;
        String summary;
        if (code == ConnectionResult.SUCCESS) {
            verdict = Verdict.PASS;
            summary = "SUCCESS (0) — Play services usable from this process";
        } else if (code == ConnectionResult.SERVICE_MISSING) {
            verdict = Verdict.FAIL;
            summary = "SERVICE_MISSING (1) — no Play services package found";
        } else if (code == ConnectionResult.SERVICE_INVALID) {
            verdict = Verdict.FAIL;
            summary = "SERVICE_INVALID (9) — a Play services package was found but rejected";
        } else {
            verdict = Verdict.PARTIAL;
            summary = name(code) + " (" + code + ")";
        }
        DiagLog.line(DiagLog.TAG, "TEST B verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("B", "Play services availability", verdict, summary, detail.toString());
    }

    /** The result codes worth naming; anything else is printed as its number. */
    private static String name(int code) {
        switch (code) {
            case ConnectionResult.SUCCESS: return "SUCCESS";
            case ConnectionResult.SERVICE_MISSING: return "SERVICE_MISSING";
            case ConnectionResult.SERVICE_UPDATING: return "SERVICE_UPDATING";
            case ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED: return "SERVICE_VERSION_UPDATE_REQUIRED";
            case ConnectionResult.SERVICE_DISABLED: return "SERVICE_DISABLED";
            case ConnectionResult.SERVICE_INVALID: return "SERVICE_INVALID";
            case ConnectionResult.API_UNAVAILABLE: return "API_UNAVAILABLE";
            default: return "CODE_" + code;
        }
    }
}
