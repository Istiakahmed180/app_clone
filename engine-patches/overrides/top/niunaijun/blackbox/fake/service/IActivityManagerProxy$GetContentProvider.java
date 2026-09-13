package top.niunaijun.blackbox.fake.service;

import android.content.pm.ProviderInfo;
import android.os.IBinder;
import android.os.IInterface;

import java.lang.reflect.Method;

import black.android.content.ContentProviderNativeStatic;
import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.entity.AppConfig;
import top.niunaijun.blackbox.fake.delegate.ContentProviderDelegate;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethod;
import top.niunaijun.blackbox.fake.service.context.providers.ContentProviderStub;
import top.niunaijun.blackbox.proxy.ProxyManifest;
import top.niunaijun.blackbox.utils.Reflector;
import top.niunaijun.blackbox.utils.compat.BuildCompat;
import top.niunaijun.blackreflection.BlackReflection;

import static android.content.pm.PackageManager.GET_META_DATA;

/**
 * Container-first resolution for Google-service authorities.
 *
 * Upstream routes any authority whose name *contains* `com.google.android.gms` (and
 * `com.android.vending` / `com.google.android.gsf`) straight to the host's content-provider
 * resolver. That is correct while the host's genuine Play services is the only implementation
 * a guest can see, but once a container provisions its own `com.google.android.gms` — e.g.
 * microG — its providers are unreachable: microG stores its configuration behind
 * `com.google.android.gms.microg.settings` / `.profile`, both of which contain the substring
 * and were therefore answered by the host, which does not define them:
 *
 *   E ActivityThread: Failed to find provider info for com.google.android.gms.microg.settings
 *
 * microG then reads checkin as disabled and refuses push registration.
 *
 * This override resolves the authority in the container first for Google-service authorities,
 * and only falls back to the host when the container has no provider for it. The
 * non-Google host-forced authorities (`settings`, `media`, `telephony`, OEM launcher
 * settings) are left exactly as upstream, and everything else keeps the container path.
 *
 * It changes only *where* a provider is looked up. No identity, signature, UID or permission
 * behavior is touched.
 */
@ProxyMethod("getContentProvider")
public class IActivityManagerProxy$GetContentProvider extends MethodHook {

    @Override
    public Object hook(Object who, Method method, Object[] args) {
        try {
            return doHook(who, method, args);
        } catch (Throwable error) {
            throw new RuntimeException(error);
        }
    }

    private Object doHook(Object who, Method method, Object[] args) throws Throwable {
        int authIndex = getAuthIndex();
        Object auth = args[authIndex];
        Object content;

        if (auth instanceof String) {
            String authority = (String) auth;
            if (ProxyManifest.isProxy(authority)) {
                return method.invoke(who, args);
            }

            if (BuildCompat.isQ()) {
                args[1] = BlackBoxCore.getHostPkg();
            }

            // Host-only system authorities keep the upstream behavior untouched: they are not
            // backed by anything a container can provision.
            if (authority.equals("settings")
                    || authority.equals("media")
                    || authority.equals("telephony")
                    || authority.equals("com.huawei.android.launcher.settings")
                    || authority.equals("com.hihonor.android.launcher.settings")) {
                content = method.invoke(who, args);
                ContentProviderDelegate.update(content, authority);
                return content;
            }

            boolean googleAuthority = authority.contains("com.google.android.gms")
                    || authority.contains("com.android.vending")
                    || authority.contains("com.google.android.gsf");

            ProviderInfo providerInfo = BlackBoxCore.getBPackageManager()
                    .resolveContentProvider(authority, GET_META_DATA, BActivityThread.getUserId());

            // No container provider: the host may have one (the genuine Play services path),
            // otherwise there is nothing to serve.
            if (providerInfo == null) {
                if (googleAuthority) {
                    content = method.invoke(who, args);
                    ContentProviderDelegate.update(content, authority);
                    return content;
                }
                return null;
            }

            IBinder providerBinder = null;
            if (BActivityThread.getAppPid() != -1) {
                AppConfig appConfig = BlackBoxCore.getBActivityManager()
                        .initProcess(
                                providerInfo.packageName,
                                providerInfo.processName,
                                BActivityThread.getUserId());
                if (appConfig.bpid != BActivityThread.getAppPid()) {
                    providerBinder = BlackBoxCore.getBActivityManager()
                            .acquireContentProviderClient(providerInfo);
                }
                args[authIndex] = ProxyManifest.getProxyAuthorities(appConfig.bpid);
                args[getUserIndex()] = BlackBoxCore.getHostUserId();
            }
            if (providerBinder == null) {
                return null;
            }

            content = method.invoke(who, args);
            Reflector.with(content).field("info").set(providerInfo);
            ContentProviderNativeStatic providerNative =
                    BlackReflection.create(ContentProviderNativeStatic.class, null, false);
            IInterface nativeProvider = providerNative.asInterface(providerBinder);
            Reflector.with(content)
                    .field("provider")
                    .set(
                            new ContentProviderStub()
                                    .wrapper(nativeProvider, providerInfo.packageName));
            return content;
        }

        return method.invoke(who, args);
    }

    protected int getAuthIndex() {
        if (BuildCompat.isQ()) {
            return 2;
        }
        return 1;
    }

    protected int getUserIndex() {
        return getAuthIndex() + 1;
    }
}
