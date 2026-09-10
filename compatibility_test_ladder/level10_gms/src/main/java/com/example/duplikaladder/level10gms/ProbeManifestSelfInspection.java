package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * P17 — can the guest read its own manifest back?
 *
 * <p>Written to test one specific, falsifiable hypothesis raised by P15.
 *
 * <p>The Maps SDK refused to construct a {@code MapView} in a guest with:
 *
 * <pre>
 * SecurityException: The Maps API requires the additional following permissions to be set
 * in the AndroidManifest.xml to ensure a correct behavior:
 *   &lt;uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/&gt;
 *   &lt;uses-permission android:name="android.permission.INTERNET"/&gt;
 * </pre>
 *
 * <p>This fixture's manifest declares <b>both</b> of those, and the identical APK passes the
 * same check on the host. So the SDK is not asking for something the app lacks — it is
 * asking the PackageManager what the app declares and getting a different answer inside a
 * container.
 *
 * <p>That matters more than Maps. This is a <em>self</em>-inspection: an app reading its own
 * manifest. It involves no other package, no account, no signature and no identity
 * assertion, so if the guest answer is wrong it is an ordinary virtualization defect of
 * exactly the shape the Level 9 package-visibility fix had — and, unlike the caller-identity
 * boundary, it is legitimately fixable. Many SDKs perform this kind of startup self-check,
 * so a wrong answer here plausibly affects far more than the Maps SDK.
 *
 * <p>The probe reads the four manifest facets an SDK self-check typically uses, and pairs
 * {@code requestedPermissions} with {@code checkSelfPermission} because they can disagree:
 * a permission can be *declared* (what Maps asks about) yet not *granted*, and conflating
 * the two would misattribute the failure.
 *
 * <p><b>Read-only.</b> Every call is a query about this app's own package.
 */
final class ProbeManifestSelfInspection {

    /** The two Maps insists on, plus one this fixture also declares as a control. */
    private static final String[] EXPECTED_PERMISSIONS = {
            "android.permission.INTERNET",
            "android.permission.ACCESS_NETWORK_STATE",
            "android.permission.ACTIVITY_RECOGNITION",
    };

    private ProbeManifestSelfInspection() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P17 — manifest self-inspection (does the guest report its own declarations?)");
        StringBuilder detail = new StringBuilder();
        PackageManager pm = context.getPackageManager();
        String self = context.getPackageName();

        // (1) The declaration list — the exact thing the Maps SDK reads.
        String[] requested = null;
        try {
            PackageInfo info = pm.getPackageInfo(self, PackageManager.GET_PERMISSIONS);
            requested = info.requestedPermissions;
        } catch (Throwable e) {
            emit(detail, "self.getPackageInfo(GET_PERMISSIONS)", threw(e));
        }
        List<String> declared = requested == null
                ? new ArrayList<>()
                : Arrays.asList(requested);
        emit(detail, "self.requestedPermissions.count",
                requested == null ? "NULL" : String.valueOf(requested.length));
        emit(detail, "self.requestedPermissions", declared.isEmpty() ? "[]" : declared.toString());

        // (2) Declared vs granted, kept apart on purpose.
        detail.append('\n');
        int missing = 0;
        for (String permission : EXPECTED_PERMISSIONS) {
            boolean isDeclared = declared.contains(permission);
            String granted;
            try {
                granted = pm.checkPermission(permission, self) == PackageManager.PERMISSION_GRANTED
                        ? "GRANTED" : "DENIED";
            } catch (Throwable e) {
                granted = threw(e);
            }
            if (!isDeclared) {
                missing++;
            }
            emit(detail, "permission[" + permission + "]",
                    "declaredInManifest=" + isDeclared + " granted=" + granted);
        }

        // (3) The other manifest facets a self-check might read, so a defect can be scoped
        // to permissions rather than assumed to be permissions.
        detail.append('\n');
        emit(detail, "self.metaData[com.google.android.geo.API_KEY]", mapsKeyPresence(pm, self));
        emit(detail, "self.componentCounts", componentCounts(pm, self));

        detail.append('\n').append("READING\n");
        Verdict verdict;
        String summary;
        if (missing == 0) {
            detail.append("The app can read its own declared permissions correctly. If this is\n");
            detail.append("the host column, it is the control; if the guest column also shows\n");
            detail.append("this, the Maps failure is NOT manifest self-inspection.\n");
            DiagLog.line(DiagLog.TAG, "P17 self-inspection intact: all "
                    + EXPECTED_PERMISSIONS.length + " declared permissions are reported back");
            verdict = Verdict.PASS;
            summary = "manifest self-inspection correct";
        } else {
            DiagLog.line(DiagLog.TAG, "P17 DEFECT: " + missing + " of " + EXPECTED_PERMISSIONS.length
                    + " permissions this app genuinely declares are NOT reported by"
                    + " getPackageInfo(GET_PERMISSIONS). This is a wrong answer about the"
                    + " app's own manifest — an ordinary virtualization defect, not an"
                    + " identity boundary, and it is what the Maps SDK rejects.");
            detail.append("DEFECT: ").append(missing).append(" permission(s) this app genuinely\n");
            detail.append("declares are not reported back. No identity is involved — this is the\n");
            detail.append("app asking about itself — so this is legitimately fixable, and it is\n");
            detail.append("the direct cause of the Maps MapView SecurityException in P15.\n");
            verdict = Verdict.FAIL;
            summary = missing + " declared permission(s) not reported by the virtualized PM";
        }

        DiagLog.line(DiagLog.TAG, "P17 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P17", "Manifest self-inspection", verdict, summary, detail.toString());
    }

    /** Presence only — the placeholder key's value is not worth logging. */
    private static String mapsKeyPresence(PackageManager pm, String self) {
        try {
            android.content.pm.ApplicationInfo info =
                    pm.getApplicationInfo(self, PackageManager.GET_META_DATA);
            if (info.metaData == null) {
                return "no metaData bundle";
            }
            return info.metaData.containsKey("com.google.android.geo.API_KEY")
                    ? "present" : "absent";
        } catch (Throwable e) {
            return threw(e);
        }
    }

    private static String componentCounts(PackageManager pm, String self) {
        try {
            PackageInfo info = pm.getPackageInfo(self, PackageManager.GET_ACTIVITIES
                    | PackageManager.GET_SERVICES | PackageManager.GET_PROVIDERS);
            return "activities=" + count(info.activities)
                    + " services=" + count(info.services)
                    + " providers=" + count(info.providers);
        } catch (Throwable e) {
            return threw(e);
        }
    }

    private static int count(Object[] array) {
        return array == null ? -1 : array.length;
    }

    private static String threw(Throwable e) {
        return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
    }

    private static void emit(StringBuilder detail, String key, String value) {
        DiagLog.line(DiagLog.TAG_PACKAGE, "P17 " + key + " = " + value);
        detail.append(key).append(" = ").append(value).append('\n');
    }
}
