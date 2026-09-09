package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;

import com.google.android.gms.common.api.HasApiKey;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Tasks;

import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * P6 — why does one GoogleApi client work and another not?
 *
 * <p>Added after the first Level 10 run produced a result that ruled out the explanation
 * Level 9 had settled on. In a guest: P1 (direct AIDL) passed, P2 (AppSet — a
 * {@code GoogleApi} client) passed, and P3 (LocationServices — also a {@code GoogleApi}
 * client) failed with {@code DEVELOPER_ERROR}. So the framework itself is not the
 * boundary, and neither is caller-identity validation by Play services: AppSet went
 * through the identical framework, was bound by Play services and answered.
 *
 * <p>The timing narrowed it further. AppSet bound and returned in ~100 ms and its bind is
 * visible in Play services' own broker log. LocationServices failed in ~20 ms and produced
 * <em>no bind at all</em> — so its {@code DEVELOPER_ERROR} is decided locally, inside the
 * client library, before any IPC.
 *
 * <p>This probe measures the inputs such a local decision can be made from, and compares
 * the two APIs side by side:
 *
 * <ol>
 *   <li>{@code GoogleApiAvailability.checkApiAvailability(client)} for each client — the
 *       framework's own per-API availability answer;</li>
 *   <li>{@code queryIntentServices} for each API's service action — if the guest cannot
 *       resolve the component the client needs, the client has grounds to declare the API
 *       unavailable without connecting;</li>
 *   <li>the number of services the guest can see declared by the Play services package,
 *       which is what {@code queryIntentServices} is resolving against.</li>
 * </ol>
 *
 * <p>Diagnosis only. Nothing is modified, nothing is spoofed, and the probe deliberately
 * draws no conclusion it has not measured — if the two APIs differ on exactly one of these
 * inputs, that input is the lead; if they differ on none, the decision is made from
 * something this probe cannot see and that is reported as such.
 */
final class ProbeApiFeature {

    /**
     * Service actions the client libraries actually bind.
     *
     * Corrected in Phase 8. The first version of this list guessed
     * {@code com.google.android.gms.location.service.START} and friends, which returned
     * zero matches <em>on the host as well</em> while LocationServices worked there -- so
     * they were simply the wrong names and the arm measured nothing. These are the real
     * ones: LocationServices binds the legacy
     * {@code com.google.android.location.internal.GoogleLocationManagerService.START}
     * action, and the two known-good controls come from the Level 9 Test C evidence, which
     * observed them resolving inside a guest.
     */
    private static final String[][] ACTIONS = {
            { "LocationServices (P3, fails) - REAL action",
              "com.google.android.location.internal.GoogleLocationManagerService.START" },
            { "AppSet (P2, works)", "com.google.android.gms.appset.service.START" },
            { "Auth sign-in (Level 9 control, resolved in guest)",
              "com.google.android.gms.auth.api.signin.service.START" },
            { "GMS common (Level 9 control, resolved in guest)",
              "com.google.android.gms.common.service.START" },
    };

    private ProbeApiFeature() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P6 — per-API availability and service resolution (why P2 works and P3 does not)");
        StringBuilder detail = new StringBuilder();
        PackageManager pm = context.getPackageManager();

