package com.example.duplikaladder.level9gms;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.pm.ServiceInfo;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * TEST C — intent resolution and a real service bind against Play services.
 *
 * <p>Test A asks whether the package is visible; this asks whether its components are
 * reachable, which is a different layer and can fail on its own. The two are kept apart
 * so that a failure can be classified as package visibility (Category A/B) rather than
 * intent resolution (C) or binding (D/E) by looking at which one broke.
 *
 * <p>Binding to an exported Play services entry point is what every Google client library
 * does; this only does it directly and reports the answer. No permission or signature
 * check is circumvented — if the platform or GMS refuses the bind, the refusal is the
 * result.
 */
final class TestCServiceResolution {

    /**
     * Public, exported entry points that GMS has advertised for years. They are probed as
     * a set rather than singly because any one of them can be absent on a given GMS
     * build, and "this specific action is gone" is a much weaker signal than "no action
     * resolves at all".
     */
    private static final String[] ACTIONS = {
            "com.google.android.gms.auth.api.signin.service.START",
            "com.google.android.gms.auth.service.START",
            "com.google.android.gms.common.service.START",
            "com.google.android.gms.measurement.START",
            "com.google.android.c2dm.intent.REGISTER",
    };

    private static final long BIND_TIMEOUT_MS = 8000;

    private TestCServiceResolution() {
    }

    interface Listener {
        void onFinished(TestResult result);
    }

    static void run(Context context, Listener listener) {
        DiagLog.section("TEST C — GMS service resolution and bind");
        StringBuilder detail = new StringBuilder();
        PackageManager pm = context.getPackageManager();

        int declaredServices = describeDeclaredServices(pm, detail);
        Intent bindTarget = resolveFirstBindableAction(pm, detail);

        if (bindTarget == null) {
            String summary = declaredServices > 0
                    ? "GMS package readable but no probed action resolved to a service"
                    : "no GMS service resolved and no service list readable";
            DiagLog.line(DiagLog.TAG_SERVICE, "TEST C verdict=FAIL (" + summary + ")");
            listener.onFinished(TestResult.of("C", "GMS service resolution", Verdict.FAIL,
                    summary, detail.toString()));
            return;
        }

        attemptBind(context, bindTarget, detail, listener);
    }

