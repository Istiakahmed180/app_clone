package com.example.duplikaladder.level9gms;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.Context;

/**
 * TEST F — does the virtualization layer inject fabricated Google accounts?
 *
 * <p>Added in the host-passthrough investigation, not the original Level 9 set. Reading the
 * engine's source showed it ships a {@code GoogleAccountManagerProxy} that can return two
 * hardcoded accounts, {@code mock.user@gmail.com} and {@code virtual.user@gmail.com}, and a
 * {@code GmsProxy} that can return a mock auth result. Both look inert — their injection
 * hooks install nothing — but "looks inert when read" is not the same as "is inert when
 * run", and making Play services genuinely visible to a guest is exactly the change that
 * would start exercising those paths. So it is measured rather than assumed.
 *
 * <p>PASS means no fabricated account was observed. FAIL means the layer is spoofing a
 * Google identity, which would be a stop-everything result.
 *
 * <p>Privacy: this never logs an account name. Only a count, and whether any name matches
 * one of the two fabricated names compiled into the engine, are recorded. No permission is
 * requested — without {@code GET_ACCOUNTS} a real account list is normally empty, and that
 * is fine, because the fabrication being tested for is unconditional: were it active, the
 * mock accounts would be returned regardless of permission.
 */
final class TestFAccountIdentity {

    /** The two names hardcoded in the engine's GoogleAccountManagerProxy. */
    private static final String[] ENGINE_MOCK_NAMES = {
            "mock.user@gmail.com",
            "virtual.user@gmail.com",
    };

    private TestFAccountIdentity() {
    }

    static TestResult run(Context context) {
        DiagLog.section("TEST F — account identity (no fabricated Google account)");
        StringBuilder detail = new StringBuilder();
        detail.append("no GET_ACCOUNTS permission requested; counts only, never names\n");

        try {
            AccountManager manager = AccountManager.get(context);
            Account[] google = manager.getAccountsByType("com.google");
            int googleCount = google == null ? 0 : google.length;

            boolean fabricated = false;
            if (google != null) {
                for (Account account : google) {
                    for (String mock : ENGINE_MOCK_NAMES) {
                        if (mock.equals(account.name)) {
                            fabricated = true;
                        }
                    }
                }
            }

            detail.append("getAccountsByType(\"com.google\") count=").append(googleCount).append('\n')
                    .append("engine-fabricated account observed=").append(fabricated).append('\n');
            DiagLog.line(DiagLog.TAG_UID, "accountsByType(com.google) count=" + googleCount
                    + " fabricatedAccountObserved=" + fabricated);

            Verdict verdict = fabricated ? Verdict.FAIL : Verdict.PASS;
            String summary = fabricated
                    ? "the layer returned a fabricated Google account"
                    : "no fabricated Google account (" + googleCount + " real accounts visible)";
            DiagLog.line(DiagLog.TAG_UID, "TEST F verdict=" + verdict + " (" + summary + ")");
            return TestResult.of("F", "Account identity", verdict, summary, detail.toString());
        } catch (SecurityException e) {
            // A refusal is the honest platform behaviour and proves nothing was fabricated
            // in its place, which is the property under test.
            DiagLog.failure(DiagLog.TAG_UID, "account lookup refused", e);
            detail.append("SecurityException: ").append(e.getMessage()).append('\n');
            return TestResult.of("F", "Account identity", Verdict.PASS,
                    "account lookup refused by the platform; nothing fabricated", detail.toString());
        } catch (RuntimeException e) {
            DiagLog.failure(DiagLog.TAG_UID, "account lookup threw", e);
            detail.append("threw ").append(e.getClass().getName()).append('\n');
            return TestResult.of("F", "Account identity", Verdict.BLOCKED,
                    "account lookup threw " + e.getClass().getSimpleName(), detail.toString());
        }
    }
}
