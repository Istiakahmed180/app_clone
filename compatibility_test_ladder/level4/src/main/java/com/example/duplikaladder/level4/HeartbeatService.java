package com.example.duplikaladder.level4;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

public final class HeartbeatService extends Service {
    private static final String TAG = "LadderLevel4Service";
    private static final String CHANNEL = "ladder_level4";

    @Override public void onCreate() {
        super.onCreate();
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel channel = new NotificationChannel(CHANNEL, "Ladder service", NotificationManager.IMPORTANCE_LOW);
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
        Notification.Builder builder = Build.VERSION.SDK_INT >= 26 ? new Notification.Builder(this, CHANNEL) : new Notification.Builder(this);
        startForeground(41, builder.setContentTitle("Ladder Level 4").setContentText("Service is running").setSmallIcon(android.R.drawable.ic_popup_sync).build());
        Log.i(TAG, "onCreate and foreground started");
    }

    @Override public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "onStartCommand startId=" + startId);
        return START_STICKY;
    }

    @Override public IBinder onBind(Intent intent) { return null; }
}
