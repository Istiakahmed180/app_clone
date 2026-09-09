package com.example.duplikaladder.umprobe;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import android.os.UserManager;
import android.util.Log;
import android.util.TypedValue;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Reproduces, in isolation, the framework call that crashes Chrome inside a Duplika
 * container on Android 15.
 *
 * <p>Chrome's crash is:
 *
 * <pre>
 * java.lang.SecurityException: Only system may: get application restrictions for other
 *     user/app com.android.chrome
 *   at android.os.IUserManager$Stub$Proxy.getApplicationRestrictionsForUser
 *   at android.os.UserManager.getApplicationRestrictions
 * </pre>
 *
 * <p>The important detail is that Chrome asks for <b>its own</b> package's restrictions,
 * which any app may do. It only looks like a cross-app request from the framework's side,
 * because inside a container the Binder calling UID is the host app's while the package name
 * is the guest's — so the two do not correspond and the platform refuses.
 *
 * <p>This probe therefore does exactly that and nothing more: it asks
 * {@code getApplicationRestrictions(getPackageName())} — always its <b>own</b> package. It
 * never queries another app, never queries another Android user, never reads Chrome data,
 * and never touches a restrictions value; only whether the call succeeded, how big the
 * returned Bundle was, and the exception if one was thrown.
 *
 * <p>Run the same APK twice — installed normally, then cloned — and compare. The APK has no
 * dependencies at all, so the only difference between the runs is the virtualization layer.
 */
public class MainActivity extends Activity {

    private static final String TAG = "Duplika.UMProbe";

    /** Virtual user id parsed from a redirected data dir, as the other ladder probes do. */
    private static final Pattern VIRTUAL_USER =
            Pattern.compile("/(?:blackbox|virtual)/(?:data/)?user/(\\d+)/");

    private final List<String> lines = new ArrayList<>();

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);

        header();
        probeOwnApplicationRestrictions();
        probeUserRestrictionsControl();
        probeIsSystemUserControl();
        line("================ RUN COMPLETE ================");
        writeReport();

        TextView view = new TextView(this);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        view.setPadding(24, 24, 24, 24);
        view.setText(String.join("\n", lines));
        ScrollView scroller = new ScrollView(this);
        scroller.addView(view);
        setContentView(scroller);
    }

    private void header() {
        String dataDir = getApplicationInfo().dataDir;
        String filesDir = getFilesDir() == null ? "" : getFilesDir().getAbsolutePath();
        Matcher m = VIRTUAL_USER.matcher(dataDir + " " + filesDir);
        boolean virtualized = m.find();

        line("================ USERMANAGER PROBE ================");
        line("package=" + getPackageName());
        line("uid=" + Process.myUid() + " pid=" + Process.myPid());
        line("processName=" + (Build.VERSION.SDK_INT >= 28 ? Application.getProcessName() : "n/a"));
        line("dataDir=" + dataDir);
        line("virtualized=" + virtualized
                + " virtualUserId=" + (virtualized ? m.group(1) : "n/a (host installation)"));
        line("device=" + Build.MANUFACTURER + " " + Build.MODEL
                + " android=" + Build.VERSION.RELEASE + " api=" + Build.VERSION.SDK_INT);
        line("buildType=" + (BuildConfig.DEBUG ? "debug" : "release")
                + " minified=" + !BuildConfig.DEBUG);
    }

    /**
     * The call that crashes Chrome — asked for this app's own package.
     *
     * <p>On the host this is expected to succeed and return an empty Bundle (no managed
     * profile, so no restrictions are set). Inside a container the question is whether the
     * engine's {@code IUserManagerProxy} normalises the request or whether it reaches the
     * real service unmodified and is refused.
     */
    private void probeOwnApplicationRestrictions() {
        line("");
        line("---- P1: getApplicationRestrictions(OWN package) ----");
        line("this is Chrome's exact call shape: an app asking about itself");
        UserManager um = (UserManager) getSystemService(Context.USER_SERVICE);
        if (um == null) {
            line("RESULT: BLOCKED — USER_SERVICE unavailable");
            return;
        }
        long started = System.currentTimeMillis();
        try {
            Bundle restrictions = um.getApplicationRestrictions(getPackageName());
            long ms = System.currentTimeMillis() - started;
            int size = restrictions == null ? -1 : restrictions.size();
            // Only the SIZE is recorded. Restriction values are managed-policy data and the
            // diagnosis does not need them.
            line("RESULT: SUCCESS in " + ms + " ms — bundleNull=" + (restrictions == null)
                    + " keyCount=" + size);
            line("(restriction values are deliberately not recorded)");
        } catch (Throwable e) {
            long ms = System.currentTimeMillis() - started;
            line("RESULT: THREW after " + ms + " ms");
            line("  exceptionClass=" + e.getClass().getName());
            line("  exceptionMessage=" + e.getMessage());
            StackTraceElement[] trace = e.getStackTrace();
            for (int i = 0; i < Math.min(4, trace.length); i++) {
                line("  at " + trace[i]);
            }
        }
    }

    /**
     * Control: a UserManager call about the current user that needs no cross-app
     * permission. If this succeeds while P1 fails, the failure is specific to the
     * package-scoped restrictions call rather than to UserManager being unreachable.
     */
    private void probeUserRestrictionsControl() {
        line("");
        line("---- P2 control: getUserRestrictions() (own user, no package argument) ----");
        UserManager um = (UserManager) getSystemService(Context.USER_SERVICE);
        try {
            Bundle b = um.getUserRestrictions();
            line("RESULT: SUCCESS — keyCount=" + (b == null ? -1 : b.size()));
        } catch (Throwable e) {
            line("RESULT: THREW " + e.getClass().getName() + ": " + e.getMessage());
        }
    }

    /** Second control: a trivial UserManager query, to show the service itself is usable. */
    private void probeIsSystemUserControl() {
        line("");
        line("---- P3 control: UserManager.isSystemUser() ----");
        UserManager um = (UserManager) getSystemService(Context.USER_SERVICE);
        try {
            line("RESULT: SUCCESS — isSystemUser=" + um.isSystemUser());
        } catch (Throwable e) {
            line("RESULT: THREW " + e.getClass().getName() + ": " + e.getMessage());
        }
    }

    private void line(String text) {
        lines.add(text);
        Log.i(TAG, text);
    }

    /** A copy on disk as well as in logcat; inside a container the path is itself telling. */
    private void writeReport() {
        File target = new File(getFilesDir(), "um-probe-report.txt");
        try (FileOutputStream out = new FileOutputStream(target)) {
            out.write(String.join("\n", lines).getBytes(Charset.forName("UTF-8")));
            line("report written to " + target.getAbsolutePath());
        } catch (IOException e) {
            Log.e(TAG, "could not write report", e);
        }
    }
}
