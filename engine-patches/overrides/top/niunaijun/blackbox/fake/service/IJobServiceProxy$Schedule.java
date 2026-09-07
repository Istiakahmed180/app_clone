package top.niunaijun.blackbox.fake.service;

import android.app.job.JobInfo;
import java.lang.reflect.Method;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethod;
import top.niunaijun.blackbox.utils.Slog;

/** Replacement nested hook; Android 12+ passes namespace before JobInfo. */
@ProxyMethod("schedule")
public class IJobServiceProxy$Schedule extends MethodHook {
    @Override
    public Object hook(Object who, Method method, Object[] args) {
        try {
            int jobIndex = findJobInfo(args);
            if (jobIndex < 0) {
                Slog.w("JobServiceStub", "Schedule: no JobInfo argument for " + method);
                return method.invoke(who, args);
            }

            JobInfo jobInfo = (JobInfo) args[jobIndex];
            Slog.d("JobServiceStub", "Schedule: Processing JobInfo at args[" + jobIndex + "] for package: "
                    + jobInfo.getService().getPackageName());
            try {
                JobInfo proxyJobInfo = BlackBoxCore.getBJobManager().schedule(jobInfo);
                if (proxyJobInfo != null) {
                    args[jobIndex] = proxyJobInfo;
                    Slog.d("JobServiceStub", "Schedule: Successfully created proxy JobInfo");
                }
            } catch (Throwable error) {
                Slog.w("JobServiceStub", "Schedule: virtual JobInfo rewrite failed; invoking host method", error);
            }
            return method.invoke(who, args);
        } catch (Throwable error) {
            throw new RuntimeException(error);
        }
    }

    private static int findJobInfo(Object[] args) {
        if (args == null) return -1;
        for (int i = 0; i < args.length; i++) {
            if (args[i] instanceof JobInfo) return i;
        }
        return -1;
    }
}
