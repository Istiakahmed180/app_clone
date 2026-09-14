package top.niunaijun.blackbox.fake.service;

import android.content.pm.PackageInfo;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.app.BActivityThread;
import top.niunaijun.blackbox.fake.hook.MethodHook;
import top.niunaijun.blackbox.fake.hook.ProxyMethod;
import top.niunaijun.blackbox.utils.Slog;

/**
 * Keeps the upstream UID translation and completes the answer with the container's packages.
 *
 * ## Why
 *
 * microG verifies that a caller may act for a package with
 * `PackageUtils.checkPackageUid(context, packageName, callingUid)` — it asks the package
 * manager for `getPackagesForUid(callingUid)` and requires the package to be in that set. A
 * guest process running inside the container reports its own virtual UID as the caller, and
 * the container maps that UID to a single package, so the set comes back as
 * `[com.google.android.gms]` while the request is for `com.digibank.mobile`. microG then
 * refuses with
 *
 *   SecurityException: UID [10001] is not related to packageName [com.digibank.mobile]
 *
 * and the app never obtains an FCM token (measured on the emulator, 2026-09-14).
 *
 * Every package in a container runs under the same host process identity, so the distinction
 * this set is used for is not meaningful here. Merging the UID's own packages with the
 * packages installed in the current container keeps the upstream translation intact and makes
 * the set complete for callers that only ask "does this package belong to this container".
 *
 * It changes no permission, signature, UID or package identity: the UID translation above is
 * upstream's, and the added names are the packages this container already has.
 */
@ProxyMethod("getPackagesForUid")
public class IPackageManagerProxy$GetPackagesForUid extends MethodHook {

    private static final String TAG = "PackageManagerStub";

    @Override
    public Object hook(Object who, Method method, Object[] args) {
        try {
            int uid = (Integer) args[0];
            if (uid == BlackBoxCore.getHostUid()) {
                args[0] = BActivityThread.getBUid();
                uid = (int) args[0];
            }

            String[] packagesForUid = BlackBoxCore.getBPackageManager().getPackagesForUid(uid);
            String[] merged = mergeWithContainerPackages(packagesForUid);

            Slog.d(
                    TAG,
                    args[0] + " , " + BActivityThread.getAppProcessName()
                            + " GetPackagesForUid: " + Arrays.toString(merged));

            return merged;
        } catch (Throwable error) {
            // Never break a package-manager query: fall back to the upstream behaviour.
            Slog.w(TAG, "getPackagesForUid completion failed: " + error);
            try {
                int uid = (Integer) args[0];
                if (uid == BlackBoxCore.getHostUid()) {
                    args[0] = BActivityThread.getBUid();
                    uid = (int) args[0];
                }
                return BlackBoxCore.getBPackageManager().getPackagesForUid(uid);
            } catch (Throwable ignored) {
                return null;
            }
        }
    }

    private static String[] mergeWithContainerPackages(String[] packagesForUid) {
        Set<String> merged = new LinkedHashSet<>();
        if (packagesForUid != null) {
            merged.addAll(Arrays.asList(packagesForUid));
        }
        try {
            List<PackageInfo> installed = BlackBoxCore.getBPackageManager()
                    .getInstalledPackages(0, BActivityThread.getUserId());
            if (installed != null) {
                for (PackageInfo info : installed) {
                    if (info != null && info.packageName != null) {
                        merged.add(info.packageName);
                    }
                }
            }
        } catch (Throwable error) {
            Slog.w(TAG, "could not list container packages: " + error);
        }
        return merged.toArray(new String[0]);
    }
}
