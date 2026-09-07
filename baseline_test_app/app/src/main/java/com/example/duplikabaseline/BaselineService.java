package com.example.duplikabaseline;

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

public final class BaselineService extends Service {
    private static final String TAG = "BaselineService";

    public static void start(Context context) {
        context.startService(new Intent(context, BaselineService.class));
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "onCreate package=" + getPackageName());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.i(TAG, "onStartCommand startId=" + startId);
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "onDestroy");
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
