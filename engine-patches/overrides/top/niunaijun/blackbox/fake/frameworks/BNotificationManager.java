package top.niunaijun.blackbox.fake.frameworks;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationChannelGroup;
import android.os.SystemClock;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.core.system.ServiceManager;
import top.niunaijun.blackbox.core.system.notification.IBNotificationManagerService;

/**
 * Replacement for the vendored Bcore class. The service binder can die between
 * BlackManager's health check and the first call, especially while a guest is
 * binding on Android 15. Re-fetch once from the engine service registry instead
 * of dereferencing the cleared cache entry.
 */
public class BNotificationManager extends BlackManager<IBNotificationManagerService> {
    private static final String TAG = "BNotificationManager";
    private static final BNotificationManager INSTANCE = new BNotificationManager();

    public static BNotificationManager get() {
        return INSTANCE;
    }

    @Override
    public String getServiceName() {
        return ServiceManager.NOTIFICATION_MANAGER;
    }

    private IBNotificationManagerService serviceOrRetry() {
        IBNotificationManagerService service = getService();
        if (service != null) return service;
        clearServiceCache();
        SystemClock.sleep(100L);
        service = getService();
        if (service == null) {
            Log.w(TAG, "Notification service unavailable after binder retry");
        }
        return service;
    }

    public NotificationChannel getNotificationChannel(String channelId) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            return service == null ? null : service.getNotificationChannel(channelId, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to read notification channel", e);
            return null;
        }
    }

    public List<NotificationChannelGroup> getNotificationChannelGroups(String packageName) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            return service == null ? null : service.getNotificationChannelGroups(packageName, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to read notification channel groups", e);
            return null;
        }
    }

    public void createNotificationChannel(NotificationChannel channel) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.createNotificationChannel(channel, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to create notification channel", e);
        }
    }

    public void deleteNotificationChannel(String channelId) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.deleteNotificationChannel(channelId, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to delete notification channel", e);
        }
    }

    public void createNotificationChannelGroup(NotificationChannelGroup group) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.createNotificationChannelGroup(group, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to create notification channel group", e);
        }
    }

    public void deleteNotificationChannelGroup(String groupId) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.deleteNotificationChannelGroup(groupId, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to delete notification channel group", e);
        }
    }

    public void enqueueNotificationWithTag(int id, String tag, Notification notification) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.enqueueNotificationWithTag(id, tag, notification, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to enqueue notification", e);
        }
    }

    public void cancelNotificationWithTag(int id, String tag) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            if (service != null) service.cancelNotificationWithTag(id, tag, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to cancel notification", e);
        }
    }

    public List<NotificationChannel> getNotificationChannels(String packageName) {
        try {
            IBNotificationManagerService service = serviceOrRetry();
            return service == null ? new ArrayList<>() : service.getNotificationChannels(packageName, BActivityThread.getUserId());
        } catch (Exception e) {
            Log.w(TAG, "Unable to read notification channels", e);
            return new ArrayList<>();
        }
    }
}
