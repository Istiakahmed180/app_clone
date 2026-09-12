package top.niunaijun.blackbox.core.env;

import android.content.ComponentName;
import android.os.Build;

import java.util.ArrayList;
import java.util.List;

import top.niunaijun.blackbox.BlackBoxCore;
import top.niunaijun.blackbox.utils.compat.BuildCompat;

/**
 * Runtime override of Bcore's {@code AppSystemEnv} (see engine-patches/README.md).
 *
 * It matches the shipped class -- the upstream version plus
 * 0002-host-platform-package-visibility.patch -- with one Duplika-specific change:
 * the host platform packages (Google Play services, GSF, Play Store) are hidden from a
 * Chrome guest, so Play services availability and package visibility report "missing"
 * inside a Chrome clone.
 *
 * Why. Chrome's first-run page is {@code SigninFirstRunFragment}. Its title is chosen by
 * {@code FullscreenSigninMediator.getTitleText()}: "Welcome to Chrome" when sign-in is
 * unsupported, "Make Chrome your own" when it is. Sign-in counts as supported only while
 * {@code ExternalAuthUtils.canUseGooglePlayServices()} succeeds, and that check is
 * {@code GoogleApiAvailability.isGooglePlayServicesAvailable()} -- a package lookup for
 * com.google.android.gms. The 0002 patch answers that lookup from the host, so a clone
 * believes Play services is usable and shows the sign-in promo, even though GMS sign-in
 * cannot actually work in a container (the caller-identity boundary). Hiding the host
 * platform packages from a Chrome guest restores Chrome's own "Play services missing"
 * path, which shows the generic welcome/ToS page instead. No other guest is affected:
 * the system-package list (used by service binding) is untouched.
 */
public class AppSystemEnv {
    private static final List<String> sSystemPackages = new ArrayList<>();
    private static final List<String> sSuPackages = new ArrayList<>();

    private static final List<String> sPreInstallPackages = new ArrayList<>();

    /**
     * Host platform packages a guest may ask about by name and get the host's real answer.
     *
     * Deliberately separate from sSystemPackages. That list is also consulted by
     * IActivityManagerProxy when binding a service, which would move service binds off the
     * plain host path they already take today; this list is consulted only by
     * IPackageManagerProxy, so it changes what a guest can *see* and nothing about how it
     * connects.
     */
    private static final List<String> sHostPlatformPackages = new ArrayList<>();

    /** The guest whose container hides the host platform packages. */
    private static final String HIDDEN_FROM_PACKAGE = "com.android.chrome";

    static {
        sHostPlatformPackages.add("com.google.android.gms");
        sHostPlatformPackages.add("com.google.android.gsf");
        sHostPlatformPackages.add("com.android.vending");

        sSystemPackages.add("android");
        sSystemPackages.add("com.google.android.webview");
        sSystemPackages.add("com.google.android.webview.dev");
        sSystemPackages.add("com.google.android.webview.beta");
        sSystemPackages.add("com.google.android.webview.canary");
        sSystemPackages.add("com.android.webview");
        sSystemPackages.add("com.android.camera");
        sSystemPackages.add("com.android.talkback");
        sSystemPackages.add("com.miui.gallery");

        sSystemPackages.add("com.google.android.inputmethod.latin");

        sSystemPackages.add("com.huawei.webview");

        sSystemPackages.add("com.coloros.safecenter");

        sSuPackages.add("com.noshufou.android.su");
        sSuPackages.add("com.noshufou.android.su.elite");
        sSuPackages.add("eu.chainfire.supersu");
        sSuPackages.add("com.koushikdutta.superuser");
        sSuPackages.add("com.thirdparty.superuser");
        sSuPackages.add("com.yellowes.su");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && Build.VERSION.SDK_INT < 29) {
        } else {
        }
    }

    public static boolean isOpenPackage(String packageName) {
        return sSystemPackages.contains(packageName);
    }

    public static boolean isOpenPackage(ComponentName componentName) {
        return componentName != null && isOpenPackage(componentName.getPackageName());
    }

    public static boolean isHostPlatformPackage(String packageName) {
        return sHostPlatformPackages.contains(packageName);
    }

    /**
     * Whether a by-name PackageManager query for this package should be answered by the
     * host instead of denied. Used only on package-visibility paths.
     */
    public static boolean isVisibleHostPackage(String packageName) {
        if (isHostPlatformPackage(packageName) && hidesHostPlatformPackages()) {
            return false;
        }
        return isOpenPackage(packageName) || isHostPlatformPackage(packageName);
    }

    public static boolean isVisibleHostPackage(ComponentName componentName) {
        return componentName != null && isVisibleHostPackage(componentName.getPackageName());
    }

    public static boolean isBlackPackage(String packageName) {
        if (BlackBoxCore.get().isHideRoot() && sSuPackages.contains(packageName)) {
            return true;
        }
        return false;
    }

    public static List<String> getPreInstallPackages() {
        return sPreInstallPackages;
    }

    /**
     * True only while this guest is the one the platform packages are hidden from.
     *
     * {@link BlackBoxCore#getAppPackageName()} answers with the running guest's package and
     * is null in the host/server process, where this is only ever a no-op.
     */
    private static boolean hidesHostPlatformPackages() {
        return HIDDEN_FROM_PACKAGE.equals(BlackBoxCore.getAppPackageName());
    }
}
