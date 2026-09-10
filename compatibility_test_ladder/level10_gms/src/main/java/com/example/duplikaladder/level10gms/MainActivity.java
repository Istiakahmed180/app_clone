package com.example.duplikaladder.level10gms;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.TypedValue;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Level 10 GMS diagnostic — how far up the Google API stack a guest can actually get.
 *
 * <p>Level 9 answered "can a guest see and reach Play services" (yes) and found one
 * GoogleApi client call failing with {@code DEVELOPER_ERROR}. One probe could not say
 * whether that was true of all Google APIs or specific to that client layer, because the
 * probe varied nothing.
 *
 * <p>Level 10 is built as a controlled comparison. P1 and P2 both need no Google account,
 * no API key and no runtime permission; they differ only in which client layer they use —
 * P1 a direct AIDL service bind, P2 the GoogleApi framework. P3 re-runs Level 9's exact
 * API so the comparison sits on a reproduced baseline rather than a remembered one.
 *
 * <p>As in Level 9 the APK carries no Duplika dependency, so the identical binary runs on
 * the host and in a container and any difference is attributable to virtualization.
 *
 * <p>Probes run sequentially on a single worker thread. Two of them bind to Play services,
 * and overlapping binds would make a timeout impossible to attribute; the worker is also
 * required because {@code AdvertisingIdClient.getAdvertisingIdInfo} and {@code Tasks.await}
 * must not run on the main thread.
 */
public class MainActivity extends Activity {

    private final Map<String, TestResult> results = new LinkedHashMap<>();
    private final Map<String, TextView> cards = new LinkedHashMap<>();

    private GuestIdentity identity;
    private TextView header;
    private Button runAll;

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        identity = GuestIdentity.capture(this);
        results.put("P0", TestResult.notTested("P0", "Package visibility + availability"));
        results.put("P1", TestResult.notTested("P1", "Direct AIDL GMS service"));
        results.put("P2", TestResult.notTested("P2", "GoogleApi framework client"));
        results.put("P3", TestResult.notTested("P3", "Level 9 control (SettingsClient)"));
        results.put("P4", TestResult.notTested("P4", "Caller identity trace"));
        results.put("P5", TestResult.notTested("P5", "Account-bound APIs"));
        results.put("P6", TestResult.notTested("P6", "Per-API availability & resolution"));
        results.put("P7", TestResult.notTested("P7", "Cross-API discriminator"));
        results.put("P8", TestResult.notTested("P8", "Cross-artifact discriminator"));
        results.put("P9", TestResult.notTested("P9", "Local-input differential"));
        results.put("P10", TestResult.notTested("P10", "Direct service bind"));
        results.put("P11", TestResult.notTested("P11", "Attribution context experiment"));
        results.put("P12", TestResult.notTested("P12", "Sign-In / Play Integrity capability"));
        setContentView(buildUi());

