package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.content.ContextWrapper;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.HasApiKey;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.Tasks;

import java.util.concurrent.TimeUnit;

/**
 * P11 — is the attribution package name the input the client library refuses on?
 *
 * <p>By P10 the field is nearly empty. Service routing, package visibility, Binder
 * forwarding, component resolution, permissions, provider state, GMS version, transport and
 * R8 are all measured and excluded, and P10 showed the guest can bind the very services
 * behind the failing APIs and get a real {@code IGmsServiceBroker} back. The client library
 * therefore <em>could</em> connect and chooses not to, from something it reads locally.
 *
 * <p>P9 found exactly two local inputs that differ between host and guest, and only one of
 * them is a value a client library would build a request from:
 *
 * <pre>
 *   host  : getOpPackageName() = com.example.duplikaladder.level10gms
 *   guest : getOpPackageName() = co.tdevs.duplika
 * </pre>
 *
 * <p>{@code getOpPackageName()} is the name the platform attributes an operation to. In a
 * guest it returns the <em>container host's</em> package, not the app's own — while
 * {@code getPackageName()} and {@code getPackagesForUid(myUid)} both say
 * {@code …level10gms}. A client library that composes a caller-attributed request from one
 * of those and validates it against the other sees a contradiction, and refusing locally
 * with {@code DEVELOPER_ERROR} is a reasonable thing to do about a contradiction. That
 * would also explain the otherwise odd per-API pattern: only APIs whose access must be
 * attributed to a caller build such a request at all, which is precisely the set that
 * fails.
 *
 * <p>This probe tests that hypothesis directly. It hands the same clients a
 * {@link ContextWrapper} whose <em>only</em> difference is that {@code getOpPackageName()}
 * returns {@link Context#getPackageName()}, and re-asks {@code checkApiAvailability}. If
 * availability flips, the input is identified. If it does not, the hypothesis is rejected
 * and the cause is something this probe still cannot see — which is reported as such rather
 * than narrowed by assertion.
 *
 * <h2>Why this is not identity spoofing</h2>
 *
 * <p>The wrapper makes this app report <b>its own real package name</b>,
 * {@code com.example.duplikaladder.level10gms} — the package it is actually running as, the
 * one {@code getPackageName()} already returns, and the one whose APK and signing
 * certificate are on the device. It replaces a <em>different</em> app's package name with
 * the true one. No other app is impersonated, no signature, certificate, UID or account is
 * altered or asserted, and nothing is hidden from Play services: the Binder calling UID it
 * observes is unchanged and still Duplika's.
 *
 * <p>The wrapper is also confined to this diagnostic fixture and is a measurement, not a
 * fix. A passing result here identifies an input; it does not by itself justify changing
 * production behaviour, because {@code getOpPackageName} is what the platform's own AppOps
 * accounting uses and it must correspond to the process's real UID for system calls to
 * succeed. That trade-off is analysed where a fix would be proposed, not here.
 */
final class ProbeAttributionContext {

    private ProbeAttributionContext() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P11 — attribution context experiment (is getOpPackageName the input?)");
        StringBuilder detail = new StringBuilder();

        String realPackage = context.getPackageName();
        String opPackage;
        try {
            opPackage = context.getOpPackageName();
        } catch (Throwable e) {
            opPackage = "threw " + e.getClass().getSimpleName();
        }
        DiagLog.line(DiagLog.TAG_UID, "P11 getPackageName=" + realPackage
                + " getOpPackageName=" + opPackage
                + " differ=" + !realPackage.equals(opPackage));
        detail.append("getPackageName    = ").append(realPackage).append('\n');
        detail.append("getOpPackageName  = ").append(opPackage).append('\n');
        detail.append("differ            = ").append(!realPackage.equals(opPackage)).append("\n\n");

        Context corrected = new SelfAttributedContext(context.getApplicationContext());

