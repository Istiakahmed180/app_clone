package top.niunaijun.blackbox.fake.service;

import java.lang.reflect.Method;
import android.content.pm.PackageManager;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethods;
import top.niunaijun.blackbox.utils.MethodParameterUtils;
import top.niunaijun.blackbox.utils.Slog;

/**
 * Keeps the upstream permission behavior and adds the Android 15 UID-based query.
 * Context.checkSelfPermission now reaches IActivityManager.checkPermissionForDevice;
 * its UID is the virtual UID and must be translated to the host UID before the
 * real framework performs the protected-permission check.
 *
 * It also applies the app's per-clone permission policy: a permission the user denied for
 * this container is denied here, before any of the grant paths below. See
 * `co.tdevs.duplika.native.ClonePermissionPolicy` for the model and its limits — a guest
 * runs under the host UID, so this scopes apps that check before use, not the hardware
 * service's own UID check.
 */
@ProxyMethods({"checkPermission", "checkPermissionForDevice"})
public class IActivityManagerProxy$checkPermission extends MethodHook {
    private static final String TAG = "ActivityManagerStub";

    @Override
    public Object hook(Object who, Method method, Object[] args) {
        final String permission = args != null && args.length > 0 && args[0] instanceof String
                ? (String) args[0] : null;

        // The per-clone policy comes first: a permission denied for this container must not
        // be allowed by the grant shortcuts below.
        if (isDeniedForThisContainer(permission)) {
            Slog.d(TAG, "checkPermission: denied for this clone: " + permission);
            return Integer.valueOf(PackageManager.PERMISSION_DENIED);
        }

        if ("checkPermissionForDevice".equals(method.getName())) {
            if (args != null && args.length >= 4 && args[2] instanceof Integer) {
                int guestUid = (Integer) args[2];
                args[2] = BlackBoxCore.getHostUid();
                Slog.d(TAG, "checkPermissionForDevice: mapped uid " + guestUid + " -> "
                        + BlackBoxCore.getHostUid() + " permission=" + permission);
            }
            try {
                return method.invoke(who, args);
            } catch (Throwable error) {
                throw new RuntimeException(error);
            }
        }

        // Preserve the existing Bcore behavior for the older three-argument method.
        MethodParameterUtils.replaceLastUid(args);
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

    /** Shared with `ClonePermissionPolicy`. */
    private static final String POLICY_FILE = "clone_permissions.txt";

    /**
     * Whether the user denied [permission] for the container this process belongs to.
     *
     * Reads the plain file the app maintains, by absolute path, because the container
     * redirects the guest's own storage: a SharedPreferences read here comes back empty. Any
     * failure reads as "not denied", which preserves the previous behaviour rather than
     * blocking a permission by accident.
     */
    private static boolean isDeniedForThisContainer(String permission) {
        if (permission == null) {
            return false;
        }
        try {
            android.content.Context context = BlackBoxCore.getContext();
            if (context == null) {
                return false;
            }
            java.io.File file = new java.io.File(context.getFilesDir(), POLICY_FILE);
            if (!file.exists()) {
                return false;
            }
            final String wanted = BActivityThread.getUserId() + " " + permission;
            try (java.io.BufferedReader reader =
                         new java.io.BufferedReader(new java.io.FileReader(file))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.trim().equals(wanted)) {
                        return true;
                    }
                }
            }
            return false;
        } catch (Throwable error) {
            Slog.d(TAG, "policy check failed for " + permission + ": " + error);
            return false;
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