        // (3) How much of Play services' component surface the guest can see at all.
        int declaredServices = -1;
        try {
            PackageInfo gms = pm.getPackageInfo("com.google.android.gms",
                    PackageManager.GET_SERVICES);
            declaredServices = gms.services == null ? 0 : gms.services.length;
            DiagLog.line(DiagLog.TAG_PACKAGE, "GMS declared services visible to guest="
                    + declaredServices);
            detail.append("GMS declared services visible: ").append(declaredServices).append('\n');
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG_PACKAGE, "GET_SERVICES on GMS failed", e);
            detail.append("GET_SERVICES on GMS threw ").append(e.getClass().getSimpleName()).append('\n');
        }

        // (2) Can each API's service action be resolved from inside the guest?
        detail.append('\n');
        boolean appSetResolves = false;
        boolean locationResolves = false;
        for (String[] entry : ACTIONS) {
            String label = entry[0];
            String action = entry[1];
            int matches = 0;
            String resolved = "none";
            try {
                Intent intent = new Intent(action).setPackage("com.google.android.gms");
                List<ResolveInfo> found = pm.queryIntentServices(intent, 0);
                matches = found == null ? 0 : found.size();
                if (matches > 0 && found.get(0).serviceInfo != null) {
                    resolved = found.get(0).serviceInfo.name;
                }
            } catch (Throwable e) {
                resolved = "threw " + e.getClass().getSimpleName();
            }
            if (action.contains(".appset.") && matches > 0) {
                appSetResolves = true;
            }
            if (action.toLowerCase(java.util.Locale.US).contains("location") && matches > 0) {
                locationResolves = true;
            }
            DiagLog.line(DiagLog.TAG_INTENT, "queryIntentServices action=" + action
                    + " matches=" + matches + " component=" + resolved);
            detail.append(label).append("\n  action=").append(action)
                    .append("\n  matches=").append(matches)
                    .append("  component=").append(resolved).append('\n');
        }

        // (1) The framework's own per-API availability verdict.
        //
        // Only asked for LocationServices. checkApiAvailability takes a HasApiKey, and
        // AppSetIdClient does not implement it in play-services-appset 16.0.2 -- so the
        // comparison cannot be made symmetric here, and inventing a symmetric-looking
        // answer would be worse than recording the asymmetry.
        detail.append('\n');
        String locationAvailability = checkApiAvailability(context,
                LocationServices.getSettingsClient(context), "LocationServices/Settings");
        detail.append("checkApiAvailability(LocationServices) = ").append(locationAvailability)
                .append('\n');
        detail.append("checkApiAvailability(AppSet) = not askable ")
                .append("(AppSetIdClient does not implement HasApiKey in this version)\n");

        detail.append('\n');
        detail.append("READING\n");
        detail.append("AppSet service action resolves: ").append(appSetResolves).append('\n');
        detail.append("Location service action resolves: ").append(locationResolves).append('\n');

        if (appSetResolves && !locationResolves) {
            DiagLog.line(DiagLog.TAG, "LEAD: the AppSet service action resolves in the guest and"
                    + " the LocationServices one does not — the client can decide the API is"
                    + " unavailable without connecting, which matches the ~20 ms no-bind failure.");
            detail.append("LEAD: component resolution differs on exactly the API that fails.\n");
            return finish(Verdict.PARTIAL,
                    "location service action does not resolve in the guest; AppSet's does",
                    detail);
        }
        if (appSetResolves && locationResolves) {
            DiagLog.line(DiagLog.TAG, "Both service actions resolve, so component visibility is"
                    + " NOT the difference; the client's local decision comes from something"
                    + " this probe does not observe (per-API Feature/module metadata).");
            detail.append("Both resolve — component visibility is not the difference. The\n");
            detail.append("remaining candidate is per-API Feature/Chimera module metadata,\n");
            detail.append("which this probe cannot read. Reported as unresolved, not guessed.\n");
            return finish(Verdict.PARTIAL,
                    "both actions resolve; cause is per-API metadata this probe cannot read",
                    detail);
        }
        return finish(Verdict.PARTIAL, "inconclusive component resolution pattern", detail);
    }

    /**
     * The framework's own answer for one API. Reported as a string because the useful
     * information is which exception or status code comes back, not a boolean.
     */
    private static String checkApiAvailability(Context context, HasApiKey<?> client, String label) {
        try {
            com.google.android.gms.common.GoogleApiAvailability availability =
                    com.google.android.gms.common.GoogleApiAvailability.getInstance();
            Tasks.await(availability.checkApiAvailability(client), 8000, TimeUnit.MILLISECONDS);
            DiagLog.line(DiagLog.TAG, "checkApiAvailability(" + label + ") = available");
            return "available";
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            String answer = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            DiagLog.line(DiagLog.TAG, "checkApiAvailability(" + label + ") = " + answer);
            return answer;
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P6 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P6", "Per-API availability & resolution", verdict, summary,
                detail.toString());
    }
}
