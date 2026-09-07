package com.example.duplikaladder.level4;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public final class TestReceiver extends BroadcastReceiver {
    @Override public void onReceive(Context context, Intent intent) {
        Log.i("LadderLevel4Receiver", "received=" + intent.getAction());
    }
}
