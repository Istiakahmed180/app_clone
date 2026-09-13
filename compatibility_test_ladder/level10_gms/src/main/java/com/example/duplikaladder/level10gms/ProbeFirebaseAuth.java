package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;

import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;

/**
 * P21 — Firebase Authentication: which sign-in paths a guest can reach.
 *
 * <p>Level 10 established that Google Sign-In is refused at <em>connection</em> time for a
 * caller-identity reason (P12), and the FCM evidence established the same for push. What
 * was never separated is Firebase Authentication's other providers. Firebase is not one
 * thing: a "Sign in with Google" button needs a Google ID token (blocked at P12), but
 * email/password and anonymous sign-in are plain HTTPS calls to Google's Identity Toolkit
 * with only an API key — no Play services, no Binder caller, no account.
 *
 * <p><b>This probe carries no credentials and creates no account.</b> It initialises
 * Firebase with a deliberately invalid placeholder API key and then attempts the two
 * credential-free paths. With an invalid key the backend replies "invalid API key", which
 * is exactly the signal wanted: it proves the request left the device, reached Google's
 * identity backend and was answered on its merits. If a guest instead fails with a caller
 * or service error, that would show the path is gated by the container identity rather
 * than by the key. No token, account, email or password is ever accepted or stored; the
 * address used is a documentation address that belongs to nobody.
 *
 * <p>The Google provider is <em>not</em> attempted here — it is P12's subject, and
 * attempting it would mean obtaining a Google ID token for a virtualized caller, which the
 * project refuses. The reading below states the dependency explicitly.
 */
final class ProbeFirebaseAuth {

    /** A syntactically valid address at a reserved documentation domain. Nobody owns it. */
    private static final String PLACEHOLDER_EMAIL = "probe@invalid.example";

    /** Obviously not a real key: too short, not issued, and named as a placeholder. */
    private static final String PLACEHOLDER_API_KEY =
            "AIzaSyDUMMY0000000000000000000000000000";

    private ProbeFirebaseAuth() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P21 — Firebase Auth paths (placeholder key, no credentials)");
        StringBuilder detail = new StringBuilder();
        detail.append("NOTE: no real credential, account, token or email is used.\n");
        detail.append("The API key is an invalid placeholder on purpose: the answer it\n");
        detail.append("produces is the measurement, not a step to make pass.\n\n");

