package top.niunaijun.blackbox.fake.service;

import java.lang.reflect.Method;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethods;
import top.niunaijun.blackbox.utils.MethodParameterUtils;
import top.niunaijun.blackbox.utils.Slog;

/**
 * Keeps the upstream permission behavior and adds the Android 15 UID-based query.
 * Context.checkSelfPermission now reaches IActivityManager.checkPermissionForDevice;
 * its UID is the virtual UID and must be translated to the host UID before the
 * real framework performs the protected-permission check.
 */
@ProxyMethods({"checkPermission", "checkPermissionForDevice"})
public class IActivityManagerProxy$checkPermission extends MethodHook {
    private static final String TAG = "ActivityManagerStub";

    @Override
    public Object hook(Object who, Method method, Object[] args) {
        if ("checkPermissionForDevice".equals(method.getName())) {
            if (args != null && args.length >= 4 && args[2] instanceof Integer) {
                int guestUid = (Integer) args[2];
                args[2] = BlackBoxCore.getHostUid();
                Slog.d(TAG, "checkPermissionForDevice: mapped uid " + guestUid + " -> "
                        + BlackBoxCore.getHostUid() + " permission=" + args[0]);
            }
            try {
                return method.invoke(who, args);
            } catch (Throwable error) {
                throw new RuntimeException(error);
            }
        }

        // Preserve the existing Bcore behavior for the older three-argument method.
        MethodParameterUtils.replaceLastUid(args);
        String permission = args != null && args.length > 0 && args[0] instanceof String
                ? (String) args[0] : null;
        if ("android.permission.ACCOUNT_MANAGER".equals(permission)
                || "android.permission.SEND_SMS".equals(permission)) {
            return Integer.valueOf(0);
        }
        if (isAudioPermission(permission)) {
            Slog.d(TAG, "ActivityManager checkPermission: Granting audio permission:" + permission);
            return Integer.valueOf(0);
        }
        if (isStorageOrMediaPermission(permission)) {
            Slog.d(TAG, "ActivityManager checkPermission: Granting storage/media permission:" + permission);
            return Integer.valueOf(0);
        }
        try {
            return method.invoke(who, args);
        } catch (Throwable error) {
            throw new RuntimeException(error);
        }
    }

    private static boolean isAudioPermission(String permission) {
        return permission != null && (permission.equals("android.permission.RECORD_AUDIO")
                || permission.equals("android.permission.CAPTURE_AUDIO_OUTPUT")
                || permission.equals("android.permission.MODIFY_AUDIO_SETTINGS")
                || permission.equals("android.permission.FOREGROUND_SERVICE_MICROPHONE")
                || permission.equals("android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION")
                || permission.equals("android.permission.FOREGROUND_SERVICE_CAMERA")
                || permission.equals("android.permission.FOREGROUND_SERVICE_LOCATION")
                || permission.equals("android.permission.FOREGROUND_SERVICE_HEALTH")
                || permission.equals("android.permission.FOREGROUND_SERVICE_DATA_SYNC")
                || permission.equals("android.permission.FOREGROUND_SERVICE_SPECIAL_USE")
                || permission.equals("android.permission.FOREGROUND_SERVICE_SYSTEM_EXEMPTED")
                || permission.equals("android.permission.FOREGROUND_SERVICE_PHONE_CALL")
                || permission.equals("android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"));
    }

    private static boolean isStorageOrMediaPermission(String permission) {
        return permission != null && (permission.equals("android.permission.READ_EXTERNAL_STORAGE")
                || permission.equals("android.permission.WRITE_EXTERNAL_STORAGE")
                || permission.equals("android.permission.READ_MEDIA_AUDIO")
                || permission.equals("android.permission.READ_MEDIA_VIDEO")
                || permission.equals("android.permission.READ_MEDIA_IMAGES")
                || permission.equals("android.permission.READ_MEDIA_VISUAL")
                || permission.equals("android.permission.READ_MEDIA_AURAL")
                || permission.equals("android.permission.ACCESS_MEDIA_LOCATION")
                || permission.equals("android.permission.READ_MEDIA_AUDIO_USER_SELECTED")
                || permission.equals("android.permission.READ_MEDIA_VIDEO_USER_SELECTED")
                || permission.equals("android.permission.READ_MEDIA_IMAGES_USER_SELECTED")
                || permission.equals("android.permission.READ_MEDIA_VISUAL_USER_SELECTED")
                || permission.equals("android.permission.READ_MEDIA_AURAL_USER_SELECTED"));
    }
}
