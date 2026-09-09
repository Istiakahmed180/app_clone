package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

/**
 * P0 — Layer A + Layer B, run first as Level 10's own baseline.
 *
 * <p>Level 9 already measured these, but Level 10 must not inherit them: if package
 * visibility or availability has regressed, every later probe's failure would be
 * misattributed to the client layer. So this runs before P1–P3 and gates them.
 *
 * <p>The consistency check is the point, not the individual values. Level 9's root cause
 * was that different PackageManager entry points disagreed about the same package —
 * {@code getPackageInfo} threw {@code NameNotFoundException} while
 * {@code getApplicationEnabledSetting} answered "enabled" microseconds later. This probe
 * asks all three about both packages in one pass and fails if they contradict each other,
 * so a regression of that specific kind cannot pass unnoticed.
 */
final class ProbeAvailability {

    private static final String[] PACKAGES = {
            "com.google.android.gms",
            "com.android.vending",
    };

    private ProbeAvailability() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P0 — package visibility + Play services availability (Level 10 baseline)");
        StringBuilder detail = new StringBuilder();
        PackageManager pm = context.getPackageManager();
        boolean allConsistent = true;

        for (String pkg : PACKAGES) {
            boolean packageInfoOk = false;
            boolean applicationInfoOk = false;
            boolean enabledOk = false;

            try {
                PackageInfo info = pm.getPackageInfo(pkg, 0);
                packageInfoOk = true;
                // longVersionCode is the API 28+ accessor; the ladder's minSdk is 23, but
                // this module is only ever run on the API 35 device of record.
                DiagLog.line(DiagLog.TAG_PACKAGE, pkg + " getPackageInfo OK"
                        + " versionName=" + info.versionName
                        + " versionCode=" + info.getLongVersionCode());
                detail.append(pkg).append(" getPackageInfo OK versionName=").append(info.versionName)
                        .append(" versionCode=").append(info.getLongVersionCode()).append('\n');
            } catch (Throwable e) {
                DiagLog.failure(DiagLog.TAG_PACKAGE, pkg + " getPackageInfo failed", e);
                detail.append(pkg).append(" getPackageInfo FAILED ")
                        .append(e.getClass().getSimpleName()).append('\n');
            }

            try {
                ApplicationInfo app = pm.getApplicationInfo(pkg, 0);
                applicationInfoOk = true;
                DiagLog.line(DiagLog.TAG_PACKAGE, pkg + " getApplicationInfo OK enabled="
                        + app.enabled + " uidOfPackage=" + app.uid);
                detail.append(pkg).append(" getApplicationInfo OK enabled=").append(app.enabled)
                        .append('\n');
            } catch (Throwable e) {
                DiagLog.failure(DiagLog.TAG_PACKAGE, pkg + " getApplicationInfo failed", e);
                detail.append(pkg).append(" getApplicationInfo FAILED ")
                        .append(e.getClass().getSimpleName()).append('\n');
            }

            try {
                int setting = pm.getApplicationEnabledSetting(pkg);
                // 0 = DEFAULT, 1 = ENABLED. Both mean "this package exists and is usable",
                // which is what has to agree with the two calls above.
                enabledOk = setting == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
                        || setting == PackageManager.COMPONENT_ENABLED_STATE_ENABLED;
                DiagLog.line(DiagLog.TAG_PACKAGE, pkg + " enabledSetting=" + setting);
                detail.append(pkg).append(" enabledSetting=").append(setting).append('\n');
            } catch (Throwable e) {
                DiagLog.failure(DiagLog.TAG_PACKAGE, pkg + " getApplicationEnabledSetting failed", e);
                detail.append(pkg).append(" getApplicationEnabledSetting FAILED ")
                        .append(e.getClass().getSimpleName()).append('\n');
            }

            boolean consistent = packageInfoOk == applicationInfoOk && applicationInfoOk == enabledOk;
            if (!consistent) {
                allConsistent = false;
            }
            DiagLog.line(DiagLog.TAG_PACKAGE, pkg + " consistency"
                    + " packageInfo=" + packageInfoOk
                    + " applicationInfo=" + applicationInfoOk
                    + " enabled=" + enabledOk
                    + " consistent=" + consistent);
            detail.append(pkg).append(" CONSISTENT=").append(consistent).append("\n\n");
        }

        // getInstalledPackages must stay container-scoped. If a guest can suddenly
        // enumerate the whole host, isolation has regressed and that is worth catching
        // here even though it is not a GMS question.
        int installedCount = -1;
        try {
            installedCount = context.getPackageManager().getInstalledPackages(0).size();
            DiagLog.line(DiagLog.TAG_PACKAGE, "getInstalledPackages count=" + installedCount);
            detail.append("getInstalledPackages count=").append(installedCount)
                    .append(" (expected: container-scoped, not the host's full list)\n");
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG_PACKAGE, "getInstalledPackages failed", e);
        }

        int availability;
        String availabilityName;
        try {
            availability = GoogleApiAvailability.getInstance()
                    .isGooglePlayServicesAvailable(context);
            availabilityName = describe(availability);
            DiagLog.line(DiagLog.TAG, "isGooglePlayServicesAvailable=" + availability
                    + " name=" + availabilityName);
            detail.append("isGooglePlayServicesAvailable=").append(availability)
                    .append(" (").append(availabilityName).append(")\n");
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "isGooglePlayServicesAvailable threw", e);
            detail.append("isGooglePlayServicesAvailable threw ")
                    .append(e.getClass().getName()).append('\n');
            return finish(Verdict.BLOCKED, "availability check threw", detail);
        }

        if (availability != ConnectionResult.SUCCESS) {
            return finish(Verdict.FAIL,
                    "availability is " + availabilityName + " (" + availability + ")", detail);
        }
        if (!allConsistent) {
            return finish(Verdict.PARTIAL,
                    "availability SUCCESS but PackageManager answers disagree", detail);
        }
        return finish(Verdict.PASS,
                "consistent package metadata and SUCCESS(0) availability", detail);
    }

    private static String describe(int code) {
        switch (code) {
            case ConnectionResult.SUCCESS: return "SUCCESS";
            case ConnectionResult.SERVICE_MISSING: return "SERVICE_MISSING";
            case ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED:
                return "SERVICE_VERSION_UPDATE_REQUIRED";
            case ConnectionResult.SERVICE_DISABLED: return "SERVICE_DISABLED";
            case ConnectionResult.SERVICE_INVALID: return "SERVICE_INVALID";
            default: return "code " + code;
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P0 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P0", "Package visibility + availability", verdict, summary,
                detail.toString());
    }
}
