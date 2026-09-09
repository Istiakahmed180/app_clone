package com.example.duplikaladder.isosvc;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.os.Process;
import android.util.Log;

/** An isolated service that does nothing but report that it was reached. */
public class IsoService extends Service {

    @Override public IBinder onBind(Intent intent) {
        Log.i("Duplika.IsoSvc", "IsoService.onBind reached, uid=" + Process.myUid()
                + " pid=" + Process.myPid());
        return new Binder();
    }
}
