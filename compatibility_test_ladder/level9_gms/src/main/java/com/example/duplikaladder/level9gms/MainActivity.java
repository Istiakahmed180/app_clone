package com.example.duplikaladder.level9gms;

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
 * Level 9 GMS diagnostic.
 *
 * <p>The same APK is meant to be run twice — once installed normally on the host, once
 * cloned into a Duplika container — and the two reports compared. That is why the app
 * carries no Duplika dependency and no build flavour: any difference between the two
 * runs can only come from the virtualization layer.
 *
 * <p>The tests run in sequence rather than in parallel. C and D each bind to Play
 * services, and overlapping binds would make a timeout impossible to attribute.
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
        results.put("A", TestResult.notTested("A", "GMS package detection"));
        results.put("B", TestResult.notTested("B", "Play services availability"));
        results.put("C", TestResult.notTested("C", "GMS service resolution"));
        results.put("D", TestResult.notTested("D", "GoogleApi client connection"));
        results.put("E", TestResult.notTested("E", "Google/Firebase dependency diagnostics"));
        setContentView(buildUi());

        // Runs itself. Both halves of the comparison — a normal installation and a clone —
        // then need nothing but `am start`, which keeps the two runs identical and makes
        // the evidence capture reproducible. `-e autorun false` holds it for a manual tap.
        if (!"false".equals(getIntent().getStringExtra("autorun"))) {
            new Handler(Looper.getMainLooper()).post(this::startRun);
        }
    }

    private View buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);

        TextView title = new TextView(this);
        title.setText("Ladder Level 9 — GMS compatibility");
        title.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(title);

        header = new TextView(this);
        header.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        header.setText(identity.summary());
        root.addView(header);

        runAll = new Button(this);
        runAll.setText("RUN ALL TESTS");
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
        DiagLog.section("LEVEL 9 GMS DIAGNOSTIC RUN");
        identity.log();

        record(TestAPackageDetection.run(this));
        record(TestBAvailability.run(this));
        record(TestELibraryDiagnostics.run(this));

        // C and D are asynchronous and are chained, so only one bind to Play services is
        // ever outstanding.
        TestCServiceResolution.run(this, resultC -> {
            record(resultC);
            TestDApiClient.run(this, resultD -> {
                record(resultD);
                DiagLog.section("RUN COMPLETE");
                writeReportFile();
                runAll.setEnabled(true);
            });
        });
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
        String body = "[" + result.verdict + "] TEST " + result.id + " — " + result.title
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
            default: return Color.parseColor("#EEEEEE");
        }
    }

    /**
     * Re-emits the whole buffer as one block. A run inside a container produces logcat
     * lines interleaved with the engine's own, and capturing evidence is far easier from
     * a single contiguous dump than from a filtered stream.
     */
    private void dumpLog() {
        for (String line : DiagLog.dump().split("\n")) {
            android.util.Log.i(DiagLog.TAG + ".Dump", line);
        }
    }

    /**
     * A copy on disk as well as in logcat.
     *
     * <p>Inside a container this path is rewritten by the engine, so where the file lands
     * is itself informative; the resolved path is logged for that reason.
     */
    private void writeReportFile() {
        File target = new File(getFilesDir(), "level9-gms-report.txt");
        try (FileOutputStream out = new FileOutputStream(target)) {
            out.write(DiagLog.dump().getBytes(Charset.forName("UTF-8")));
            DiagLog.line(DiagLog.TAG, "report written to " + target.getAbsolutePath());
        } catch (IOException e) {
            DiagLog.failure(DiagLog.TAG, "could not write report file to " + target.getAbsolutePath(), e);
        }
    }
}
