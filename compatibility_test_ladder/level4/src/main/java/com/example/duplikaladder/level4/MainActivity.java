package com.example.duplikaladder.level4;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private TextView state;

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS}, 7);
        }
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(40, 40, 40, 40);
        TextView title = new TextView(this);
        title.setText("Ladder Level 4\nServices, receiver, notification");
        title.setTextSize(22);
        root.addView(title);
        state = new TextView(this);
        state.setTextSize(17);
        root.addView(state);
        Button start = new Button(this);
        start.setText("Start foreground service");
        start.setOnClickListener(v -> {
            Intent intent = new Intent(this, HeartbeatService.class);
            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent); else startService(intent);
            state.setText("service=start requested");
        });
        root.addView(start);
        Button broadcast = new Button(this);
        broadcast.setText("Send receiver broadcast");
        broadcast.setOnClickListener(v -> sendBroadcast(new Intent("com.example.duplikaladder.level4.TEST_BROADCAST")));
        root.addView(broadcast);
        setContentView(root);
    }
}
