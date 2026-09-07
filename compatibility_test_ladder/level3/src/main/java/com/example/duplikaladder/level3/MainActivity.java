package com.example.duplikaladder.level3;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private TextView state;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);
        TextView title = new TextView(this);
        title.setText("Ladder Level 3\nModern multi-activity app");
        title.setTextSize(22);
        root.addView(title);
        state = new TextView(this);
        state.setText("network=not tested");
        state.setTextSize(17);
        root.addView(state);
        Button network = new Button(this);
        network.setText("Run network request");
        network.setOnClickListener(v -> NetworkProbe.run(state));
        root.addView(network);
        Button web = new Button(this);
        web.setText("Open WebView activity");
        web.setOnClickListener(v -> startActivity(new Intent(this, DetailActivity.class)));
        root.addView(web);
        setContentView(root);
    }
}
