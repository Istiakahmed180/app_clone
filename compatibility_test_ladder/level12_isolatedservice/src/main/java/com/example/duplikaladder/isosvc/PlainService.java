package com.example.duplikaladder.isosvc;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.os.Process;
import android.util.Log;

/** Non-isolated control service. */
public class PlainService extends Service {

    @Override public IBinder onBind(Intent intent) {
        Log.i("Duplika.IsoSvc", "PlainService.onBind reached, uid=" + Process.myUid()
                + " pid=" + Process.myPid());
        return new Binder();
    }
}
