package com.example.duplikaladder.level3;

import android.os.Handler;
import android.os.Looper;
import android.widget.TextView;
import java.net.HttpURLConnection;
import java.net.URL;

final class NetworkProbe {
    private NetworkProbe() {}

    static void run(TextView target) {
        target.setText("network=running");
        new Thread(() -> {
            String result;
            try {
                HttpURLConnection connection = (HttpURLConnection) new URL("https://example.com").openConnection();
                connection.setConnectTimeout(5000);
                connection.setReadTimeout(5000);
                result = "network=" + connection.getResponseCode();
                connection.disconnect();
            } catch (Exception error) {
                result = "network=" + error.getClass().getSimpleName();
            }
            String finalResult = result;
            new Handler(Looper.getMainLooper()).post(() -> target.setText(finalResult));
        }).start();
    }
}
