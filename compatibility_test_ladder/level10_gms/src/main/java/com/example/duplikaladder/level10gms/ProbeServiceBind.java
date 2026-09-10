package com.example.duplikaladder.level10gms;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * P10 — can the guest actually <em>bind</em> each API's service?
 *
 * <p>This probe exists because of a reading of the evidence that had not been tested. The
 * refusal was characterised as "pre-IPC" from two observations: it takes 1-20 ms, and Play
 * services' broker log shows no bind. But there is a second state that produces exactly
 * those two symptoms — <b>a {@code bindService} that returns {@code false}</b>. It is
 * synchronous (so: milliseconds), and it never reaches the target process (so: nothing in
 * the broker log). "Decided before any IPC" and "attempted a bind that was refused by the
 * local ActivityManager" are indistinguishable from outside, and they have opposite
 * consequences: the first is a client-library policy decision, the second is a
 * virtualization defect in service routing or package visibility.
 *
 * <p>So the probe stops inferring and binds the services directly, with a plain
 * {@code Context.bindService} that involves no Google client library at all. For each API
 * it records the three things that distinguish the cases:
 *
 * <ol>
 *   <li>the boolean {@code bindService} returned — {@code false} means the local
 *       ActivityManager refused before any IPC;</li>
 *   <li>whether {@code onServiceConnected} actually fired, and what binder interface came
 *       back — the only proof the bind completed end to end;</li>
 *   <li>any exception, which is where a {@code SecurityException} would surface.</li>
 * </ol>
 *
 * <p>The controls are the point: P1's AdvertisingId service and P2's AppSet API both work
 * in a guest, so if the failing APIs' services bind here just as readily, service binding
 * is excluded and the decision really is the client library's own. If they do not bind,
 * the cause is local and mechanical.
 *
 * <p><b>Read-only.</b> Binding a service and immediately unbinding performs no operation on
 * it — no AIDL transaction is issued, nothing is requested, nothing is modified. No
 * identity is altered or asserted: these are the ordinary binds the app's own client
 * libraries would make on its behalf.
 */
final class ProbeServiceBind {

    private static final String GMS = "com.google.android.gms";

    /** How long to wait for {@code onServiceConnected} after a bind that returned true. */
    private static final long CONNECT_TIMEOUT_MS = 4000;

    /**
     * Each API's real service action, paired with its known guest outcome so the table
     * reads as the comparison it is. Actions are the ones P6 corrected in Phase 8 and P9
     * re-verified against the device.
     */
    private static final String[][] TARGETS = {
            { "LocationServices (GoogleApi FAILS in guest)",
              "com.google.android.location.internal.GoogleLocationManagerService.START" },
            { "SmsRetriever (GoogleApi FAILS in guest)",
              "com.google.android.gms.auth.api.phone.service.SmsRetrieverApiService.START" },
            { "GMS common — the framework's own entry point",
              "com.google.android.gms.common.service.START" },
            { "AdvertisingId (CONTROL: works in guest)",
              "com.google.android.gms.ads.identifier.service.START" },
    };

    private ProbeServiceBind() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P10 — direct service bind (is the bind itself refused?)");
        StringBuilder detail = new StringBuilder();

        int bound = 0;
        int attempted = 0;
        boolean locationBound = false;
        boolean controlBound = false;

        for (String[] target : TARGETS) {
            attempted++;
            BindOutcome outcome = bind(context, target[1]);
            DiagLog.line(DiagLog.TAG_BINDER, "P10 " + target[1] + " -> " + outcome);
            detail.append(target[0]).append('\n')
                    .append("  action=").append(target[1]).append('\n')
                    .append("  ").append(outcome).append('\n');
            if (outcome.connected) {
                bound++;
                if (target[1].contains("GoogleLocationManagerService")) {
                    locationBound = true;
                }
                if (target[1].contains("ads.identifier")) {
                    controlBound = true;
                }
            }
        }

