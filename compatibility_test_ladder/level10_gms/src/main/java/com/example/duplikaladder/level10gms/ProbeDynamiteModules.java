package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.dynamite.DynamiteModule;

/**
 * P13 — Chimera / Dynamite module loading.
 *
 * <p>The single most load-bearing untested capability in the guest. Modern Play services
 * ships almost nothing as static manifest components: an API is a <em>Chimera module</em>
 * that Play services hands to the calling app, and the client library loads that module's
 * code <b>into the caller's own process</b> via {@link DynamiteModule}. Maps, ML Kit, the
 * security provider, Cast and Wallet all work this way.
 *
 * <p>P6 saw the shadow of this without naming it: {@code appset.service.START} resolved to
 * <em>zero</em> manifest services on the host while the API worked perfectly. That is
 * Chimera — there is no manifest component to find.
 *
 * <p>So this probe asks the question that gates a whole class of Google SDKs: can a guest
 * ask Play services for a module's version, and can it actually load one? It matters
 * because it is independent of the caller-identity boundary. Module loading is about code
 * distribution, not about attributing an operation to a package, so there is no reason it
 * <em>should</em> be refused — but "no reason it should fail" is exactly the kind of claim
 * this project requires evidence for.
 *
 * <p>Three measurements per module, which fail differently and are worth separating:
 *
 * <ol>
 *   <li>{@code getLocalVersion} — the copy compiled into this APK. Purely local; a
 *       non-zero answer here in a guest proves nothing about Play services and is included
 *       as the control that shows the call itself works.</li>
 *   <li>{@code getRemoteVersion} — Play services' copy. This is a real query against the
 *       host GMS installation and is the first point that can differ host vs guest.</li>
 *   <li>{@code load(PREFER_REMOTE)} — actually pulls the module and gets a
 *       {@code Context} for it. The only result that proves end-to-end capability, because
 *       a version number can be answered from metadata while the load still fails.</li>
 * </ol>
 *
 * <p><b>Read-only.</b> Loading a module obtains a class loader and a context; this probe
 * calls nothing inside the module, requests no data, and touches no account, key or
 * credential.
 */
final class ProbeDynamiteModules {

    /**
     * Modules chosen because none of them needs an account, an API key or a permission,
     * and because each backs a different real SDK — so a partial result says which SDK
     * families are affected rather than just "Chimera is broken".
     */
    private static final String[][] MODULES = {
            { "Security provider (ProviderInstaller / Conscrypt)",
              "com.google.android.gms.providerinstaller.dynamite" },
            { "Maps SDK renderer", "com.google.android.gms.maps_dynamite" },
            { "ML Kit barcode scanning", "com.google.mlkit.dynamite.barcode" },
            { "Cast framework", "com.google.android.gms.cast.framework.dynamite" },
    };

    private ProbeDynamiteModules() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P13 — Chimera/Dynamite module loading (gates Maps, ML Kit, security provider)");
        StringBuilder detail = new StringBuilder();

        int remoteFound = 0;
        int loaded = 0;

        for (String[] entry : MODULES) {
            String label = entry[0];
            String moduleId = entry[1];

            String local = versionOf(context, moduleId, false);
            String remote = versionOf(context, moduleId, true);
            String loadResult = load(context, moduleId);

            if (isPositiveVersion(remote)) {
                remoteFound++;
            }
            if (loadResult.startsWith("loaded")) {
                loaded++;
            }

            DiagLog.line(DiagLog.TAG, "P13 " + moduleId
                    + " local=" + local + " remote=" + remote + " load=" + loadResult);
            detail.append(label).append('\n')
                    .append("  moduleId      = ").append(moduleId).append('\n')
                    .append("  localVersion  = ").append(local).append('\n')
                    .append("  remoteVersion = ").append(remote).append('\n')
                    .append("  load          = ").append(loadResult).append('\n');
        }

        detail.append('\n').append("READING\n");
        detail.append("modules with a remote version: ").append(remoteFound)
                .append(" of ").append(MODULES.length).append('\n');
        detail.append("modules successfully loaded  : ").append(loaded)
                .append(" of ").append(MODULES.length).append('\n');

        Verdict verdict;
        String summary;
        if (loaded > 0) {
            DiagLog.line(DiagLog.TAG, "P13 Chimera module loading WORKS for this caller —"
                    + " Play services served module code into the process. This is"
                    + " independent of the caller-identity boundary.");
            detail.append("Chimera module loading works: Play services served module code into\n");
            detail.append("this process. Module distribution is not caller-attributed, so it is\n");
            detail.append("unaffected by the identity boundary that blocks the caller-scoped APIs.\n");
            verdict = Verdict.PASS;
            summary = "Chimera module loading works (" + loaded + "/" + MODULES.length + " loaded)";
        } else if (remoteFound > 0) {
            detail.append("Remote versions are visible but no module loaded. Recorded as PARTIAL;\n");
            detail.append("the version query and the load are different capabilities.\n");
            verdict = Verdict.PARTIAL;
            summary = "remote versions visible but no module loaded";
        } else {
            verdict = Verdict.FAIL;
            summary = "no Chimera module reachable";
        }

        DiagLog.line(DiagLog.TAG, "P13 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P13", "Chimera/Dynamite modules", verdict, summary, detail.toString());
    }

    private static String versionOf(Context context, String moduleId, boolean remote) {
        try {
            int version = remote
                    ? DynamiteModule.getRemoteVersion(context, moduleId)
                    : DynamiteModule.getLocalVersion(context, moduleId);
            return String.valueOf(version);
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    /**
     * Loads a module with {@code PREFER_REMOTE} — the policy the real SDKs use, which takes
     * Play services' copy when it is newer than the one compiled into the app.
     */
    private static String load(Context context, String moduleId) {
        try {
            DynamiteModule module =
                    DynamiteModule.load(context, DynamiteModule.PREFER_REMOTE, moduleId);
            Context moduleContext = module.getModuleContext();
            return "loaded" + (moduleContext == null
                    ? " (null module context)"
                    : " moduleContext=" + moduleContext.getClass().getSimpleName());
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    private static boolean isPositiveVersion(String value) {
        try {
            return Integer.parseInt(value.trim()) > 0;
        } catch (NumberFormatException e) {
            return false;
        }
    }
}
