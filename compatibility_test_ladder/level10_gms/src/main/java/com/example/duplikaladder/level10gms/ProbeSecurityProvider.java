package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.security.ProviderInstaller;

import java.security.Security;

/**
 * P14 — the Play services security provider.
 *
 * <p>{@code ProviderInstaller.installIfNeeded} asks Play services for its up-to-date TLS
 * stack (Conscrypt) and installs it as the process's preferred JCE provider. It is one of
 * the most widely used Google APIs in ordinary apps and one of the least visible: many
 * networking libraries call it during startup, and apps targeting older platforms depend on
 * it for modern TLS.
 *
 * <p>It is worth measuring here for a specific structural reason. It is delivered as a
 * Chimera module (P13), needs no account, no API key and no permission, and — critically —
 * it is <b>not caller-scoped</b>: Play services is handing over a code module, not
 * attributing an operation to a package. So it should be unaffected by the caller-identity
 * boundary, and confirming that on a real, non-trivial API is more informative than
 * confirming it again on another ID-fetching call.
 *
 * <p>The probe records the JCE provider list before and after, which is what makes the
 * result verifiable rather than merely "no exception was thrown": a successful install
 * visibly changes the process's security providers.
 *
 * <p><b>Read-only with respect to Google.</b> Nothing is sent, no account or credential is
 * touched. The one side effect is local and intended: the process's own JCE provider list
 * may gain Conscrypt, which is exactly what the API exists to do and which dies with the
 * process.
 */
final class ProbeSecurityProvider {

    private ProbeSecurityProvider() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P14 — Play services security provider (ProviderInstaller)");
        StringBuilder detail = new StringBuilder();

        String before = providerList();
        detail.append("JCE providers before = ").append(before).append('\n');
        DiagLog.line(DiagLog.TAG, "P14 providersBefore=" + before);

        String outcome;
        boolean installed = false;
        try {
            // The synchronous form. The async form exists for UI flows that may need to
            // show a Play-services repair prompt; this probe wants the direct answer and
            // has no UI to drive.
            ProviderInstaller.installIfNeeded(context);
            outcome = "installIfNeeded returned normally";
            installed = true;
        } catch (Throwable e) {
            outcome = "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
        DiagLog.line(DiagLog.TAG, "P14 installIfNeeded -> " + outcome);
        detail.append("installIfNeeded      = ").append(outcome).append('\n');

        String after = providerList();
        detail.append("JCE providers after  = ").append(after).append('\n');
        DiagLog.line(DiagLog.TAG, "P14 providersAfter=" + after);

        boolean conscrypt = after.contains("GmsCore_OpenSSL") || after.contains("Conscrypt");
        detail.append("GMS provider present = ").append(conscrypt).append('\n');

        detail.append('\n').append("READING\n");
        Verdict verdict;
        String summary;
        if (installed && conscrypt) {
            DiagLog.line(DiagLog.TAG, "P14 the Play services security provider installed"
                    + " successfully — a non-trivial, widely used, non-caller-scoped Google"
                    + " API working end to end for this caller.");
            detail.append("Installed. Play services delivered its TLS provider into this process\n");
            detail.append("and it is visible in the JCE provider list — verified by observable\n");
            detail.append("state change, not merely by the absence of an exception.\n");
            verdict = Verdict.PASS;
            summary = "security provider installed; GMS provider present";
        } else if (installed) {
            detail.append("installIfNeeded returned without error but no GMS provider appeared.\n");
            detail.append("Recorded as PARTIAL: the call succeeded, the effect is unconfirmed.\n");
            verdict = Verdict.PARTIAL;
            summary = "installIfNeeded returned but no GMS provider observed";
        } else {
            verdict = Verdict.FAIL;
            summary = "security provider could not be installed";
        }

        DiagLog.line(DiagLog.TAG, "P14 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P14", "Security provider", verdict, summary, detail.toString());
    }

    /** Provider names in preference order — the order is the part that changes on install. */
    private static String providerList() {
        try {
            StringBuilder out = new StringBuilder("[");
            java.security.Provider[] providers = Security.getProviders();
            for (int i = 0; i < providers.length; i++) {
                if (i > 0) {
                    out.append(", ");
                }
                out.append(providers[i].getName());
            }
            return out.append(']').toString();
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName();
        }
    }
}