    /**
     * Reading GMS's own service list is a second, independent view of the same question.
     * It can succeed while intent resolution fails (or the reverse), and that split is
     * what separates a PackageManager virtualization problem from an intent-resolution
     * one.
     */
    private static int describeDeclaredServices(PackageManager pm, StringBuilder detail) {
        try {
            PackageInfo info = pm.getPackageInfo(
                    TestAPackageDetection.GMS, PackageManager.GET_SERVICES);
            ServiceInfo[] services = info.services;
            int count = services == null ? 0 : services.length;
            int exported = 0;
            if (services != null) {
                for (ServiceInfo service : services) {
                    if (service.exported) {
                        exported++;
                    }
                }
            }
            detail.append("GET_SERVICES on GMS: ").append(count)
                    .append(" declared, ").append(exported).append(" exported\n");
            DiagLog.line(DiagLog.TAG_SERVICE, "GMS declared services=" + count + " exported=" + exported);
            return count;
        } catch (PackageManager.NameNotFoundException e) {
            detail.append("GET_SERVICES on GMS: NameNotFoundException\n");
            DiagLog.failure(DiagLog.TAG_SERVICE, "GET_SERVICES on GMS failed", e);
            return 0;
        } catch (RuntimeException e) {
            detail.append("GET_SERVICES on GMS: ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_SERVICE, "GET_SERVICES on GMS threw", e);
            return 0;
        }
    }

    private static Intent resolveFirstBindableAction(PackageManager pm, StringBuilder detail) {
        Intent chosen = null;
        for (String action : ACTIONS) {
            Intent intent = new Intent(action).setPackage(TestAPackageDetection.GMS);
            try {
                List<ResolveInfo> matches = pm.queryIntentServices(intent, 0);
                int count = matches == null ? 0 : matches.size();
                detail.append("queryIntentServices ").append(action)
                        .append(" -> ").append(count).append('\n');
                DiagLog.line(DiagLog.TAG_INTENT, "queryIntentServices action=" + action
                        + " matches=" + count);
                if (count > 0) {
                    ServiceInfo service = matches.get(0).serviceInfo;
                    detail.append("  -> ").append(service.packageName).append('/')
                            .append(service.name).append(" exported=").append(service.exported)
                            .append(" permission=").append(service.permission).append('\n');
                    DiagLog.line(DiagLog.TAG_INTENT, "resolved component="
                            + service.packageName + "/" + service.name
                            + " exported=" + service.exported + " permission=" + service.permission);
                    if (chosen == null && service.exported) {
                        chosen = new Intent(action)
                                .setComponent(new ComponentName(service.packageName, service.name));
                    }
                }
            } catch (RuntimeException e) {
                detail.append("queryIntentServices ").append(action).append(": ")
                        .append(e.getClass().getName()).append('\n');
                DiagLog.failure(DiagLog.TAG_INTENT, "queryIntentServices failed for " + action, e);
            }
        }
        return chosen;
    }

    /**
     * A bind that is never answered is its own finding, so the attempt is bounded by a
     * timeout rather than left to hang. {@code bindService} returning true only means the
     * request was accepted; the callback is what proves a binder actually crossed.
     */
    private static void attemptBind(Context context, Intent target, StringBuilder detail,
                                    Listener listener) {
        ComponentName component = target.getComponent();
        detail.append("bind target: ").append(component).append('\n');
        DiagLog.line(DiagLog.TAG_BINDER, "attempting bindService to " + component);

        Handler handler = new Handler(Looper.getMainLooper());
        AtomicBoolean settled = new AtomicBoolean(false);

        ServiceConnection connection = new ServiceConnection() {
            @Override public void onServiceConnected(ComponentName name, IBinder service) {
                if (!settled.compareAndSet(false, true)) {
                    return;
                }
                String descriptor;
                try {
                    descriptor = service.getInterfaceDescriptor();
                } catch (Exception e) {
                    descriptor = "unavailable (" + e.getClass().getSimpleName() + ")";
                }
                detail.append("onServiceConnected: binder=").append(service)
                        .append(" descriptor=").append(descriptor).append('\n');
                DiagLog.line(DiagLog.TAG_BINDER, "onServiceConnected component=" + name
                        + " descriptor=" + descriptor);
                unbindQuietly(context, this);
                finish(listener, Verdict.PASS,
                        "bound to " + name.getShortClassName() + " and received a binder", detail);
            }

            @Override public void onServiceDisconnected(ComponentName name) {
                DiagLog.line(DiagLog.TAG_BINDER, "onServiceDisconnected component=" + name);
            }

            @Override public void onNullBinding(ComponentName name) {
                if (!settled.compareAndSet(false, true)) {
                    return;
                }
                // The service accepted the bind and deliberately returned no interface.
                // The binder path works; this particular entry point just declines.
                detail.append("onNullBinding: service accepted the bind but returned no binder\n");
                DiagLog.line(DiagLog.TAG_BINDER, "onNullBinding component=" + name);
                unbindQuietly(context, this);
                finish(listener, Verdict.PARTIAL,
                        "bind accepted, service returned a null binder", detail);
            }
        };

        boolean requested;
        try {
            requested = context.bindService(target, connection, Context.BIND_AUTO_CREATE);
        } catch (SecurityException e) {
            settled.set(true);
            detail.append("bindService threw SecurityException: ").append(e.getMessage()).append('\n');
            DiagLog.failure(DiagLog.TAG_BINDER, "bindService SecurityException", e);
            finish(listener, Verdict.FAIL, "bindService threw SecurityException", detail);
            return;
        } catch (RuntimeException e) {
            settled.set(true);
            detail.append("bindService threw ").append(e.getClass().getName()).append('\n');
            DiagLog.failure(DiagLog.TAG_BINDER, "bindService threw", e);
            finish(listener, Verdict.FAIL, "bindService threw " + e.getClass().getSimpleName(), detail);
            return;
        }

        detail.append("bindService returned ").append(requested).append('\n');
        DiagLog.line(DiagLog.TAG_BINDER, "bindService returned " + requested);
        if (!requested) {
            settled.set(true);
            unbindQuietly(context, connection);
            finish(listener, Verdict.FAIL, "bindService returned false", detail);
            return;
        }

        handler.postDelayed(() -> {
            if (!settled.compareAndSet(false, true)) {
                return;
            }
            detail.append("no connection callback within ").append(BIND_TIMEOUT_MS).append(" ms\n");
            DiagLog.line(DiagLog.TAG_BINDER, "bind timed out after " + BIND_TIMEOUT_MS + " ms");
            unbindQuietly(context, connection);
            finish(listener, Verdict.FAIL,
                    "bind accepted but no callback within " + BIND_TIMEOUT_MS + " ms", detail);
        }, BIND_TIMEOUT_MS);
    }

    private static void unbindQuietly(Context context, ServiceConnection connection) {
        try {
            context.unbindService(connection);
        } catch (IllegalArgumentException | IllegalStateException e) {
            DiagLog.line(DiagLog.TAG_BINDER, "unbindService ignored: " + e.getClass().getSimpleName());
        }
    }

    private static void finish(Listener listener, Verdict verdict, String summary,
                               StringBuilder detail) {
        DiagLog.line(DiagLog.TAG_SERVICE, "TEST C verdict=" + verdict + " (" + summary + ")");
        listener.onFinished(TestResult.of("C", "GMS service resolution", verdict, summary,
                detail.toString()));
    }
}
