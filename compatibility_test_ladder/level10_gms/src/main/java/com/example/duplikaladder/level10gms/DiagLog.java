package com.example.duplikaladder.level10gms;

import android.util.Log;

import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * The one place Level 10 writes evidence.
 *
 * <p>Every line goes to logcat under a {@code Duplika.GMS10*} tag and is also kept in
 * memory so the same text can be shown in the app and dumped as a single block. Both
 * matter: logcat is what the evidence files are captured from, and the in-app copy is
 * what makes the diagnostic usable on a device with no host attached.
 *
 * <p>Nothing here ever receives a credential. The diagnostics deliberately stop short of
 * any account, token or key, so there is nothing to redact — but {@link #line} still
 * refuses anything that looks like one, so a future test cannot quietly start leaking.
 */
public final class DiagLog {

    public static final String TAG = "Duplika.GMS10";
    public static final String TAG_PACKAGE = "Duplika.GMS10.Package";
    public static final String TAG_SERVICE = "Duplika.GMS10.Service";
    public static final String TAG_BINDER = "Duplika.GMS10.Binder";
    public static final String TAG_INTENT = "Duplika.GMS10.Intent";
    public static final String TAG_UID = "Duplika.GMS10.UID";

    private static final SimpleDateFormat STAMP =
            new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US);

    /** Substrings that must never reach a log line, checked case-insensitively. */
    private static final String[] FORBIDDEN = {
            "access_token", "refresh_token", "id_token", "oauth", "bearer ",
            "password", "private key", "begin rsa",
    };

    private static final List<String> BUFFER = new ArrayList<>();

    private DiagLog() {
    }

    public static synchronized void line(String tag, String message) {
        String safe = redactIfSuspicious(message);
        String stamped = STAMP.format(new Date()) + " " + tag + ": " + safe;
        BUFFER.add(stamped);
        Log.i(tag, safe);
    }

    public static synchronized void failure(String tag, String message, Throwable error) {
        StringWriter trace = new StringWriter();
        error.printStackTrace(new PrintWriter(trace));
        String body = message
                + " | exceptionClass=" + error.getClass().getName()
                + " | exceptionMessage=" + error.getMessage();
        String stamped = STAMP.format(new Date()) + " " + tag + ": " + body + "\n" + trace;
        BUFFER.add(stamped);
        Log.e(tag, body, error);
    }

    public static synchronized void section(String title) {
        line(TAG, "================ " + title + " ================");
    }

    public static synchronized String dump() {
        StringBuilder out = new StringBuilder();
        for (String entry : BUFFER) {
            out.append(entry).append('\n');
        }
        return out.toString();
    }

    public static synchronized void clear() {
        BUFFER.clear();
    }

    /**
     * A guard, not a feature. If a line ever looks like it carries a secret the value is
     * dropped rather than logged, and the drop itself is visible so it cannot pass
     * unnoticed.
     */
    private static String redactIfSuspicious(String message) {
        String lower = message.toLowerCase(Locale.US);
        for (String marker : FORBIDDEN) {
            if (lower.contains(marker)) {
                return "[REDACTED: line matched forbidden marker '" + marker + "']";
            }
        }
        return message;
    }
}
