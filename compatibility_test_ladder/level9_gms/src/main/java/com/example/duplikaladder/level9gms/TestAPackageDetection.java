package com.example.duplikaladder.level9gms;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.os.Build;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * TEST A — can the guest see {@code com.google.android.gms} at all?
 *
 * <p>This is first because every Google API begins here. If the package is invisible,
 * everything downstream fails for one reason and the later tests only measure the echo.
 *
 * <p>Nothing is faked. The manifest declares {@code <queries>} for these packages, which
 * is the ordinary, documented way an app asks to see them, so an invisible result is a
 * property of the virtualization layer and not of Android 11 package filtering.
 */
final class TestAPackageDetection {

    static final String GMS = "com.google.android.gms";
    static final String GSF = "com.google.android.gsf";
    static final String VENDING = "com.android.vending";

    private TestAPackageDetection() {
    }

    static TestResult run(Context context) {
        DiagLog.section("TEST A — GMS package detection");
        PackageManager pm = context.getPackageManager();

        StringBuilder detail = new StringBuilder();
        boolean gmsVisible = probe(pm, GMS, detail);
        probeSigningCertificate(pm, GMS, detail);
        boolean gsfVisible = probe(pm, GSF, detail);
        boolean vendingVisible = probe(pm, VENDING, detail);

        Verdict verdict;
        String summary;
        if (gmsVisible) {
            verdict = (gsfVisible && vendingVisible) ? Verdict.PASS : Verdict.PARTIAL;
            summary = gmsVisible && gsfVisible && vendingVisible
                    ? "all three Google packages visible"
                    : "GMS visible; gsf=" + gsfVisible + " vending=" + vendingVisible;
        } else {
            verdict = Verdict.FAIL;
            summary = "com.google.android.gms is not visible to this process";
        }
        DiagLog.line(DiagLog.TAG_PACKAGE, "TEST A verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("A", "GMS package detection", verdict, summary, detail.toString());
    }

    /**
     * What signing certificate the guest's PackageManager reports for Play services.
     *
     * <p>This exists to separate two failures that look identical from the outside. The
     * Google client libraries verify that the Play services they found is Google-signed
     * before using it, so a rejected Play services can mean either that the container
     * holds a differently-signed copy or that the container reports the genuine one
     * incorrectly. Comparing this digest between a normal installation and a container
     * says which, and nothing else does.
     *
     * <p>A certificate digest is public information — it is the same value {@code apksigner}
     * prints for any installed APK — so recording it discloses nothing. This only reads and
     * reports; no signature is produced, altered or presented anywhere.
     */
    private static void probeSigningCertificate(PackageManager pm, String packageName,
                                                StringBuilder detail) {
        detail.append("  signing certificate\n");
        try {
            Signature[] signatures = readSignatures(pm, packageName);
            if (signatures == null || signatures.length == 0) {
                detail.append("    none reported\n");
                DiagLog.line(DiagLog.TAG_PACKAGE, packageName + " signatures: none reported");
                return;
            }
            for (Signature signature : signatures) {
                String digest = sha256(signature.toByteArray());
                detail.append("    sha256=").append(digest).append('\n');
                DiagLog.line(DiagLog.TAG_PACKAGE, packageName + " signature sha256=" + digest);
            }
        } catch (PackageManager.NameNotFoundException e) {
            detail.append("    NameNotFoundException\n");
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " signature lookup not found", e);
        } catch (RuntimeException e) {
            detail.append("    ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " signature lookup threw", e);
        }
    }

    private static Signature[] readSignatures(PackageManager pm, String packageName)
            throws PackageManager.NameNotFoundException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            SigningInfo info = pm.getPackageInfo(
                    packageName, PackageManager.GET_SIGNING_CERTIFICATES).signingInfo;
            if (info == null) {
                return null;
            }
            return info.hasMultipleSigners()
                    ? info.getApkContentsSigners() : info.getSigningCertificateHistory();
        }
        return pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures;
    }

    private static String sha256(byte[] input) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(input);
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                hex.append(Character.forDigit((b >> 4) & 0xF, 16))
                   .append(Character.forDigit(b & 0xF, 16));
            }
            return hex.toString();
        } catch (NoSuchAlgorithmException e) {
            return "sha256-unavailable";
        }
    }

    /**
     * Three separate PackageManager entry points, not one.
     *
     * <p>They are asked independently because a virtualized PackageManager can answer
     * them inconsistently — the interesting failure is not "no" everywhere, it is
     * {@code getPackageInfo} throwing while {@code getApplicationInfo} succeeds, which
     * points at the virtualization layer rather than at absence.
     */
    private static boolean probe(PackageManager pm, String packageName, StringBuilder detail) {
        boolean visible = false;
        detail.append(packageName).append('\n');

        try {
            PackageInfo info = pm.getPackageInfo(packageName, 0);
            long code = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
                    ? info.getLongVersionCode() : info.versionCode;
            visible = true;
            detail.append("  getPackageInfo: OK versionName=").append(info.versionName)
                    .append(" versionCode=").append(code).append('\n');
            DiagLog.line(DiagLog.TAG_PACKAGE, packageName + " getPackageInfo OK"
                    + " versionName=" + info.versionName + " versionCode=" + code);
        } catch (PackageManager.NameNotFoundException e) {
            detail.append("  getPackageInfo: NameNotFoundException\n");
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " getPackageInfo not found", e);
        } catch (RuntimeException e) {
            detail.append("  getPackageInfo: ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " getPackageInfo threw", e);
        }

        try {
            ApplicationInfo app = pm.getApplicationInfo(packageName, 0);
            detail.append("  getApplicationInfo: OK enabled=").append(app.enabled)
                    .append(" uid=").append(app.uid)
                    .append(" sourceDir=").append(app.sourceDir).append('\n');
            DiagLog.line(DiagLog.TAG_PACKAGE, packageName + " getApplicationInfo OK"
                    + " enabled=" + app.enabled + " hostUidOfPackage=" + app.uid
                    + " sourceDir=" + app.sourceDir);
        } catch (PackageManager.NameNotFoundException e) {
            detail.append("  getApplicationInfo: NameNotFoundException\n");
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " getApplicationInfo not found", e);
        } catch (RuntimeException e) {
            detail.append("  getApplicationInfo: ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " getApplicationInfo threw", e);
        }

        try {
            int state = pm.getApplicationEnabledSetting(packageName);
            detail.append("  getApplicationEnabledSetting: ").append(state).append('\n');
            DiagLog.line(DiagLog.TAG_PACKAGE, packageName + " enabledSetting=" + state);
        } catch (RuntimeException e) {
            detail.append("  getApplicationEnabledSetting: ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_PACKAGE, packageName + " enabledSetting threw", e);
        }

        return visible;
    }
}
