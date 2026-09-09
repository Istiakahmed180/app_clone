package com.example.duplikaladder.isosplit.feature;

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Process;
import android.util.Log;
import android.util.TypedValue;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The launcher activity of the isolated-feature-split fixture — declared only in this
 * split's manifest, never in the base.
 *
 * <p>Reaching {@code onCreate} at all is the entire assertion. If this screen appears, the
 * engine resolved a MAIN/LAUNCHER component that exists only in a split manifest, which is
 * the capability Chrome needs. If the clone refuses to launch, the engine is still parsing
 * base.apk alone.
 *
 * <p>It also prints whether the split APKs actually reached the guest's ClassLoader, so a
 * pass cannot be confused with the patch-0003 runtime-path support that was already present.
 */
public class MainActivity extends Activity {

    private static final String TAG = "Duplika.IsoSplit";

    private static final Pattern VIRTUAL_USER =
            Pattern.compile("/(?:blackbox|virtual)/(?:data/)?user/(\\d+)/");

    private final List<String> lines = new ArrayList<>();

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);

        ApplicationInfo ai = getApplicationInfo();
        Matcher m = VIRTUAL_USER.matcher(
                ai.dataDir + " " + (getFilesDir() == null ? "" : getFilesDir().getAbsolutePath()));
        boolean virtualized = m.find();

        line("========== ISOLATED FEATURE SPLIT FIXTURE ==========");
        line("LAUNCHED — a MAIN/LAUNCHER activity declared only in a split manifest resolved.");
        line("");
        line("package=" + getPackageName());
        line("activityClass=" + getClass().getName());
        line("uid=" + Process.myUid() + " pid=" + Process.myPid());
        line("virtualized=" + virtualized
                + " virtualUserId=" + (virtualized ? m.group(1) : "n/a (host installation)"));
        line("device=" + Build.MANUFACTURER + " " + Build.MODEL
                + " android=" + Build.VERSION.RELEASE + " api=" + Build.VERSION.SDK_INT);
        line("");
        line("---- split runtime paths (patch 0003 territory, shown to keep the two apart) ----");
        line("sourceDir=" + ai.sourceDir);
        String[] splits = ai.splitSourceDirs;
        line("splitSourceDirs=" + (splits == null ? "null" : splits.length + " entries"));
        if (splits != null) {
            for (String s : splits) {
                line("  " + s);
            }
        }
        line("");
        line("VERDICT: PASS — split-manifest component registration works.");
        line("====================================================");

        TextView view = new TextView(this);
        view.setTextSize(TypedValue.COMPLEX_UNIT_SP, 12);
        view.setPadding(24, 24, 24, 24);
        view.setText(String.join("\n", lines));
        ScrollView scroller = new ScrollView(this);
        scroller.addView(view);
        setContentView(scroller);
    }

    private void line(String text) {
        lines.add(text);
        Log.i(TAG, text);
    }
}
