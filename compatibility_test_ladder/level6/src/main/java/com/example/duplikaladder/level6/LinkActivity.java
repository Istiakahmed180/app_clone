package com.example.duplikaladder.level6;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class LinkActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        TextView v = new TextView(this);
        v.setText("Level 6 link activity reached");
        v.setTextSize(24);
        v.setPadding(40, 80, 40, 40);
        setContentView(v);
    }
}
