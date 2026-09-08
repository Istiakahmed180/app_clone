package com.example.duplikaladder.level9gms;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.LocationSettingsRequest;
import com.google.android.gms.location.LocationSettingsResponse;
import com.google.android.gms.location.SettingsClient;
import com.google.android.gms.tasks.Task;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * TEST D — an officially supported GoogleApi client, connected without authentication.
 *
 * <p>{@code SettingsClient.checkLocationSettings} was chosen because it is the rare
 * Google API that needs no Google account, no runtime permission and no API key, yet
 * still runs the complete path a real app uses: client library, GoogleApiManager,
 * binder connection to Play services, and a Task completed from the service. It reads a
 * device setting and returns; nothing is signed in and nothing is written.
 *
 * <p>A {@link ApiException} here is a real answer from Play services, so it counts as the
 * connection having worked. Only a failure to reach the service at all is a Test D
 * failure.
 */
final class TestDApiClient {

    private static final long TASK_TIMEOUT_MS = 10000;

    private TestDApiClient() {
    }

    interface Listener {
        void onFinished(TestResult result);
    }

    static void run(Context context, Listener listener) {
        DiagLog.section("TEST D — GoogleApi client connection (no authentication)");
        StringBuilder detail = new StringBuilder();
        detail.append("client: SettingsClient.checkLocationSettings — no account, no permission\n");

        AtomicBoolean settled = new AtomicBoolean(false);

        SettingsClient client;
        Task<LocationSettingsResponse> task;
        try {
            client = LocationServices.getSettingsClient(context);
            detail.append("SettingsClient constructed: ").append(client.getClass().getName()).append('\n');
            DiagLog.line(DiagLog.TAG, "SettingsClient constructed");

            LocationSettingsRequest request = new LocationSettingsRequest.Builder()
                    .addLocationRequest(new LocationRequest.Builder(10000).build())
                    .build();
            task = client.checkLocationSettings(request);
            DiagLog.line(DiagLog.TAG, "checkLocationSettings task submitted");
        } catch (Throwable e) {
            // NoClassDefFoundError included: a client library that cannot even be
            // constructed is a different failure from one that cannot connect.
            DiagLog.failure(DiagLog.TAG, "GoogleApi client could not be constructed", e);
            detail.append("construction threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            listener.onFinished(TestResult.of("D", "GoogleApi client connection", Verdict.BLOCKED,
                    "client construction threw " + e.getClass().getSimpleName(), detail.toString()));
            return;
        }

        task.addOnSuccessListener(response -> {
            if (!settled.compareAndSet(false, true)) {
                return;
            }
            detail.append("Task succeeded: Play services answered the API call\n");
            DiagLog.line(DiagLog.TAG, "checkLocationSettings succeeded");
            finish(listener, Verdict.PASS, "GoogleApi call completed against Play services", detail);
        });

        task.addOnFailureListener(error -> {
            if (!settled.compareAndSet(false, true)) {
                return;
            }
            if (error instanceof ApiException) {
                int statusCode = ((ApiException) error).getStatusCode();
                detail.append("ApiException statusCode=").append(statusCode)
                        .append(" message=").append(error.getMessage()).append('\n');
                DiagLog.failure(DiagLog.TAG, "checkLocationSettings ApiException statusCode="
                        + statusCode, error);
                // What this test measures is whether the client reached Play services, not
                // whether the device happens to satisfy the request. A documented API reply
                // -- RESOLUTION_REQUIRED because location is off, say -- means the binder
                // round-trip completed, which is the connection this test is about. Only the
                // status codes that say the service was never reached count as a failure.
                if (isConnectionFailure(statusCode)) {
                    finish(listener, Verdict.FAIL,
                            "client never reached Play services (status " + statusCode + ")", detail);
                } else {
                    finish(listener, Verdict.PASS,
                            "Play services replied (status " + statusCode + ")", detail);
                }
                return;
            }
            detail.append("Task failed with ").append(error.getClass().getName())
                    .append(": ").append(error.getMessage()).append('\n');
            DiagLog.failure(DiagLog.TAG, "checkLocationSettings failed", error);
            finish(listener, Verdict.FAIL,
                    "client call failed with " + error.getClass().getSimpleName(), detail);
        });

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            if (!settled.compareAndSet(false, true)) {
                return;
            }
            detail.append("Task never completed within ").append(TASK_TIMEOUT_MS).append(" ms\n");
            DiagLog.line(DiagLog.TAG, "checkLocationSettings timed out after " + TASK_TIMEOUT_MS + " ms");
            finish(listener, Verdict.FAIL,
                    "no Task callback within " + TASK_TIMEOUT_MS + " ms", detail);
        }, TASK_TIMEOUT_MS);
    }

    /**
     * Status codes that mean the call never got to Play services. Anything else is a
     * reply, and a reply is what proves the connection.
     */
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

    private static void finish(Listener listener, Verdict verdict, String summary,
                               StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "TEST D verdict=" + verdict + " (" + summary + ")");
        listener.onFinished(TestResult.of("D", "GoogleApi client connection", verdict, summary,
                detail.toString()));
    }
}
