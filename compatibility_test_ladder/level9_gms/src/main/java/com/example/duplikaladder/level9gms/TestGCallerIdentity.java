package com.example.duplikaladder.level9gms;

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Process;

import java.util.Arrays;

/**
 * TEST G — is this process's claimed package coherent with the UID it runs as?
 *
 * <p>Added after the host-passthrough change made Play services genuinely visible (Test A
 * and B pass) while a real API call still failed with {@code DEVELOPER_ERROR}. The identical
 * APK passes on a normal installation, so the cause is not the manifest, the permissions or
 * the client library; it is what the caller looks like from outside.
 *
 * <p>A guest runs under the host app's kernel UID while presenting its own package name. Any
 * service that resolves its caller's UID back to a package — which is the ordinary way an
 * Android service identifies who is calling it — therefore sees two different answers. This
 * measures that mismatch directly instead of inferring it from a client library's error code.
 *
 * <p>This test only reports. Making the mismatch go away would mean changing what the guest
 * claims to be toward a service that is deliberately checking, which is caller-identity
 * spoofing and is out of scope by design.
 */
final class TestGCallerIdentity {

    private TestGCallerIdentity() {
    }

    static TestResult run(Context context) {
        DiagLog.section("TEST G — caller identity coherence");
        StringBuilder detail = new StringBuilder();

        String ownPackage = context.getPackageName();
        int myUid = Process.myUid();
        detail.append("claimed package = ").append(ownPackage).append('\n')
                .append("process uid     = ").append(myUid).append('\n');

        PackageManager pm = context.getPackageManager();

        String[] uidPackages;
        try {
            uidPackages = pm.getPackagesForUid(myUid);
        } catch (RuntimeException e) {
            DiagLog.failure(DiagLog.TAG_UID, "getPackagesForUid threw", e);
            detail.append("getPackagesForUid threw ").append(e.getClass().getName()).append('\n');
            return TestResult.of("G", "Caller identity coherence", Verdict.BLOCKED,
                    "getPackagesForUid threw " + e.getClass().getSimpleName(), detail.toString());
        }

        String rendered = uidPackages == null ? "null" : Arrays.toString(uidPackages);
        detail.append("getPackagesForUid(").append(myUid).append(") = ").append(rendered).append('\n');
        DiagLog.line(DiagLog.TAG_UID, "claimedPackage=" + ownPackage + " uid=" + myUid
                + " getPackagesForUid=" + rendered);

        boolean coherent = uidPackages != null && Arrays.asList(uidPackages).contains(ownPackage);

        int declaredUid = -1;
        try {
            declaredUid = pm.getApplicationInfo(ownPackage, 0).uid;
            detail.append("getApplicationInfo(own).uid = ").append(declaredUid).append('\n');
        } catch (PackageManager.NameNotFoundException | RuntimeException e) {
            detail.append("getApplicationInfo(own) failed: ").append(e.getClass().getName()).append('\n');
        }
        DiagLog.line(DiagLog.TAG_UID, "declaredUidForOwnPackage=" + declaredUid
                + " coherentWithProcessUid=" + coherent);

        detail.append("claimed package owned by this uid = ").append(coherent).append('\n');

        // Not a defect to fix: a coherent answer here would mean the container had convinced
        // the platform that its UID owns the guest's package. Incoherence is the honest
        // state of a virtualized caller, and is recorded as PARTIAL rather than FAIL for
        // that reason.
        Verdict verdict = coherent ? Verdict.PASS : Verdict.PARTIAL;
        String summary = coherent
                ? "self-consistent as seen from inside this process (uid " + myUid
                        + " reported as owning " + ownPackage + ")"
                : "claimed package is not owned by this uid — a service that resolves its "
                        + "caller by uid will not see " + ownPackage;
        DiagLog.line(DiagLog.TAG_UID, "TEST G verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("G", "Caller identity coherence", verdict, summary, detail.toString());
    }
}
