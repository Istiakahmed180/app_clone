package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.PurchasesUpdatedListener;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * P16 — Play Billing service connection.
 *
 * <p>Included because it is the only probe in this fixture that talks to a
 * <em>different host application</em>. Everything else here binds
 * {@code com.google.android.gms}; Play Billing binds the Play Store,
 * {@code com.android.vending}, over its own AIDL interface. That makes it an independent
 * test of whether the container's service routing and package visibility work for a second
 * Google host app, rather than a fourth confirmation of the same path.
 *
 * <p>It is also the natural place to look for a <em>second</em> caller-identity boundary.
 * Play Billing is inherently identity-bound — purchases belong to an app and an account —
 * so the interesting question is at which layer that identity is demanded: at connection,
 * or later at query/purchase time. This probe answers only the first half, deliberately.
 *
 * <h2>Scope — connection only</h2>
 *
 * <p>{@code startConnection} is called and the resulting {@link BillingResult} recorded.
 * <b>No purchase flow is launched, no product is queried against a real SKU list, no
 * purchase is acknowledged or consumed, and nothing is faked.</b> A billing response code is
 * a fact reported by the Play Store; this probe records it and stops. There is no purchase
 * UI anywhere in this fixture and no code path that could complete one.
 *
 * <p>{@code isFeatureSupported} is additionally read because it is a pure capability query
 * that costs nothing and distinguishes "connected but degraded" from "connected".
 */
final class ProbeBilling {

    private static final long CONNECT_TIMEOUT_MS = 15_000;

    private ProbeBilling() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P16 — Play Billing connection (connection only; no purchase flow)");
        StringBuilder detail = new StringBuilder();

        // Required by the builder, and never invoked: nothing in this fixture starts a
        // purchase, so there is no update to receive.
        PurchasesUpdatedListener noPurchases = (billingResult, purchases) ->
                DiagLog.line(DiagLog.TAG, "P16 unexpected purchases callback — ignored");

        BillingClient client;
        try {
            client = BillingClient.newBuilder(context)
                    .setListener(noPurchases)
                    .enablePendingPurchases(
                            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                    .build();
        } catch (Throwable e) {
            String message = "BillingClient.newBuilder threw "
                    + e.getClass().getSimpleName() + ": " + e.getMessage();
            DiagLog.line(DiagLog.TAG, "P16 " + message);
            detail.append(message).append('\n');
            return finish(Verdict.FAIL, "billing client could not be constructed", detail);
        }
        detail.append("BillingClient constructed = ").append(client.getClass().getName()).append('\n');

        AtomicReference<String> setupResult = new AtomicReference<>("no callback within timeout");
        CountDownLatch latch = new CountDownLatch(1);
        try {
            client.startConnection(new BillingClientStateListener() {
                @Override public void onBillingSetupFinished(BillingResult result) {
                    setupResult.set("responseCode=" + result.getResponseCode()
                            + " (" + describe(result.getResponseCode()) + ")"
                            + " debugMessage=\"" + result.getDebugMessage() + "\"");
                    latch.countDown();
                }

                @Override public void onBillingServiceDisconnected() {
                    // Only meaningful after a successful connection; the probe has its
                    // answer by then and does not retry.
                    DiagLog.line(DiagLog.TAG, "P16 onBillingServiceDisconnected");
                }
            });
        } catch (Throwable e) {
            setupResult.set("startConnection threw "
                    + e.getClass().getSimpleName() + ": " + e.getMessage());
            latch.countDown();
        }

        try {
            latch.await(CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        String setup = setupResult.get();
        DiagLog.line(DiagLog.TAG, "P16 startConnection -> " + setup);
        detail.append("startConnection           = ").append(setup).append('\n');

        boolean connected = setup.startsWith("responseCode=0");
        detail.append("isReady                   = ").append(safeIsReady(client)).append('\n');

        if (connected) {
            String subscriptions = featureSupported(client, BillingClient.FeatureType.SUBSCRIPTIONS);
            DiagLog.line(DiagLog.TAG, "P16 isFeatureSupported(SUBSCRIPTIONS) -> " + subscriptions);
            detail.append("isFeatureSupported(SUBS)  = ").append(subscriptions).append('\n');
        }

        detail.append("purchase flow             = NOT ATTEMPTED (no such code path exists here)\n");

        try {
            client.endConnection();
        } catch (Throwable ignored) {
            // Tearing down a connection that never established throws; not part of the
            // measurement.
        }

        detail.append('\n').append("READING\n");
        if (connected) {
            DiagLog.line(DiagLog.TAG, "P16 the Play Store accepted a billing connection from"
                    + " this caller. Connection is not entitlement: whether a purchase or"
                    + " ownership query would be attributed correctly is NOT tested here.");
            detail.append("The Play Store accepted a billing connection from this caller.\n");
            detail.append("Note the limit of that claim: establishing a connection is not the\n");
            detail.append("same as being able to transact. Purchase and ownership queries are\n");
            detail.append("account- and app-attributed and are NOT tested by this probe.\n");
            return finish(Verdict.PASS, "Play Store accepted a billing connection", detail);
        }
        detail.append("No billing connection. The response code above is the Play Store's own\n");
        detail.append("answer and is recorded verbatim rather than interpreted.\n");
        return finish(Verdict.FAIL, "no billing connection: " + setup, detail);
    }

    private static String safeIsReady(BillingClient client) {
        try {
            return String.valueOf(client.isReady());
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName();
        }
    }

    private static String featureSupported(BillingClient client, String feature) {
        try {
            BillingResult result = client.isFeatureSupported(feature);
            return "responseCode=" + result.getResponseCode()
                    + " (" + describe(result.getResponseCode()) + ")";
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    /** The documented billing response codes, so a log line needs no lookup table. */
    private static String describe(int code) {
        switch (code) {
            case BillingClient.BillingResponseCode.OK: return "OK";
            case BillingClient.BillingResponseCode.USER_CANCELED: return "USER_CANCELED";
            case BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE: return "SERVICE_UNAVAILABLE";
            case BillingClient.BillingResponseCode.BILLING_UNAVAILABLE: return "BILLING_UNAVAILABLE";
            case BillingClient.BillingResponseCode.ITEM_UNAVAILABLE: return "ITEM_UNAVAILABLE";
            case BillingClient.BillingResponseCode.DEVELOPER_ERROR: return "DEVELOPER_ERROR";
            case BillingClient.BillingResponseCode.ERROR: return "ERROR";
            case BillingClient.BillingResponseCode.SERVICE_DISCONNECTED: return "SERVICE_DISCONNECTED";
            case BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED: return "FEATURE_NOT_SUPPORTED";
            case BillingClient.BillingResponseCode.NETWORK_ERROR: return "NETWORK_ERROR";
            default: return "code " + code;
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P16 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P16", "Play Billing connection", verdict, summary, detail.toString());
    }
}
