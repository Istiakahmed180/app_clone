package com.example.duplikaladder.level7fixture;

import android.app.Activity;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

/** Ordinary third-party-style single-activity split-resource fixture. */
public final class MainActivity extends Activity {
    static { System.loadLibrary("level7fixture"); }
    private TextView status;
    private SharedPreferences preferences;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        preferences = getSharedPreferences("level7", MODE_PRIVATE);
        int launches = preferences.getInt("launches", 0) + 1;
        preferences.edit().putInt("launches", launches).apply();

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(40, 40, 40, 40);
        TextView title = new TextView(this);
        title.setText("Level 7A\\nBase + ABI split");
        title.setTextSize(24);
        root.addView(title);
        status = new TextView(this);
        status.setText("launches=" + launches + " marker=" + markerColor() + " native=" + nativeMarker());
        root.addView(status);
        Button button = new Button(this);
        button.setText("VERIFY SPLIT RESOURCE");
        button.setOnClickListener(v -> status.setText("split resource loaded marker=" + markerColor() + " native=" + nativeMarker()));
        root.addView(button);
        setContentView(root);
    }

    private String markerColor() {
        return getResources().getResourceEntryName(com.example.duplikaladder.level7fixture.R.drawable.split_marker);
    }

    private static native String nativeMarker();
}
