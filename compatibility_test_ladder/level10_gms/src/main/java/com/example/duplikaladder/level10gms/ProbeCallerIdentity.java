package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Process;

/**
 * P4 — caller identity trace. DIAGNOSIS ONLY.
 *
 * <p>Level 9 established, from the host side, that Play services observes the guest's bind
 * as {@code mCallingUid=<the Duplika host UID>} while the client library names the guest's
 * own package. This probe records the same mismatch from *inside* the guest, so the two
 * halves of the picture sit in one evidence set.
 *
 * <p>Nothing here modifies identity. There is deliberately no attempt to make
 * {@code Process.myUid()} agree with the host's view, to rewrite the package name sent to
 * Play services, or to influence what any Google service believes about the caller — that
 * would be the identity spoofing the project forbids, and it is the reason the affected
 * APIs are classified {@code UNSUPPORTED / SECURITY-BOUNDARY} rather than treated as bugs.
 *
 * <p>What the probe can and cannot see is worth stating plainly. From inside the process it
 * can read the UID the engine reports, the package name, and what the virtualized
 * PackageManager says owns that UID. It cannot read the kernel-level Binder calling UID
 * that Play services actually receives — only the host side can, which is why the Level 9
 * host-side capture is referenced rather than reproduced.
 */
final class ProbeCallerIdentity {

    private ProbeCallerIdentity() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P4 — caller identity trace (diagnosis only, nothing is modified)");
        StringBuilder detail = new StringBuilder();

        String claimedPackage = context.getPackageName();
        int uid = Process.myUid();
        int pid = Process.myPid();

        DiagLog.line(DiagLog.TAG_UID, "claimedPackage=" + claimedPackage + " uid=" + uid + " pid=" + pid);
        detail.append("package this process claims to be: ").append(claimedPackage).append('\n');
        detail.append("uid as reported inside the guest: ").append(uid).append('\n');
        detail.append("pid: ").append(pid).append('\n');

        // What the *virtualized* PackageManager says owns this UID. Inside a container this
        // is answered by the engine, so agreement here says nothing about what the host --
        // or Play services -- believes.
        String[] owners;
        try {
            owners = context.getPackageManager().getPackagesForUid(uid);
        } catch (Throwable e) {
            owners = null;
            DiagLog.failure(DiagLog.TAG_UID, "getPackagesForUid failed", e);
        }
        String ownerList = owners == null ? "null" : java.util.Arrays.toString(owners);
        DiagLog.line(DiagLog.TAG_UID, "getPackagesForUid(" + uid + ")=" + ownerList
                + " (answered by the VIRTUALIZED PackageManager)");
        detail.append("getPackagesForUid(").append(uid).append(") = ").append(ownerList)
                .append("  <- virtualized answer, not the host's\n");

        boolean selfConsistentInside = owners != null && contains(owners, claimedPackage);

        int declaredUid = -1;
        try {
            declaredUid = context.getPackageManager()
                    .getApplicationInfo(claimedPackage, 0).uid;
        } catch (PackageManager.NameNotFoundException e) {
            DiagLog.failure(DiagLog.TAG_UID, "own ApplicationInfo not found", e);
        }
        DiagLog.line(DiagLog.TAG_UID, "declaredUidForOwnPackage=" + declaredUid
                + " matchesProcessUid=" + (declaredUid == uid));
        detail.append("ApplicationInfo.uid for own package: ").append(declaredUid)
                .append(" (matches process uid: ").append(declaredUid == uid).append(")\n");

        detail.append('\n');
        detail.append("LIMIT OF THIS PROBE: the Binder calling UID that Play services\n");
        detail.append("actually receives cannot be read from inside this process. Level 9\n");
        detail.append("captured it host-side: Play services' own BoundBrokerSvc logged the\n");
        detail.append("guest's binds as mCallingUid=<Duplika host uid>, never a uid owning\n");
        detail.append("this package. See level9-gms/host-passthrough-investigation/\n");
        detail.append("gms-caller-identity.log.\n");
        DiagLog.line(DiagLog.TAG_UID,
                "NOTE the kernel Binder calling uid is not observable from inside the guest;"
                        + " see Level 9 host-side capture");

        // Deliberately not a PASS/FAIL of compatibility. It is self-consistent inside the
        // container by construction, and that is exactly what makes it misleading on its
        // own -- Level 9 Test G reported PASS here while the GoogleApi path was failing for
        // this very reason. So the verdict records coherence, and the summary says whose
        // view it describes.
        if (selfConsistentInside && declaredUid == uid) {
            return finish(Verdict.PASS,
                    "self-consistent INSIDE the guest (says nothing about the host's view)",
                    detail);
        }
        return finish(Verdict.PARTIAL,
                "identity is not self-consistent even inside the guest", detail);
    }

    private static boolean contains(String[] values, String needle) {
        for (String value : values) {
            if (needle.equals(value)) {
                return true;
            }
        }
        return false;
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P4 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P4", "Caller identity trace", verdict, summary, detail.toString());
    }
}
