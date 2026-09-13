package top.niunaijun.blackbox.fake.service.context.providers;

import android.os.Bundle;
import android.os.IInterface;

import java.lang.reflect.Method;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.ClassInvocationStub;
import top.niunaijun.blackbox.utils.AttributionSourceUtils;
import top.niunaijun.blackbox.utils.Slog;

/**
 * Spike fix (spike/microg-container): keeps the upstream behavior, but when the framework
 * rejects a provider call with an attribution-source UID mismatch
 * ("Calling uid: N doesn't match source uid: M"), retries the call once with the
 * attribution source's uid rewritten to the *calling* uid the framework named.
 *
 * Why: a guest process's virtual uid (e.g. 10002 for microG) and the host uid the engine's
 * AttributionSourceUtils writes into the source (e.g. 10257) disagree, so Android 11+
 * refuses every cross-process provider call with that mismatch. Upstream swallows the error
 * and returns a safe default — for `query`, null — which is fine for providers a guest only
 * reads opportunistically, but fatal for microG, whose SettingsContract reads its own
 * settings through a provider and turns a null cursor into "Checkin disabled".
 *
 * This is deliberately narrow: it only rewrites the uid on a retry, after the framework has
 * told us which uid it expects, and only for providers reached through this wrapper.
 */
public class ContentProviderStub extends ClassInvocationStub implements BContentProvider {
    public static final String TAG = "ContentProviderStub";
    private IInterface mBase;
    private String mAppPkg;

    private static final Pattern CALLING_UID =
            Pattern.compile("Calling uid:\\s*(\\d+)\\s*doesn't match source uid");

    public IInterface wrapper(final IInterface contentProviderProxy, final String appPkg) {
        mBase = contentProviderProxy;
        mAppPkg = appPkg;
        injectHook();
        return (IInterface) getProxyInvocation();
    }

    @Override
    public Object getWho() {
        return mBase;
    }

    @Override
    public void inject(Object baseInvocation, Object proxyInvocation) {

    }

    @Override
    public void onBindMethod() {

    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) {
        try {
            return doInvoke(proxy, method, args);
        } catch (Throwable error) {
            throw new RuntimeException(error);
        }
    }

    private Object doInvoke(Object proxy, Method method, Object[] args) throws Throwable {
        if ("asBinder".equals(method.getName())) {
            return method.invoke(mBase, args);
        }

        String methodName = method.getName();

        if ("call".equals(methodName)) {
            AttributionSourceUtils.fixAttributionSourceInArgs(args);
        } else {
            if (args != null && args.length > 0) {
                for (int i = 0; i < args.length; i++) {
                    Object arg = args[i];
                    if (arg instanceof String) {
                        String strArg = (String) arg;
                        if (!isSystemProviderAuthority(strArg)) {
                            args[i] = mAppPkg;
                        }
                    }
                }
                AttributionSourceUtils.fixAttributionSourceInArgs(args);
            }
        }

        boolean dataMethod = methodName.equals("query") || methodName.equals("insert")
                || methodName.equals("update") || methodName.equals("delete")
                || methodName.equals("bulkInsert") || methodName.equals("call");

        if (dataMethod) {
            try {
                return method.invoke(mBase, args);
            } catch (Throwable e) {
                Throwable cause = e.getCause();
                if (isUidMismatchError(cause)) {
                    Integer callingUid = callingUidFrom(cause);
                    if (callingUid != null && rewriteAttributionUid(args, callingUid)) {
                        try {
                            Slog.w(TAG, "UID mismatch; retrying " + methodName
                                    + " with source uid " + callingUid);
                            return method.invoke(mBase, args);
                        } catch (Throwable retryError) {
                            Slog.w(TAG, "UID-mismatch retry failed: " + retryError);
                        }
                    }
                    Slog.w(TAG, "UID mismatch in ContentProvider call, returning safe default: "
                            + cause.getMessage());
                    return getSafeDefaultValue(methodName, method.getReturnType());
                } else if (cause instanceof RuntimeException) {
                    String message = cause.getMessage();
                    if (message != null && (message.contains("uid") || message.contains("permission"))) {
                        Slog.w(TAG, "Permission/UID error in ContentProvider call, returning safe default: " + message);
                        return getSafeDefaultValue(methodName, method.getReturnType());
                    }
                }

                if (methodName.equals("call")) {
                    Slog.w(TAG, "Error in call method, returning safe default: " + e.getMessage());
                    return getSafeDefaultValue(methodName, method.getReturnType());
                }

                throw e.getCause();
            }
        }

        try {
            return method.invoke(mBase, args);
        } catch (Throwable e) {
            Throwable cause = e.getCause();
            if (isUidMismatchError(cause)) {
                Integer callingUid = callingUidFrom(cause);
                if (callingUid != null && rewriteAttributionUid(args, callingUid)) {
                    try {
                        return method.invoke(mBase, args);
                    } catch (Throwable ignored) {
                    }
                }
                Slog.w(TAG, "UID mismatch in " + methodName + ", returning safe default: " + cause.getMessage());
                return getSafeDefaultValue(methodName, method.getReturnType());
            }
            throw e.getCause();
        }
    }