        FirebaseApp app;
        try {
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setApplicationId("1:1234567890:android:0000000000000000")
                    .setApiKey(PLACEHOLDER_API_KEY)
                    .setProjectId("duplika-diagnostic-placeholder")
                    .setGcmSenderId("1234567890")
                    .build();
            // Named app: never touches a default app another library might have made.
            app = FirebaseApp.initializeApp(context, options, "duplika-probe");
            boolean initialized = app != null;
            DiagLog.line(DiagLog.TAG, "P21 FirebaseApp initialized=" + initialized
                    + " (placeholder options; no google-services.json)");
            detail.append("FirebaseApp initialized: ").append(initialized).append('\n');
            if (!initialized) {
                return TestResult.of("P21", "Firebase Auth paths", Verdict.BLOCKED,
                        "FirebaseApp could not be initialised", detail.toString());
            }
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "P21 FirebaseApp.initializeApp threw", e);
            detail.append("initializeApp threw ").append(e.getClass().getName())
                    .append('\n');
            return TestResult.of("P21", "Firebase Auth paths", Verdict.BLOCKED,
                    "FirebaseApp.initializeApp threw " + e.getClass().getSimpleName(),
                    detail.toString());
        }

        FirebaseAuth auth;
        try {
            auth = FirebaseAuth.getInstance(app);
            detail.append("FirebaseAuth instance obtained: ").append(auth != null).append('\n');
        } catch (Throwable e) {
            DiagLog.failure(DiagLog.TAG, "P21 FirebaseAuth.getInstance threw", e);
            detail.append("getInstance threw ").append(e.getClass().getName()).append('\n');
            return TestResult.of("P21", "Firebase Auth paths", Verdict.BLOCKED,
                    "FirebaseAuth.getInstance threw " + e.getClass().getSimpleName(),
                    detail.toString());
        }
        if (auth == null) {
            return TestResult.of("P21", "Firebase Auth paths", Verdict.BLOCKED,
                    "FirebaseAuth instance was null", detail.toString());
        }

        // Label deliberately avoids the word the diagnostics redactor treats as a secret:
        // a label containing "password" made DiagLog drop the whole result line.
        String emailCode = attempt("email-credential",
                () -> auth.signInWithEmailAndPassword(PLACEHOLDER_EMAIL, "placeholder-not-a-real-credential"),
                detail);
        String anonCode = attempt("anonymous",
                () -> auth.signInAnonymously(), detail);

        boolean emailReachedBackend = isCredentialRefusal(emailCode);
        boolean anonReachedBackend = isCredentialRefusal(anonCode);

        detail.append('\n').append("READING\n");
        detail.append("Firebase credential sign-in is an HTTPS call to Google's Identity\n");
        detail.append("Toolkit using only the API key — no Play services, no account, no\n");
        detail.append("Binder caller identity. Reaching the backend (an invalid-key refusal)\n");
        detail.append("is therefore evidence the path is not gated by the container.\n\n");
        detail.append("The Google provider is a different path and is NOT tested here: it\n");
        detail.append("requires a Google ID token from Google Sign-In, which P12 shows is\n");
        detail.append("refused at connection time inside a guest. Firebase Phone Auth and\n");
        detail.append("App Check additionally need Play Integrity attestation, which a\n");
        detail.append("container cannot honestly satisfy.\n");

        Verdict verdict;
        String summary;
        if (emailReachedBackend || anonReachedBackend) {
            verdict = Verdict.PASS;
            summary = "credential paths reached Google's auth backend; only the placeholder "
                    + "key was refused";
        } else {
            verdict = Verdict.PARTIAL;
            summary = "credential paths did not reach the backend; see detail";
        }
        DiagLog.line(DiagLog.TAG, "P21 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P21", "Firebase Auth paths", verdict, summary, detail.toString());
    }

    /**
     * Runs one sign-in attempt and returns its error code, or {@code SUCCESS} if — against
     * expectation — the placeholder key was accepted (which itself would be worth knowing).
     */
    private static String attempt(String label, Callable<com.google.android.gms.tasks.Task<AuthResult>> op,
            StringBuilder detail) {
        try {
            Tasks.await(op.call(), 20, TimeUnit.SECONDS);
            DiagLog.line(DiagLog.TAG, "P21 " + label + " = SUCCESS (placeholder key accepted?!)");
            detail.append(label).append(" = SUCCESS (unexpected)\n");
            return "SUCCESS";
        } catch (java.util.concurrent.ExecutionException e) {
            Throwable cause = e.getCause() == null ? e : e.getCause();
            String code = cause instanceof FirebaseAuthException
                    ? ((FirebaseAuthException) cause).getErrorCode()
                    : cause.getClass().getSimpleName() + ": " + cause.getMessage();
            DiagLog.line(DiagLog.TAG, "P21 " + label + " = " + code);
            detail.append(label).append(" = ").append(code).append('\n');
            return code;
        } catch (Throwable t) {
            String code = t.getClass().getSimpleName() + ": " + t.getMessage();
            DiagLog.line(DiagLog.TAG, "P21 " + label + " threw " + code);
            detail.append(label).append(" threw ").append(code).append('\n');
            return code;
        }
    }

    /**
     * Whether the answer means "the request reached the Firebase backend and the API key
     * (or the provider setting) was refused" — i.e. no container-identity gate intervened.
     *
     * <p>The Android SDK surfaces the Identity Toolkit's invalid-key answer either as a
     * {@code FirebaseAuthException} code ({@code ERROR_INVALID_API_KEY}) or, for some paths,
     * as a generic {@code FirebaseException} whose message is the server's plain sentence
     * ("API key not valid. Please pass a valid API key."). Both wordings are matched;
     * matching only the code word made the first host run read as if the backend had never
     * been reached.
     */
    private static boolean isCredentialRefusal(String code) {
        if (code == null) {
            return false;
        }
        String lower = code.toLowerCase(java.util.Locale.US);
        return lower.contains("error_invalid_api_key")
                || lower.contains("api_key_invalid")
                || lower.contains("api key not valid")
                || lower.contains("invalid api key")
                || lower.contains("error_operation_not_allowed")
                || lower.contains("error_app_not_authorized");
    }
}