        // Self-running, so a host installation and a clone both need nothing but
        // `am start` and the two runs stay identical. `-e autorun false` holds for a tap.
        if (!"false".equals(getIntent().getStringExtra("autorun"))) {
            new Handler(Looper.getMainLooper()).post(this::startRun);
        }
    }

    private View buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);

        TextView title = new TextView(this);
        title.setText("Ladder Level 10 — GMS API reach");
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(title);

        header = new TextView(this);
        header.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        header.setText(identity.summary());
        root.addView(header);

        runAll = new Button(this);
        runAll.setText("RUN ALL PROBES");
        runAll.setOnClickListener(v -> startRun());
        root.addView(runAll);

        Button dump = new Button(this);
        dump.setText("DUMP FULL LOG TO LOGCAT");
        dump.setOnClickListener(v -> dumpLog());
        root.addView(dump);

        for (Map.Entry<String, TestResult> entry : results.entrySet()) {
            TextView card = new TextView(this);
            card.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
            card.setPadding(16, 16, 16, 16);
            cards.put(entry.getKey(), card);
            root.addView(card);
            render(entry.getKey());
        }

        ScrollView scroller = new ScrollView(this);
        scroller.addView(root);
        return scroller;
    }

    private void startRun() {
        runAll.setEnabled(false);
        DiagLog.clear();
        DiagLog.section("LEVEL 10 GMS API REACH RUN");
        identity.log();

        // One worker, probes in order. P0 first because it is the baseline the rest are
        // interpreted against; P1 before P2 so the direct-AIDL result is on record before
        // the framework result, which is the comparison the whole run exists to make.
        new Thread(() -> {
            post(ProbeAvailability.run(this));
            post(ProbeAdvertisingId.run(this));
            post(ProbeAppSetId.run(this));
            post(ProbeLocationSettings.run(this));
            post(ProbeCallerIdentity.run(this));
            post(ProbeAccountBoundary.run(this));
            post(ProbeApiFeature.run(this));
            post(ProbeActivityRecognition.run(this));
            post(ProbeSmsRetriever.run(this));
            post(ProbeLocalInputs.run(this));
            post(ProbeServiceBind.run(this));
            post(ProbeAttributionContext.run(this));
            post(ProbeCapabilityChecks.run(this));

            new Handler(Looper.getMainLooper()).post(() -> {
                logComparison();
                DiagLog.section("RUN COMPLETE");
                writeReportFile();
                runAll.setEnabled(true);
            });
        }, "level10-probes").start();
    }

    /**
     * The one line the whole run is for: what the P1/P2 pair implies about where the
     * boundary sits. Stated in the log so the evidence carries its own interpretation and
     * a reader does not have to re-derive it from six probe verdicts.
     */
    private void logComparison() {
        Verdict direct = verdictOf("P1");
        Verdict framework = verdictOf("P2");
        Verdict control = verdictOf("P3");

        DiagLog.section("BOUNDARY LOCATION (from the P1 vs P2 comparison)");
        DiagLog.line(DiagLog.TAG, "P1 direct-AIDL=" + direct
                + "  P2 GoogleApi-framework=" + framework
                + "  P3 Level9-control=" + control);

        boolean directOk = direct == Verdict.PASS || direct == Verdict.PARTIAL;
        boolean frameworkOk = framework == Verdict.PASS;

        if (directOk && !frameworkOk) {
            DiagLog.line(DiagLog.TAG, "CONCLUSION: GMS transport and plain AIDL GMS services work"
                    + " in the guest; the boundary is the GoogleApi client framework's caller"
                    + " validation. Credential requirements were held constant, so the client"
                    + " layer is the only variable.");
        } else if (directOk && frameworkOk) {
            DiagLog.line(DiagLog.TAG, "CONCLUSION: both client layers work; Level 9's"
                    + " DEVELOPER_ERROR is specific to that one API rather than to the framework.");
        } else if (!directOk && !frameworkOk) {
            DiagLog.line(DiagLog.TAG, "CONCLUSION: neither client layer completes; the boundary"
                    + " is below the framework, at any GMS call that identifies its caller.");
        } else {
            DiagLog.line(DiagLog.TAG, "CONCLUSION: framework works while direct AIDL does not —"
                    + " unexpected; treat the run as inconclusive and re-measure.");
        }
    }

    private Verdict verdictOf(String id) {
        TestResult result = results.get(id);
        return result == null ? Verdict.NOT_TESTED : result.verdict;
    }

    private void post(TestResult result) {
        new Handler(Looper.getMainLooper()).post(() -> record(result));
    }

    private void record(TestResult result) {
        results.put(result.id, result);
        render(result.id);
    }

    private void render(String id) {
        TestResult result = results.get(id);
        TextView card = cards.get(id);
        if (result == null || card == null) {
            return;
        }
        card.setBackgroundColor(background(result.verdict));
        String body = "[" + result.verdict + "] " + result.id + " — " + result.title
                + "\n" + result.summary;
        if (!result.detail.isEmpty()) {
            body += "\n\n" + result.detail.trim();
        }
        card.setText(body);
    }

    private int background(Verdict verdict) {
        switch (verdict) {
            case PASS: return Color.parseColor("#C8E6C9");
            case PARTIAL: return Color.parseColor("#FFE0B2");
            case FAIL: return Color.parseColor("#FFCDD2");
            case BLOCKED: return Color.parseColor("#D1C4E9");
            // A security boundary is not a failure and must not read like one, or the
            // matrix invites someone to "fix" it.
            case UNSUPPORTED: return Color.parseColor("#CFD8DC");
            default: return Color.parseColor("#EEEEEE");
        }
    }

    private void dumpLog() {
        for (String line : DiagLog.dump().split("\n")) {
            android.util.Log.i(DiagLog.TAG + ".Dump", line);
        }
    }

    private void writeReportFile() {
        File target = new File(getFilesDir(), "level10-gms-report.txt");
        try (FileOutputStream out = new FileOutputStream(target)) {
            out.write(DiagLog.dump().getBytes(Charset.forName("UTF-8")));
            DiagLog.line(DiagLog.TAG, "report written to " + target.getAbsolutePath());
        } catch (IOException e) {
            DiagLog.failure(DiagLog.TAG, "could not write report file to "
                    + target.getAbsolutePath(), e);
        }
    }
}
