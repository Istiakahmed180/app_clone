package com.example.duplikabaseline;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class SecondActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(48, 48, 48, 48);

        TextView text = new TextView(this);
        text.setText("Second Activity\nNavigation succeeded");
        text.setTextSize(22);
        root.addView(text);

        Button back = new Button(this);
        back.setText("Return to MainActivity");
        back.setOnClickListener(view -> finish());
        root.addView(back);
        setContentView(root);
    }
}
