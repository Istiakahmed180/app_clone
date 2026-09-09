package com.example.duplikaladder.level10gms;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.content.Context;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;

/**
 * P5 — the account-bound boundary, observed WITHOUT attempting to cross it.
 *
 * <p>This probe exists to classify, not to fix. It makes two read-only observations and
 * then stops:
 *
 * <ol>
 *   <li>how many {@code com.google} accounts the guest can see, and whether any of them
 *       was fabricated by the engine (Level 9 found a {@code mock.user@gmail.com} pattern
 *       in some virtualization engines — a fake account is exactly the kind of thing this
 *       project refuses to ship, so it is checked for rather than assumed absent);</li>
 *   <li>whether a cached {@code GoogleSignInAccount} exists, via
 *       {@link GoogleSignIn#getLastSignedInAccount(Context)}, which is a local read of
 *       previously-granted state and performs no network call and no authentication.</li>
 * </ol>
 *
 * <p>What this probe deliberately does NOT do: no {@code signIn()}, no
 * {@code silentSignIn()}, no token request, no {@code GoogleAuthUtil.getToken}, no
 * interactive consent. Those would either attempt to authenticate a virtualized caller
 * that Play services has legitimately refused to validate, or require a token this
 * container cannot honestly obtain. Both are on the forbidden list.
 *
 * <p>The verdict is therefore {@code UNSUPPORTED} whenever no real account is present:
 * that is not a defect in Duplika and not a test that could be made to pass by fixing
 * something — Google account sign-in inside a third-party container needs an identity
 * guarantee the container cannot legitimately provide. It is recorded so the boundary is
 * explicit in the matrix rather than left looking like an untested gap.
 */
final class ProbeAccountBoundary {

    /** Fabricated-account markers seen in other virtualization engines. */
    private static final String[] FABRICATED_MARKERS = { "mock.user", "example.com", "test@test" };

    private ProbeAccountBoundary() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P5 — account-bound APIs (observed read-only, never attempted)");
        StringBuilder detail = new StringBuilder();
        detail.append("NOTE: no sign-in, no silentSignIn, no token request is performed here.\n");
        detail.append("Only read-only observations, then classification.\n\n");

        int googleAccounts = -1;
        boolean fabricatedSeen = false;
        try {
            // Without GET_ACCOUNTS this returns an empty array on modern Android rather
            // than throwing; either way the count is the observation, and no permission is
            // requested to obtain it.
            Account[] accounts = AccountManager.get(context).getAccountsByType("com.google");
            googleAccounts = accounts == null ? 0 : accounts.length;
            if (accounts != null) {
                for (Account account : accounts) {
                    String name = account.name == null ? "" : account.name.toLowerCase(java.util.Locale.US);
                    for (String marker : FABRICATED_MARKERS) {
                        if (name.contains(marker)) {
                            fabricatedSeen = true;
                        }
                    }
                }
            }
            // Account names are personal data and are never logged -- only the count and
            // the fabricated-marker verdict.
            DiagLog.line(DiagLog.TAG_UID, "accountsByType(com.google) count=" + googleAccounts
                    + " fabricatedAccountObserved=" + fabricatedSeen);
            detail.append("visible com.google accounts: ").append(googleAccounts).append('\n');
            detail.append("engine-fabricated account observed: ").append(fabricatedSeen).append('\n');
            detail.append("(account names are personal data and are not recorded)\n");
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG_UID, "account enumeration failed", e);
            detail.append("account enumeration threw ").append(e.getClass().getName()).append('\n');
        }

        boolean cachedSignIn = false;
        try {
            GoogleSignInAccount last = GoogleSignIn.getLastSignedInAccount(context);
            cachedSignIn = last != null;
            DiagLog.line(DiagLog.TAG, "getLastSignedInAccount present=" + cachedSignIn
                    + " (local read, no network, no authentication)");
            detail.append("cached GoogleSignInAccount present: ").append(cachedSignIn).append('\n');
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "getLastSignedInAccount threw", e);
            detail.append("getLastSignedInAccount threw ").append(e.getClass().getName()).append('\n');
        }

        detail.append('\n');
        detail.append("CLASSIFICATION\n");
        detail.append("Google account sign-in and any OAuth-token-bound Google API are\n");
        detail.append("UNSUPPORTED / SECURITY-BOUNDARY inside this container. Play services\n");
        detail.append("validates the calling package against the Binder calling UID, and in a\n");
        detail.append("container those do not correspond (see P4). Making them agree would be\n");
        detail.append("caller-identity spoofing. No attempt is made, and none should be.\n");

        if (fabricatedSeen) {
            // A fabricated account would be a serious problem in its own right, so it is a
            // FAIL of Duplika's own honesty rather than a Google boundary.
            DiagLog.line(DiagLog.TAG, "P5 verdict=FAIL (engine-fabricated Google account observed)");
            return TestResult.of("P5", "Account-bound APIs", Verdict.FAIL,
                    "an engine-fabricated Google account was observed", detail.toString());
        }
        if (googleAccounts > 0 || cachedSignIn) {
            // A real account is visible. That still does not mean sign-in works -- it means
            // the boundary cannot be classified from a no-account observation alone, and
            // testing further would require attempting authentication, which is refused.
            DiagLog.line(DiagLog.TAG, "P5 verdict=UNSUPPORTED (real account visible; sign-in not attempted)");
            return TestResult.of("P5", "Account-bound APIs", Verdict.UNSUPPORTED,
                    "real account visible; sign-in deliberately not attempted",
                    detail.toString());
        }
        DiagLog.line(DiagLog.TAG, "P5 verdict=UNSUPPORTED (no account; boundary not crossed)");
        return TestResult.of("P5", "Account-bound APIs", Verdict.UNSUPPORTED,
                "no Google account present and none fabricated — boundary, not a defect",
                detail.toString());
    }
}