        detail.append('\n').append("READING\n");
        detail.append("bound ").append(bound).append(" of ").append(attempted).append('\n');

        Verdict verdict;
        String summary;
        if (locationBound && controlBound) {
            // The failing API's own service binds fine. Service routing, package visibility
            // and Binder forwarding are therefore all excluded as the cause, and the
            // DEVELOPER_ERROR is genuinely the client library's own decision.
            DiagLog.line(DiagLog.TAG, "P10 CONCLUSION: the service behind a FAILING GoogleApi"
                    + " binds successfully from this process. Service routing, package"
                    + " visibility and Binder forwarding are excluded; the refusal is the"
                    + " client library's own local decision, not a blocked bind.");
            detail.append("The failing API's service binds. Bind refusal is EXCLUDED as the cause.\n");
            verdict = Verdict.PASS;
            summary = "failing API's service binds; bind refusal excluded";
        } else if (!locationBound && controlBound) {
            DiagLog.line(DiagLog.TAG, "P10 LEAD: the control service binds but the FAILING"
                    + " API's service does not. The refusal is a local bind failure, which is"
                    + " a virtualization defect (service routing / package visibility), not a"
                    + " client-library policy decision.");
            detail.append("LEAD: control binds, failing API's service does not.\n");
            verdict = Verdict.FAIL;
            summary = "failing API's service will not bind; control does";
        } else {
            verdict = Verdict.PARTIAL;
            summary = "mixed bind results; see detail";
        }

        DiagLog.line(DiagLog.TAG, "P10 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P10", "Direct service bind", verdict, summary, detail.toString());
    }

    /**
     * Binds one action and waits for the connection callback.
     *
     * <p>The wait is what makes the result trustworthy. {@code bindService} returning
     * {@code true} only means the request was accepted for dispatch; the bind can still
     * fail afterwards, and a probe that recorded the boolean alone would report a success
     * that never happened.
     */
    private static BindOutcome bind(Context context, String action) {
        final CountDownLatch latch = new CountDownLatch(1);
        final AtomicReference<String> descriptor = new AtomicReference<>("none");
        ServiceConnection connection = new ServiceConnection() {
            @Override public void onServiceConnected(ComponentName name, IBinder service) {
                String value;
                try {
                    value = service == null ? "null binder" : String.valueOf(service.getInterfaceDescriptor());
                } catch (Throwable e) {
                    value = "descriptor threw " + e.getClass().getSimpleName();
                }
                descriptor.set(value);
                latch.countDown();
            }

            @Override public void onServiceDisconnected(ComponentName name) {
                // Not part of the measurement: the probe unbinds as soon as it has its answer.
            }
        };

        boolean requested = false;
        String error = "none";
        try {
            Intent intent = new Intent(action).setPackage(GMS);
            requested = context.bindService(intent, connection, Context.BIND_AUTO_CREATE);
        } catch (Throwable e) {
            error = e.getClass().getSimpleName() + ": " + e.getMessage();
        }

        boolean connected = false;
        if (requested) {
            try {
                connected = latch.await(CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        try {
            context.unbindService(connection);
        } catch (Throwable ignored) {
            // Unbinding a bind that never completed throws; not part of the measurement.
        }
        return new BindOutcome(requested, connected, descriptor.get(), error);
    }

    /** One bind attempt's three-part answer, formatted identically in both runs. */
    private static final class BindOutcome {
        final boolean requested;
        final boolean connected;
        final String descriptor;
        final String error;

        BindOutcome(boolean requested, boolean connected, String descriptor, String error) {
            this.requested = requested;
            this.connected = connected;
            this.descriptor = descriptor;
            this.error = error;
        }

        @Override public String toString() {
            return "bindService=" + requested
                    + " onServiceConnected=" + connected
                    + " interface=" + descriptor
                    + " exception=" + error;
        }
    }
}
