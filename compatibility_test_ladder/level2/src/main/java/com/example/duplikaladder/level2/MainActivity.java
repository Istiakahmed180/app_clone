package com.example.duplikaladder.level2;

import android.app.Activity;
import android.os.Bundle;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private int count;
    private TextView state;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        count = getPreferences(MODE_PRIVATE).getInt("count", 0);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(48, 48, 48, 48);
        TextView title = new TextView(this);
        title.setText("Ladder Level 2\nSimple ordinary app");
        title.setTextSize(24);
        root.addView(title, new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        state = new TextView(this);
        state.setTextSize(18);
        root.addView(state);
        Button button = new Button(this);
        button.setText("Increment and persist");
        button.setOnClickListener(v -> {
            count++;
            getPreferences(MODE_PRIVATE).edit().putInt("count", count).apply();
            render();
        });
        root.addView(button);
        setContentView(root);
        render();
    }

    private void render() { state.setText("count=" + count + "\npackage=" + getPackageName()); }
}
