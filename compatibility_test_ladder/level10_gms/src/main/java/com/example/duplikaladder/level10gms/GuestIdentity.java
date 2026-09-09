package com.example.duplikaladder.level10gms;

import android.app.Application;
import android.content.Context;
import android.os.Build;
import android.os.Process;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Who this process actually is, from inside it.
 *
 * <p>Every Level 10 failure has to be attributable to a specific guest identity, so this
 * is captured once per run and stamped into the log ahead of the tests. It reads only
 * what any app may read about itself — no engine class is referenced, so the same APK
 * runs unchanged on the host and inside a container, which is the whole point: the two
 * runs are comparable because the binary is identical.
 */
public final class GuestIdentity {

    /**
     * Virtual user id parsed out of a redirected data directory, e.g.
     * {@code .../blackbox/data/user/1/<package>}. Bcore rewrites the data directory of a
     * guest process, so the path is the honest signal available from inside; there is no
     * public API for "which container am I in".
     */
    private static final Pattern VIRTUAL_USER =
            Pattern.compile("/(?:blackbox|virtual)/(?:data/)?user/(\\d+)/");

    public final String packageName;
    public final int uid;
    public final int pid;
    public final String processName;
    public final String dataDir;
    public final boolean virtualized;
    public final String virtualUserId;

    private GuestIdentity(String packageName, int uid, int pid, String processName,
                          String dataDir, boolean virtualized, String virtualUserId) {
        this.packageName = packageName;
        this.uid = uid;
        this.pid = pid;
        this.processName = processName;
        this.dataDir = dataDir;
        this.virtualized = virtualized;
        this.virtualUserId = virtualUserId;
    }

    public static GuestIdentity capture(Context context) {
        String dataDir = context.getApplicationInfo().dataDir;
        String filesDir = context.getFilesDir() == null ? "" : context.getFilesDir().getAbsolutePath();
        String probe = dataDir + " " + filesDir;

        Matcher matcher = VIRTUAL_USER.matcher(probe);
        boolean virtualized = matcher.find();
        String virtualUserId = virtualized ? matcher.group(1) : "n/a (host installation)";

        return new GuestIdentity(
                context.getPackageName(),
                Process.myUid(),
                Process.myPid(),
                processName(),
                dataDir,
                virtualized,
                virtualUserId);
    }

    private static String processName() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            return Application.getProcessName();
        }
        return "unavailable-below-api-28";
    }

    /**
     * The header written before every run.
     *
     * <p>{@code uid} is the host UID the guest runs under — a container does not get its
     * own kernel UID, it shares the host app's, and several of the results below only
     * make sense once that is on the record.
     */
    public void log() {
        DiagLog.line(DiagLog.TAG_UID, "guestPackage=" + packageName);
        DiagLog.line(DiagLog.TAG_UID, "hostUid=" + uid + " pid=" + pid);
        DiagLog.line(DiagLog.TAG_UID, "processName=" + processName);
        DiagLog.line(DiagLog.TAG_UID, "dataDir=" + dataDir);
        DiagLog.line(DiagLog.TAG_UID, "virtualized=" + virtualized + " virtualUserId=" + virtualUserId);
        DiagLog.line(DiagLog.TAG, "device=" + Build.MANUFACTURER + " " + Build.MODEL
                + " android=" + Build.VERSION.RELEASE + " api=" + Build.VERSION.SDK_INT
                + " abi=" + (Build.SUPPORTED_ABIS.length > 0 ? Build.SUPPORTED_ABIS[0] : "unknown"));
        DiagLog.line(DiagLog.TAG, "buildType=" + (BuildConfig.DEBUG ? "debug" : "release")
                + " minified=" + !BuildConfig.DEBUG);
    }

    public String summary() {
        return (virtualized ? "GUEST (virtual user " + virtualUserId + ")" : "HOST installation")
                + " · uid " + uid + " · " + processName;
    }
}
