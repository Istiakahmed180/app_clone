package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.location.SettingsClient;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P3 — the Level 9 control, carried forward unchanged.
 *
 * <p>This is deliberately the same API Level 9 Test D used, so Level 10 can be compared
 * directly against the Level 9 evidence rather than against a re-specified test. If this
 * probe stops reproducing Level 9's {@code DEVELOPER_ERROR}, something changed in the
 * environment and the rest of Level 10's conclusions have to be re-derived; if it
 * reproduces it, the P1/P2 comparison sits on a verified-stable baseline.
 *
 * <p>Like P1 and P2 it needs no Google account, no API key and no runtime permission, and
 * it is a {@code GoogleApi} client — so it belongs to the same family as P2.
 */
final class ProbeLocationSettings {

    private static final long TIMEOUT_MS = 10000;

    private ProbeLocationSettings() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P3 — Level 9 control (SettingsClient.checkLocationSettings)");
        StringBuilder detail = new StringBuilder();
        detail.append("path: SettingsClient (a GoogleApi subclass) -> GoogleApiManager -> Play services\n");
        detail.append("client layer: GoogleApi framework\n");
        detail.append("purpose: reproduce the Level 9 Test D result before trusting P1/P2\n");

        Task<LocationSettingsResponse> task;
        try {
            SettingsClient client = LocationServices.getSettingsClient(context);
            LocationSettingsRequest request = new LocationSettingsRequest.Builder()
                    .addLocationRequest(new LocationRequest.Builder(10000).build())
                    .build();
            task = client.checkLocationSettings(request);
            DiagLog.line(DiagLog.TAG, "checkLocationSettings task submitted");
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "SettingsClient could not be constructed", e);
            detail.append("construction threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.BLOCKED,
                    "client construction threw " + e.getClass().getSimpleName(), detail);
        }

        try {
            Tasks.await(task, TIMEOUT_MS, TimeUnit.MILLISECONDS);
            DiagLog.line(DiagLog.TAG, "checkLocationSettings succeeded");
            detail.append("Task succeeded: Play services answered the API call\n");
            return finish(Verdict.PASS, "GoogleApi call completed against Play services", detail);
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            if (cause instanceof ApiException) {
                int statusCode = ((ApiException) cause).getStatusCode();
                DiagLog.failure(DiagLog.TAG,
                        "checkLocationSettings ApiException statusCode=" + statusCode, cause);
                detail.append("ApiException statusCode=").append(statusCode)
                        .append(" message=").append(cause.getMessage()).append('\n');
                // Same rule as Level 9 Test D: a documented API reply means the binder
                // round-trip completed, which is what this probe measures. Only the codes
                // that say the service was never reached count as a failure.
                if (isConnectionFailure(statusCode)) {
                    return finish(Verdict.FAIL,
                            "client never reached Play services (status " + statusCode + ")", detail);
                }
                return finish(Verdict.PASS,
                        "Play services replied (status " + statusCode + ")", detail);
            }
            DiagLog.failure(DiagLog.TAG, "checkLocationSettings failed", e);
            detail.append("threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.FAIL,
                    "call failed with " + e.getClass().getSimpleName(), detail);
        }
    }

    private static boolean isConnectionFailure(int statusCode) {
        switch (statusCode) {
            case ConnectionResult.SERVICE_MISSING:
            case ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED:
            case ConnectionResult.SERVICE_DISABLED:
            case ConnectionResult.SERVICE_INVALID:
            case ConnectionResult.API_UNAVAILABLE:
            case CommonStatusCodes.API_NOT_CONNECTED:
            case CommonStatusCodes.NETWORK_ERROR:
                return true;
            default:
                return false;
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P3 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P3", "Level 9 control (SettingsClient)", verdict, summary,
                detail.toString());
    }
}
