package top.niunaijun.blackbox.fake.service;

import black.android.app.ActivityThreadStatic;
import black.android.os.ServiceManagerStatic;
import black.android.permission.IPermissionManagerStubStatic;
import java.lang.reflect.Method;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.BinderInvocationStub;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.service.base.PkgMethodProxy;
import top.niunaijun.blackbox.fake.service.base.ValueMethodProxy;
import top.niunaijun.blackreflection.BlackReflection;
import top.niunaijun.blackbox.utils.compat.BuildCompat;
import top.niunaijun.blackbox.utils.Slog;

/** Android 15 PermissionManager hook with host-grant mapping for guest self queries. */
public class IPermissionManagerProxy extends BinderInvocationStub {
    public static final String TAG = "IPermissionManagerProxy";
    private static final String P = "permissionmgr";

    public IPermissionManagerProxy() {
        super(serviceManager().getService(P));
    }

    @Override
    public Object getWho() {
        return permissionStub().asInterface(serviceManager().getService(P));
    }

    @Override
    public void inject(Object baseInvocation, Object proxyInvocation) {
        replaceSystemService(P);
        activityThread()._set_sPermissionManager(proxyInvocation);
    }

    @Override
    public void onBindMethod() {
        super.onBindMethod();
        addMethodHook(new ValueMethodProxy("addPermissionAsync", true));
        addMethodHook(new ValueMethodProxy("addPermission", true));
        addMethodHook(new ValueMethodProxy("performDexOpt", true));
        addMethodHook(new ValueMethodProxy("performDexOptIfNeeded", false));
        addMethodHook(new ValueMethodProxy("performDexOptSecondary", true));
        addMethodHook(new ValueMethodProxy("addOnPermissionsChangeListener", 0));
        addMethodHook(new ValueMethodProxy("removeOnPermissionsChangeListener", 0));
        addMethodHook(new ValueMethodProxy("checkDeviceIdentifierAccess", false));
        addMethodHook(new PkgMethodProxy("shouldShowRequestPermissionRationale"));
        addMethodHook(new CheckPackageNamePermission());
        addMethodHook(new CheckPermission());
        if (BuildCompat.isOreo()) {
            addMethodHook(new ValueMethodProxy("notifyDexLoad", 0));
            addMethodHook(new ValueMethodProxy("notifyPackageUse", 0));
            addMethodHook(new ValueMethodProxy("setInstantAppCookie", false));
            addMethodHook(new ValueMethodProxy("isInstantApp", false));
        }
    }

    @Override
    public boolean isBadEnv() {
        return false;
    }

    private static ServiceManagerStatic serviceManager() {
        return BlackReflection.create(ServiceManagerStatic.class, null, false);
    }

    private static IPermissionManagerStubStatic permissionStub() {
        return BlackReflection.create(IPermissionManagerStubStatic.class, null, false);
    }

    private static ActivityThreadStatic activityThread() {
        return BlackReflection.create(ActivityThreadStatic.class, null, false);
    }

    public static class CheckPackageNamePermission extends MethodHook {
        @Override
        public String getMethodName() {
            return "checkPackageNamePermission";
        }

        @Override
        public Object hook(Object who, Method method, Object[] args) {
            try {
                String guestPackage = BActivityThread.getAppProcessName();
                if (args != null && args.length > 0 && args[0] instanceof String) {
                    String requestedPackage = (String) args[0];
                    if (guestPackage != null && guestPackage.equals(args[0])) {
                        args[0] = BlackBoxCore.getHostPkg();
                        Slog.d(TAG, "Mapped permission package " + requestedPackage + " -> "
                                + BlackBoxCore.getHostPkg());
                    }
                }
                return method.invoke(who, args);
            } catch (Throwable error) {
                throw new RuntimeException(error);
            }
        }
    }

    public static class CheckPermission extends MethodHook {
        @Override
        public String getMethodName() {
            return "checkPermission";
        }

        @Override
        public Object hook(Object who, Method method, Object[] args) {
            try {
                String guestPackage = BActivityThread.getAppProcessName();
                if (args != null && args.length > 0 && args[0] instanceof String
                        && guestPackage != null && guestPackage.equals(args[0])) {
                    String requestedPackage = (String) args[0];
                    args[0] = BlackBoxCore.getHostPkg();
                    Slog.d(TAG, "Mapped checkPermission package " + requestedPackage + " -> "
                            + BlackBoxCore.getHostPkg());
                }
                return method.invoke(who, args);
            } catch (Throwable error) {
                throw new RuntimeException(error);
            }
        }
    }
}
