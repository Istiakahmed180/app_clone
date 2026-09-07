package com.example.duplikaladder.level6;

import android.app.job.JobParameters;
import android.app.job.JobService;
import android.util.Log;

public class ProbeJobService extends JobService {
    @Override public boolean onStartJob(JobParameters params) {
        Log.i("LadderLevel6Job", "onStartJob");
        jobFinished(params, false);
        return false;
    }
    @Override public boolean onStopJob(JobParameters params) { Log.i("LadderLevel6Job", "onStopJob"); return false; }
}