        detail.append("BASELINE (unmodified context)\n");
        String locationBefore = availability(
                LocationServices.getSettingsClient(context), "LocationServices baseline");
        String smsBefore = availability(
                SmsRetriever.getClient(context), "SmsRetriever baseline");
        detail.append("  LocationServices = ").append(locationBefore).append('\n');
        detail.append("  SmsRetriever     = ").append(smsBefore).append('\n');

        detail.append("\nCORRECTED (getOpPackageName returns this app's own package)\n");
        String locationAfter = availability(
                LocationServices.getSettingsClient(corrected), "LocationServices corrected");
        String smsAfter = availability(
                SmsRetriever.getClient(corrected), "SmsRetriever corrected");
        detail.append("  LocationServices = ").append(locationAfter).append('\n');
        detail.append("  SmsRetriever     = ").append(smsAfter).append('\n');

        boolean flipped = (!"available".equals(locationBefore) && "available".equals(locationAfter))
                || (!"available".equals(smsBefore) && "available".equals(smsAfter));
        boolean baselineAlreadyFine =
                "available".equals(locationBefore) && "available".equals(smsBefore);

        detail.append('\n').append("READING\n");
        Verdict verdict;
        String summary;
        if (baselineAlreadyFine) {
            // The host column. Nothing to flip; the run exists to prove the wrapper is inert
            // where the value was already correct, so a guest flip cannot be an artefact of
            // the wrapper itself.
            detail.append("Baseline already available (this is the host control). The wrapper\n");
            detail.append("changes nothing here, which is what makes a guest flip meaningful.\n");
            verdict = Verdict.PASS;
            summary = "host control: available before and after; wrapper is inert";
        } else if (flipped) {
            DiagLog.line(DiagLog.TAG, "P11 CONFIRMED: correcting getOpPackageName to this app's"
                    + " own package makes the refused APIs available. The input to the client"
                    + " library's local refusal is the attribution package name, which the"
                    + " container reports as the host's package instead of the guest's.");
            detail.append("CONFIRMED: the attribution package name is the input. The container\n");
            detail.append("reports the HOST's package from getOpPackageName() while every other\n");
            detail.append("identity read says the guest's; correcting it restores availability.\n");
            verdict = Verdict.PASS;
            summary = "CONFIRMED — getOpPackageName is the refused input";
        } else {
            DiagLog.line(DiagLog.TAG, "P11 REJECTED: correcting getOpPackageName does not restore"
                    + " availability. The attribution package name is not the input, and the"
                    + " cause remains unidentified.");
            detail.append("REJECTED: correcting the attribution package name changes nothing.\n");
            detail.append("The cause is something this probe cannot observe. Not narrowed further.\n");
            verdict = Verdict.FAIL;
            summary = "REJECTED — attribution package name is not the input";
        }

        DiagLog.line(DiagLog.TAG, "P11 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P11", "Attribution context experiment", verdict, summary,
                detail.toString());
    }

    private static String availability(HasApiKey<?> client, String label) {
        try {
            Tasks.await(GoogleApiAvailability.getInstance().checkApiAvailability(client),
                    8000, TimeUnit.MILLISECONDS);
            DiagLog.line(DiagLog.TAG, "P11 checkApiAvailability(" + label + ") = available");
            return "available";
        } catch (Throwable e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            String answer = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            DiagLog.line(DiagLog.TAG, "P11 checkApiAvailability(" + label + ") = " + answer);
            return answer;
        }
    }

    /**
     * The app's own context, reporting its own package name for attribution.
     *
     * <p>One override, nothing else delegated differently. Overriding
     * {@code getApplicationContext} to return {@code this} matters as much as the package
     * name: the Google client libraries immediately call it and would otherwise unwrap
     * straight back to the container's context, and the experiment would silently measure
     * the baseline twice.
     */
    private static final class SelfAttributedContext extends ContextWrapper {

        SelfAttributedContext(Context base) {
            super(base);
        }

        @Override public String getOpPackageName() {
            return getPackageName();
        }

        @Override public Context getApplicationContext() {
            return this;
        }
    }
}
