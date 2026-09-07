package com.example.duplikabaseline;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public final class MainActivity extends Activity {
    private static final String PREFS = "baseline_state";
    private static final String COUNT = "count";
    private static final String NAME = "name";

    private android.content.SharedPreferences state;
    private TextView stateView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        state = getSharedPreferences(PREFS, MODE_PRIVATE);
        BaselineService.start(this);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(48, 48, 48, 48);

        TextView title = new TextView(this);
        title.setText("Duplika baseline app");
        title.setTextSize(24);
        root.addView(title);

        stateView = new TextView(this);
        stateView.setTextSize(18);
        root.addView(stateView);

        Button increment = new Button(this);
        increment.setText("Increment and persist");
        increment.setOnClickListener(view -> {
            int count = state.getInt(COUNT, 0) + 1;
            state.edit().putInt(COUNT, count).putString(NAME, "Baseline user").apply();
            updateState();
        });
        root.addView(increment);

        Button navigate = new Button(this);
        navigate.setText("Open second Activity");
        navigate.setOnClickListener(view ->
                startActivity(new Intent(this, SecondActivity.class)));
        root.addView(navigate);

        setContentView(root);
        updateState();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (state != null) updateState();
    }

    private void updateState() {
        String providerStatus = "unavailable";
        try (Cursor cursor = getContentResolver().query(
                Uri.parse("content://com.example.duplikabaseline.provider/status"),
                null, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                providerStatus = cursor.getString(cursor.getColumnIndexOrThrow("status"));
            }
        } catch (RuntimeException error) {
            providerStatus = "error=" + error.getClass().getSimpleName();
        }
        stateView.setText("count=" + state.getInt(COUNT, 0) +
                "\nname=" + state.getString(NAME, "Initial user") +
                "\nprovider=" + providerStatus);
    }
}
