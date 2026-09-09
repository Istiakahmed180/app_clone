package com.example.duplikaladder.isosvc;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.os.Process;
import android.util.Log;
import android.util.TypedValue;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Minimal reproduction for the Chrome post-launch failure, with Chrome removed.
 *
 * <p>Chrome starts every renderer with
 * {@code Context.bindIsolatedService(intent, flags, instanceName, executor, conn)} against one
 * of its 40 {@code SandboxedProcessService0..39} declarations, each of which is
 * {@code android:isolatedProcess="true"}. Inside a Duplika container that produced:
 *
 * <pre>
 * IllegalArgumentException: Can't use instance name '0' with non-isolated
 *     non-sdk sandbox service 'top.niunaijun.blackbox.proxy.ProxyService$P1'
 * </pre>
 *
 * <p>This probe issues that same call shape and nothing else. No Chrome, no GMS, no account,
 * no credentials, no permissions. Run the same APK on the host and cloned, and compare.
 *
 * <p>Four cells are measured, so a failure can be attributed precisely:
 *
 * <ol>
 *   <li><b>P1</b> {@code bindIsolatedService} on an isolated service <b>with</b> an instance
 *       name — Chrome's exact shape, and the one expected to fail in a container;</li>
 *   <li><b>P2</b> {@code bindService} on the same isolated service, <b>no</b> instance name —
 *       isolates "isolated service" from "instance name";</li>
 *   <li><b>P3</b> {@code bindIsolatedService} on a <b>non-isolated</b> service with an instance
 *       name — what the platform itself refuses, so it shows the rule is the platform's;</li>
 *   <li><b>P4</b> {@code bindService} on the non-isolated service — the plain control.</li>
 * </ol>
 *
 * <p>Nothing here bypasses anything: it only asks the framework to do ordinary binds and
 * records the answers.
 */
public class MainActivity extends Activity {

    private static final String TAG = "Duplika.IsoSvc";
    private static final long WAIT_MS = 6000;

    private static final Pattern VIRTUAL_USER =
            Pattern.compile("/(?:blackbox|virtual)/(?:data/)?user/(\\d+)/");

    private final List<String> lines = new ArrayList<>();
    private final Executor executor = Executors.newSingleThreadExecutor();

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);

        header();
        bindIsolated(IsoService.class, "0", "P1", "isolated service + instance name (CHROME'S SHAPE)");
        bindPlain(IsoService.class, "P2", "isolated service, no instance name");
        bindIsolated(PlainService.class, "0", "P3", "NON-isolated service + instance name (platform refuses this)");
        bindPlain(PlainService.class, "P4", "non-isolated service, no instance name (control)");
        line("");
        line("=============== RUN COMPLETE ===============");

        TextView view = new TextView(this);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
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

        line("========== ISOLATED SERVICE BIND PROBE ==========");
        line("package=" + getPackageName());
        line("uid=" + Process.myUid() + " pid=" + Process.myPid());
        line("virtualized=" + virtualized
                + " virtualUserId=" + (virtualized ? m.group(1) : "n/a (host installation)"));
        line("device=" + Build.MANUFACTURER + " " + Build.MODEL
                + " android=" + Build.VERSION.RELEASE + " api=" + Build.VERSION.SDK_INT);
        line("buildType=" + (BuildConfig.DEBUG ? "debug" : "release"));
    }

    /** {@code bindIsolatedService} — the call Chrome makes for every renderer. */
    private void bindIsolated(Class<?> svc, String instanceName, String id, String what) {
        line("");
        line("---- " + id + ": bindIsolatedService(" + svc.getSimpleName()
                + ", instanceName=\"" + instanceName + "\") ----");
        line("     " + what);
        Intent intent = new Intent(this, svc);
        final CountDownLatch connected = new CountDownLatch(1);
        final String[] connectedTo = new String[1];
        ServiceConnection conn = connection(connected, connectedTo);
        long started = System.currentTimeMillis();
        try {
            boolean accepted = bindIsolatedService(
                    intent, Context.BIND_AUTO_CREATE, instanceName, executor, conn);
            report(id, accepted, connected, connectedTo, started, conn);
        } catch (Throwable e) {
            threw(id, e, System.currentTimeMillis() - started);
        }
    }

    /** Plain {@code bindService} on the same component, for contrast. */
    private void bindPlain(Class<?> svc, String id, String what) {
        line("");
        line("---- " + id + ": bindService(" + svc.getSimpleName() + ") ----");
        line("     " + what);
        Intent intent = new Intent(this, svc);
        final CountDownLatch connected = new CountDownLatch(1);
        final String[] connectedTo = new String[1];
        ServiceConnection conn = connection(connected, connectedTo);
        long started = System.currentTimeMillis();
        try {
            // The Executor overload matters: plain bindService(Intent, conn, flags) delivers
            // onServiceConnected on the main thread, which this probe is blocking while it
            // waits — that would report a false "never connected" for a bind that worked.
            boolean accepted = bindService(intent, Context.BIND_AUTO_CREATE, executor, conn);
            report(id, accepted, connected, connectedTo, started, conn);
        } catch (Throwable e) {
            threw(id, e, System.currentTimeMillis() - started);
        }
    }

    private ServiceConnection connection(CountDownLatch latch, String[] sink) {
        return new ServiceConnection() {
            @Override public void onServiceConnected(ComponentName name, IBinder service) {
                sink[0] = String.valueOf(name);
                latch.countDown();
            }
            @Override public void onServiceDisconnected(ComponentName name) { }
        };
    }

    /**
     * A {@code true} return only means the request was accepted. The bind has actually
     * succeeded when {@code onServiceConnected} fires, so both are recorded — a bind that is
     * accepted and then never connects is exactly the "button does nothing" shape.
     */
    private void report(String id, boolean accepted, CountDownLatch connected,
                        String[] connectedTo, long started, ServiceConnection conn) {
        boolean arrived = false;
        try {
            arrived = connected.await(WAIT_MS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException ignored) {
            Thread.currentThread().interrupt();
        }
        long ms = System.currentTimeMillis() - started;
        line("RESULT: accepted=" + accepted + " connected=" + arrived
                + (arrived ? " component=" + connectedTo[0] : "") + " in " + ms + " ms");
        if (accepted && !arrived) {
            line("  NOTE: request accepted but the service never connected within "
                    + WAIT_MS + " ms — a silent failure, not an exception.");
        }
        try {
            unbindService(conn);
        } catch (Throwable ignored) {
            // Nothing to learn from an unbind of a bind that never took.
        }
    }

    private void threw(String id, Throwable e, long ms) {
        line("RESULT: THREW after " + ms + " ms");
        line("  " + e.getClass().getName() + ": " + e.getMessage());
        StackTraceElement[] trace = e.getStackTrace();
        for (int i = 0; i < Math.min(5, trace.length); i++) {
            line("  at " + trace[i]);
        }
        Log.e(TAG, id + " threw", e);
    }

    private void line(String text) {
        lines.add(text);
        Log.i(TAG, text);
    }
}
