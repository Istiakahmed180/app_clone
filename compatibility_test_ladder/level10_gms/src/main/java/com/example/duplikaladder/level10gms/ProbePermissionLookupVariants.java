package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Process;

import java.util.Arrays;
import java.util.List;

/**
 * P18 — which permission-lookup path disagrees?
 *
 * <p>P15 stage 2 fails in a guest with the Maps renderer insisting that {@code INTERNET}
 * and {@code ACCESS_NETWORK_STATE} are not declared. P17 then showed the obvious
 * explanation is wrong: {@code getPackageInfo(self, GET_PERMISSIONS)} returns all five
 * declared permissions in the guest, identically to the host.
 *
 * <p>The stack from P15 says where to look next:
 *
 * <pre>
 * com.google.maps.api.android.lib6.impl.by.a(:com.google.android.gms.dynamite_mapsdynamite@…)
 * …
 * m6.eg.onTransact(:com.google.android.gms.dynamite_mapsdynamite@…)
 * android.os.Binder.transact(Binder.java:1345)
 * com.google.android.gms.internal.maps.zza.zzc(play-services-maps@@19.0.0:2)
 * </pre>
 *
 * <p>The check runs in <b>Chimera module code loaded into this process from Play services</b>
 * (P13 confirmed that loading works), reached through a local Binder transaction. Module code
 * is not the app's code: it may hold a different {@link Context} — typically one created for
 * the {@code com.google.android.gms} package — and it may use a different lookup API. Either
 * would explain a disagreement that P17's app-side reads cannot see.
 *
 * <p>So this probe asks the same question six ways and prints the answers side by side. The
 * variant that says DENIED in the guest while the host says GRANTED is the lookup a
 * container has to satisfy, and naming it is the prerequisite for any fix.
 *
 * <p>The two {@code viaGmsContext} variants are the pointed ones: they ask through a
 * {@code Context} created for the Play services package, which is the closest this probe can
 * legitimately get to what module code holds. If those disagree with the app-side reads, the
 * defect is that a package context's PackageManager is not virtualized.
 *
 * <p><b>Read-only.</b> Every call is a permission <em>query</em> about this app's own
 * package. Nothing is granted, requested or modified, and {@code createPackageContext} with
 * no flags loads no foreign code.
 */
final class ProbePermissionLookupVariants {

    /** The two the Maps renderer demands. */
    private static final String[] PERMISSIONS = {
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
    };

    private static final String GMS = "com.google.android.gms";

    private ProbePermissionLookupVariants() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P18 — permission lookup variants (which path does the Maps module use?)");
        StringBuilder detail = new StringBuilder();

        String self = context.getPackageName();
        Context gmsContext = gmsContext(context);
        emit(detail, "gmsPackageContext",
                gmsContext == null ? "could not create" : "created");

        int disagreements = 0;

        for (String permission : PERMISSIONS) {
            detail.append('\n').append(permission).append('\n');

            String v1 = result(() -> context.checkSelfPermission(permission));
            String v2 = result(() -> context.checkCallingOrSelfPermission(permission));
            String v3 = result(() ->
                    context.checkPermission(permission, Process.myPid(), Process.myUid()));
            String v4 = result(() -> context.getPackageManager().checkPermission(permission, self));
            String v5 = declaredVia(context, self, permission);
            String v6 = gmsContext == null
                    ? "n/a (no gms context)"
                    : result(() -> gmsContext.getPackageManager().checkPermission(permission, self));
            String v7 = gmsContext == null
                    ? "n/a (no gms context)"
                    : declaredVia(gmsContext, self, permission);

            record(detail, "  1 context.checkSelfPermission           ", v1);
            record(detail, "  2 context.checkCallingOrSelfPermission  ", v2);
            record(detail, "  3 context.checkPermission(pid,uid)      ", v3);
            record(detail, "  4 appPM.checkPermission(perm,self)      ", v4);
            record(detail, "  5 appPM.getPackageInfo declared?        ", v5);
            record(detail, "  6 gmsCtxPM.checkPermission(perm,self)   ", v6);
            record(detail, "  7 gmsCtxPM.getPackageInfo declared?     ", v7);

            for (String value : new String[] { v1, v2, v3, v4, v5, v6, v7 }) {
                if (value.contains("DENIED") || value.contains("NOT DECLARED")) {
                    disagreements++;
                }
            }
        }

        detail.append('\n').append("READING\n");
        detail.append("Any variant answering DENIED / NOT DECLARED in the guest while the host\n");
        detail.append("answers GRANTED / declared is the lookup the Maps renderer uses and the\n");
        detail.append("one a container must satisfy. If every variant agrees in both columns,\n");
        detail.append("the renderer reads something this probe cannot reach and that is\n");
        detail.append("reported as unresolved rather than guessed.\n");

        Verdict verdict;
        String summary;
        if (disagreements == 0) {
            verdict = Verdict.PASS;
            summary = "all lookup variants report the permissions as present";
        } else {
            DiagLog.line(DiagLog.TAG, "P18 " + disagreements
                    + " lookup variant answer(s) report the permission as absent");
            verdict = Verdict.FAIL;
            summary = disagreements + " lookup variant answer(s) report absent";
        }

        DiagLog.line(DiagLog.TAG, "P18 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P18", "Permission lookup variants", verdict, summary,
                detail.toString());
    }

    private static Context gmsContext(Context context) {
        try {
            // No flags: metadata and resources only, no code loading.
            return context.createPackageContext(GMS, 0);
        } catch (Throwable e) {
            DiagLog.line(DiagLog.TAG, "P18 createPackageContext(" + GMS + ") threw "
                    + e.getClass().getSimpleName() + ": " + e.getMessage());
            return null;
        }
    }

    /** Whether the permission appears in the package's declared list, via a given context. */
    private static String declaredVia(Context context, String self, String permission) {
        try {
            PackageInfo info = context.getPackageManager()
                    .getPackageInfo(self, PackageManager.GET_PERMISSIONS);
            String[] requested = info.requestedPermissions;
            if (requested == null) {
                return "NOT DECLARED (requestedPermissions null)";
            }
            List<String> list = Arrays.asList(requested);
            return list.contains(permission)
                    ? "declared (" + requested.length + " total)"
                    : "NOT DECLARED (" + requested.length + " total)";
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    private static String result(PermissionCheck check) {
        try {
            return check.run() == PackageManager.PERMISSION_GRANTED ? "GRANTED" : "DENIED";
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    private static void record(StringBuilder detail, String label, String value) {
        DiagLog.line(DiagLog.TAG_PACKAGE, "P18" + label + "= " + value);
        detail.append(label).append("= ").append(value).append('\n');
    }

    private static void emit(StringBuilder detail, String key, String value) {
        DiagLog.line(DiagLog.TAG_PACKAGE, "P18 " + key + " = " + value);
        detail.append(key).append(" = ").append(value).append('\n');
    }

    /** So each variant can be passed as a lambda and share one try/catch. */
    private interface PermissionCheck {
        int run();
    }
}
