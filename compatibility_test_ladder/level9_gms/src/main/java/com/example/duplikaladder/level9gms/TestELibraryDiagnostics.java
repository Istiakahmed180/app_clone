package com.example.duplikaladder.level9gms;

import android.content.Context;
import android.content.pm.PackageManager;
import android.content.pm.ProviderInfo;

import com.google.firebase.FirebaseApp;

import java.util.List;

/**
 * TEST E — Google/Firebase dependency diagnostics, taken apart.
 *
 * <p>"Firebase does not work" is not a usable finding, because at least four different
 * layers can produce it. This test separates them so a failure lands in exactly one:
 *
 * <ol>
 *   <li>E1 class loading — can the guest's class loader reach the library at all?</li>
 *   <li>E2 provider installation — did {@code FirebaseInitProvider}, an ordinary
 *       ContentProvider the library auto-installs, get registered and run? This is
 *       ContentProvider virtualization, not Google infrastructure.</li>
 *   <li>E3 configuration — {@code initializeApp} with no {@code google-services.json}.
 *       Returning null is the correct answer on host and guest alike; it is included as
 *       a control, so that a *different* answer inside a container is meaningful.</li>
 *   <li>E4 service discovery — can the library's own dependency, Play services, be
 *       discovered from here?</li>
 * </ol>
 *
 * <p>No {@code google-services.json} and no google-services plugin are present, so
 * nothing in this test can contact a Google backend or carry a project identity.
 */
final class TestELibraryDiagnostics {

    /**
     * Loaded by name rather than referenced, so that a library missing at runtime is
     * reported instead of crashing the process at verification time.
     */
    private static final String[] PROBED_CLASSES = {
            "com.google.android.gms.common.GoogleApiAvailability",
            "com.google.android.gms.common.ConnectionResult",
            "com.google.android.gms.common.api.GoogleApi",
            "com.google.android.gms.tasks.Tasks",
            "com.google.firebase.FirebaseApp",
            "com.google.firebase.provider.FirebaseInitProvider",
    };

    private TestELibraryDiagnostics() {
    }

    static TestResult run(Context context) {
        DiagLog.section("TEST E — Google/Firebase dependency diagnostics");
        StringBuilder detail = new StringBuilder();

        boolean classesOk = probeClassLoading(detail);
        boolean providerOk = probeInitProvider(context, detail);
        boolean initRan = probeFirebaseInit(context, detail);
        boolean discoveryOk = probeServiceDiscovery(context, detail);

        Verdict verdict;
        String summary;
        if (!classesOk) {
            verdict = Verdict.FAIL;
            summary = "E1 class loading failed — library unreachable in this process";
        } else if (!providerOk) {
            verdict = Verdict.FAIL;
            summary = "E2 FirebaseInitProvider not registered — ContentProvider layer";
        } else if (!discoveryOk) {
            verdict = Verdict.PARTIAL;
            summary = "E1/E2 fine; E4 service discovery cannot see Play services";
        } else {
            verdict = Verdict.PASS;
            summary = "library loads, provider registered, Play services discoverable"
                    + (initRan ? "" : " (E3 unconfigured, as expected)");
        }
        DiagLog.line(DiagLog.TAG, "TEST E verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("E", "Google/Firebase dependency diagnostics", verdict, summary,
                detail.toString());
    }

    private static boolean probeClassLoading(StringBuilder detail) {
        detail.append("E1 class loading\n");
        boolean allLoaded = true;
        for (String name : PROBED_CLASSES) {
            try {
                Class<?> loaded = Class.forName(name);
                detail.append("  OK   ").append(name)
                        .append("  loader=").append(loaded.getClassLoader()).append('\n');
                DiagLog.line(DiagLog.TAG, "class load OK " + name);
            } catch (Throwable e) {
                allLoaded = false;
                detail.append("  FAIL ").append(name).append("  ")
                        .append(e.getClass().getName()).append('\n');
                DiagLog.failure(DiagLog.TAG, "class load failed " + name, e);
            }
        }
        return allLoaded;
    }

    /**
     * The library's provider is looked up by authority, the same way the platform
     * installs it. Inside a container this is a direct test of provider virtualization
     * for a third-party library, independent of anything Google-specific.
     */
    private static boolean probeInitProvider(Context context, StringBuilder detail) {
        String authority = context.getPackageName() + ".firebaseinitprovider";
        detail.append("E2 provider installation, authority=").append(authority).append('\n');
        try {
            ProviderInfo info = context.getPackageManager().resolveContentProvider(authority, 0);
            if (info == null) {
                detail.append("  resolveContentProvider returned null\n");
                DiagLog.line(DiagLog.TAG, "FirebaseInitProvider NOT resolvable authority=" + authority);
                return false;
            }
            detail.append("  resolved ").append(info.packageName).append('/').append(info.name)
                    .append(" enabled=").append(info.enabled).append('\n');
            DiagLog.line(DiagLog.TAG, "FirebaseInitProvider resolved " + info.packageName + "/" + info.name);
            return true;
        } catch (RuntimeException e) {
            detail.append("  resolveContentProvider threw ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG, "resolveContentProvider threw for " + authority, e);
            return false;
        }
    }

    /**
     * Deliberately expected to find nothing. With no {@code google-services.json} the
     * library has no options to initialize from, so an empty list is the correct result
     * everywhere; it is recorded so that a container producing anything else stands out.
     */
    private static boolean probeFirebaseInit(Context context, StringBuilder detail) {
        detail.append("E3 configuration (no google-services.json is present by design)\n");
        try {
            List<FirebaseApp> existing = FirebaseApp.getApps(context);
            detail.append("  FirebaseApp.getApps size=").append(existing.size()).append('\n');
            DiagLog.line(DiagLog.TAG, "FirebaseApp.getApps size=" + existing.size());

            FirebaseApp app = FirebaseApp.initializeApp(context);
            boolean initialized = app != null;
            detail.append("  initializeApp -> ").append(initialized ? app.getName() : "null")
                    .append(initialized ? "\n" : " (expected: no configuration resource)\n");
            DiagLog.line(DiagLog.TAG, "FirebaseApp.initializeApp initialized=" + initialized);
            return initialized;
        } catch (Throwable e) {
            detail.append("  initializeApp threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            DiagLog.failure(DiagLog.TAG, "FirebaseApp.initializeApp threw", e);
            return false;
        }
    }

    private static boolean probeServiceDiscovery(Context context, StringBuilder detail) {
        detail.append("E4 service discovery\n");
        PackageManager pm = context.getPackageManager();
        try {
            pm.getPackageInfo(TestAPackageDetection.GMS, 0);
            detail.append("  Play services discoverable from the library's point of view\n");
            DiagLog.line(DiagLog.TAG, "E4 Play services discoverable");
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            detail.append("  Play services NOT discoverable: NameNotFoundException\n");
            DiagLog.failure(DiagLog.TAG, "E4 Play services not discoverable", e);
            return false;
        } catch (RuntimeException e) {
            detail.append("  Play services discovery threw ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG, "E4 discovery threw", e);
            return false;
        }
    }
}
