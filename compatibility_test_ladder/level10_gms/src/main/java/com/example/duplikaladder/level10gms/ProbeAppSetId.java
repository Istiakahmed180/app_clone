package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.appset.AppSet;
import com.google.android.gms.appset.AppSetIdClient;
import com.google.android.gms.appset.AppSetIdInfo;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P2 — a Google API reached THROUGH the GoogleApi client framework, with the same
 * "no credentials" property as P1.
 *
 * <p>This is the other half of the controlled comparison described in
 * {@link ProbeAdvertisingId}. {@code AppSet.getClient(context).getAppSetIdInfo()} needs no
 * Google account, no API key and no runtime permission — exactly like P1 — but unlike P1
 * it is a {@code GoogleApi} subclass, so the framework performs its usual connection
 * handshake and sends a {@code GetServiceRequest} that names the calling package.
 *
 * <p>Holding the credential requirement constant and varying only the client layer is what
 * makes the P1/P2 pair able to locate the boundary. Level 9's single probe could not:
 * it used the framework and needed no credentials, so a failure was consistent with either
 * explanation.
 *
 * <p>The App Set ID is scoped per developer per device and is explicitly not a permanent
 * device identifier, but it is still an identifier, so as in P1 only its presence, length
 * and scope are recorded — never the value.
 */
final class ProbeAppSetId {

    private static final long TIMEOUT_MS = 10000;

    private ProbeAppSetId() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P2 — GoogleApi framework client (AppSet ID, no credentials)");
        StringBuilder detail = new StringBuilder();
        detail.append("path: AppSetIdClient (a GoogleApi subclass) -> GoogleApiManager -> Play services\n");
        detail.append("client layer: GoogleApi framework (sends GetServiceRequest naming the caller)\n");
        detail.append("credentials: no account, no API key, no runtime permission\n");

        AppSetIdClient client;
        Task<AppSetIdInfo> task;
        try {
            client = AppSet.getClient(context);
            detail.append("AppSetIdClient constructed: ").append(client.getClass().getName()).append('\n');
            DiagLog.line(DiagLog.TAG, "AppSetIdClient constructed");
            task = client.getAppSetIdInfo();
            DiagLog.line(DiagLog.TAG, "getAppSetIdInfo task submitted");
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "AppSetIdClient could not be constructed", e);
            detail.append("construction threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.BLOCKED,
                    "client construction threw " + e.getClass().getSimpleName(), detail);
        }

        try {
            // Blocking wait on the worker thread the runner provides, so P1 and P2 are
            // measured the same way and neither can overlap the other's bind.
            AppSetIdInfo info = Tasks.await(task, TIMEOUT_MS, TimeUnit.MILLISECONDS);
            String id = info == null ? null : info.getId();
            boolean present = id != null && !id.isEmpty();
            DiagLog.line(DiagLog.TAG, "AppSet ID OK idPresent=" + present
                    + " idLength=" + (id == null ? 0 : id.length())
                    + " scope=" + (info == null ? "n/a" : String.valueOf(info.getScope())));
            detail.append("Task succeeded: Play services answered through the framework\n");
            detail.append("idPresent=").append(present)
                    .append(" idLength=").append(id == null ? 0 : id.length()).append('\n');
            detail.append("(the identifier value is deliberately not recorded)\n");
            return finish(Verdict.PASS,
                    "GoogleApi-framework call completed in the guest", detail);
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            if (cause instanceof ApiException) {
                int statusCode = ((ApiException) cause).getStatusCode();
                DiagLog.failure(DiagLog.TAG, "AppSet ID ApiException statusCode=" + statusCode, cause);
                detail.append("ApiException statusCode=").append(statusCode)
                        .append(" message=").append(cause.getMessage()).append('\n');
                return finish(Verdict.FAIL,
                        "framework call rejected by Play services (status " + statusCode + ")", detail);
            }
            DiagLog.failure(DiagLog.TAG, "AppSet ID failed", e);
            detail.append("threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.FAIL,
                    "framework call failed with " + e.getClass().getSimpleName(), detail);
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P2 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P2", "GoogleApi framework client", verdict, summary, detail.toString());
    }
}