    /** Rewrites every AttributionSource argument's uid to [uid]. True if at least one changed. */
    private boolean rewriteAttributionUid(Object[] args, int uid) {
        if (args == null) {
            return false;
        }
        boolean changed = false;
        for (Object arg : args) {
            if (arg != null && arg.getClass().getName().contains("AttributionSource")) {
                if (setUidField(arg, uid)) {
                    changed = true;
                }
            }
        }
        return changed;
    }

    private boolean setUidField(Object attributionSource, int uid) {
        // Android 14+: AttributionSource is final and wraps an AttributionSourceState whose
        // `uid` is the field the framework actually compares. There is no direct uid field on
        // AttributionSource itself, which is why the other candidate names do not match.
        for (String stateName : new String[]{"mAttributionSourceState", "mState", "mSource"}) {
            try {
                java.lang.reflect.Field stateField =
                        attributionSource.getClass().getDeclaredField(stateName);
                stateField.setAccessible(true);
                Object state = stateField.get(attributionSource);
                if (state == null) continue;
                java.lang.reflect.Field uidField = state.getClass().getField("uid");
                uidField.setInt(state, uid);
                return true;
            } catch (Throwable ignored) {
                // try the next wrapper name
            }
        }

        String[] names = {"mUid", "uid", "mCallingUid", "callingUid", "mSourceUid", "sourceUid"};
        for (String name : names) {
            try {
                java.lang.reflect.Field field = attributionSource.getClass().getDeclaredField(name);
                field.setAccessible(true);
                field.set(attributionSource, uid);
                return true;
            } catch (Throwable ignored) {
                // try the next candidate name
            }
        }
        return false;
    }

    private Integer callingUidFrom(Throwable error) {
        if (error == null || error.getMessage() == null) {
            return null;
        }
        Matcher matcher = CALLING_UID.matcher(error.getMessage());
        if (matcher.find()) {
            try {
                return Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException ignored) {
            }
        }
        return null;
    }

    private Object getSafeDefaultValue(String methodName) {
        switch (methodName) {
            case "query":
                return null;
            case "insert":
                return null;
            case "update":
            case "delete":
                return 0;
            case "bulkInsert":
                return 0;
            case "call":
                return new Bundle();
            case "getType":
                return null;
            case "openFile":
                return null;
            case "openAssetFile":
                return null;
            default:
                return null;
        }
    }

    private boolean isSystemProviderAuthority(String authority) {
        if (authority == null) return false;
        return authority.equals("settings")
                || authority.equals("settings_global")
                || authority.equals("settings_system")
                || authority.equals("settings_secure")
                || authority.equals("media")
                || authority.equals("telephony")
                || authority.startsWith("android.provider.Settings");
    }

    private boolean isUidMismatchError(Throwable error) {
        if (error == null) return false;
        String message = error.getMessage();
        if (message == null) return false;
        return message.contains("Calling uid") && message.contains("doesn't match source uid")
                || message.contains("uid") && message.contains("permission")
                || message.contains("SecurityException")
                || message.contains("UID mismatch");
    }

    private Object getSafeDefaultValue(String methodName, Class<?> returnType) {
        if (returnType == null) {
            return getSafeDefaultValue(methodName);
        }
        if (returnType == String.class) {
            return "true";
        } else if (returnType == int.class || returnType == Integer.class) {
            return 1;
        } else if (returnType == long.class || returnType == Long.class) {
            return 1L;
        } else if (returnType == float.class || returnType == Float.class) {
            return 1.0f;
        } else if (returnType == boolean.class || returnType == Boolean.class) {
            return true;
        } else if (returnType == Bundle.class) {
            return new Bundle();
        }
        return getSafeDefaultValue(methodName);
    }

    @Override
    public boolean isBadEnv() {
        return false;
    }
}
