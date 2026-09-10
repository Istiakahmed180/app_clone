package com.example.duplikaladder.level10gms;

import android.content.ContentProviderClient;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.ProviderInfo;
import android.content.pm.ResolveInfo;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Build;
import android.os.Process;

import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * P9 — the local-input differential.
 *
 * <p>Phases 8-10 established the shape of the failure but not its cause. What is
 * <em>confirmed</em>: three attribution-sensitive {@code GoogleApi}s (LocationServices,
 * ActivityRecognition, SmsRetriever — two artifacts, two gating mechanisms) are refused in
 * a guest with {@code DEVELOPER_ERROR} in 1-20 ms with <em>no service bind at all</em>,
 * while two non-attribution-sensitive APIs are served normally. What is
 * <em>unknown</em> (root-cause-analysis.md Finding 4): which input the client library reads
 * to make that decision.
 *
 * <p>This probe attacks that question from the only direction available without
 * instrumenting Google's closed client library: <b>the decision is made inside the guest
 * process with no IPC to Play services, so every input to it must be data the client read
 * from the local — and therefore virtualized — Android framework.</b> If some input differs
 * between host and guest, it is the lead. If none of them differ, that is itself decisive:
 * the decision is not made from locally-readable package data at all.
 *
 * <p>That framing also settles the classification question the brief cares about. Play
 * services is never consulted, so the refusal cannot be Play services enforcing a policy;
 * it is the bundled client library reasoning about what it can see. So the honest question
 * is not "is Google rejecting us" but "is Duplika giving this library a wrong answer about
 * the real host GMS installation" — the same shape as the Level 9 package-visibility fix.
 *
 * <p><b>Read-only.</b> Every call is a query. Nothing is modified, nothing is spoofed, no
 * account, token or credential is touched, and no value that could identify a user is
 * logged — certificates are reported as SHA-256 digests, which is how the platform's own
 * {@code checkSignatures} comparison is expressed and is not a secret.
 */
final class ProbeLocalInputs {

    /**
     * Chimera's component-router provider authority, read off the device
     * ({@code dumpsys package providers}). Modern Play services dispatches GoogleApi calls
     * through Chimera modules rather than manifest components — which is why P6 found
     * {@code appset.service.START} resolving to <em>zero</em> manifest services on the host
     * while the API works there. If the client consults this provider before connecting, a
     * guest that cannot reach it has grounds to declare an API unavailable locally, which
     * is exactly the observed no-bind signature.
     */
    private static final String CHIMERA_ROUTER_AUTHORITY =
            "com.google.android.chimera.router.remapping1";

    private static final String GMS = "com.google.android.gms";

    /** Providers a GoogleApi client could plausibly consult, by authority. */
    private static final String[][] PROVIDERS = {
            { "Chimera component router", CHIMERA_ROUTER_AUTHORITY },
            { "GMS settings/broker", "com.google.android.gms.settings.gms" },
            { "GMS phenotype (flags)", "com.google.android.gms.phenotype" },
            { "GMS chimera modules", "com.google.android.gms.chimera" },
    };

    /**
     * Service actions, paired with the probe outcome they belong to, so the differential
     * reads as a comparison rather than a list. Names are the ones P6 corrected in Phase 8.
     */
    private static final String[][] ACTIONS = {
            { "LocationServices (FAILS in guest)",
              "com.google.android.location.internal.GoogleLocationManagerService.START" },
            { "ActivityRecognition (FAILS in guest)",
              "com.google.android.gms.location.ACTIVITY_RECOGNITION" },
            { "SmsRetriever (FAILS in guest)",
              "com.google.android.gms.auth.api.phone.service.SmsRetrieverApiService.START" },
            { "AppSet (WORKS in guest)", "com.google.android.gms.appset.service.START" },
            { "AdvertisingId (WORKS in guest, direct AIDL)",
              "com.google.android.gms.ads.identifier.service.START" },
    };

    private ProbeLocalInputs() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P9 — local-input differential (what the client can read without IPC)");
        StringBuilder detail = new StringBuilder();
        PackageManager pm = context.getPackageManager();

        callerIdentity(context, detail);
        signatures(context, pm, detail);
        gmsMetadata(pm, detail);
        providers(context, pm, detail);
        serviceResolution(pm, detail);

        detail.append('\n');
        detail.append("READING\n");
        detail.append("Compare this block against the host run. Any line that differs is an\n");
        detail.append("input the client library could be deciding on; if every line matches,\n");
        detail.append("the decision is not made from locally-readable package data.\n");

        DiagLog.line(DiagLog.TAG, "P9 verdict=PARTIAL (differential recorded; "
                + "interpretation requires the paired host run)");
        return TestResult.of("P9", "Local-input differential", Verdict.PARTIAL,
                "recorded; compare host vs guest", detail.toString());
    }

    /** (A) Who the client thinks it is, by every name the framework offers. */
    private static void callerIdentity(Context context, StringBuilder detail) {
        String opPackage = "n/a";
        String attributionTag = "n/a";
        try {
            opPackage = context.getOpPackageName();
        } catch (Throwable ignored) {
            // Recorded as n/a rather than swallowed silently; see the detail block.
        }
        if (Build.VERSION.SDK_INT >= 30) {
            try {
                attributionTag = String.valueOf(context.getAttributionTag());
            } catch (Throwable ignored) {
                // Same.
            }
        }
        emit(detail, "caller.packageName", context.getPackageName());
        emit(detail, "caller.opPackageName", opPackage);
        emit(detail, "caller.attributionTag", attributionTag);
        emit(detail, "caller.uid", String.valueOf(Process.myUid()));
        try {
            emit(detail, "caller.applicationInfo.uid",
                    String.valueOf(context.getApplicationInfo().uid));
        } catch (Throwable e) {
            emit(detail, "caller.applicationInfo.uid", threw(e));
        }
    }

    /**
     * (B/C) The signature surface.
     *
     * <p>{@code GoogleSignatureVerifier} — used across the client libraries — checks that
     * the Play services package really is Google-signed before trusting it, and some APIs
     * additionally hash the <em>calling</em> package's certificate. Both reads go through
     * the local PackageManager, so both are candidates. Digests only; a signing certificate
     * is public, but there is no reason to put raw bytes in a log.
     */
    private static void signatures(Context context, PackageManager pm, StringBuilder detail) {
        emit(detail, "sig.self.sha256", certDigest(pm, context.getPackageName()));
        emit(detail, "sig.gms.sha256", certDigest(pm, GMS));
        emit(detail, "sig.vending.sha256", certDigest(pm, "com.android.vending"));
        try {
            emit(detail, "sig.checkSignatures(self,gms)",
                    signatureMatchName(pm.checkSignatures(context.getPackageName(), GMS)));
        } catch (Throwable e) {
            emit(detail, "sig.checkSignatures(self,gms)", threw(e));
        }
        try {
            emit(detail, "sig.checkSignatures(gms,vending)",
                    signatureMatchName(pm.checkSignatures(GMS, "com.android.vending")));
        } catch (Throwable e) {
            emit(detail, "sig.checkSignatures(gms,vending)", threw(e));
        }
    }

    /** (D/G) The Play services installation as the guest sees it. */
    private static void gmsMetadata(PackageManager pm, StringBuilder detail) {
        try {
            ApplicationInfo info = pm.getApplicationInfo(GMS, PackageManager.GET_META_DATA);
            emit(detail, "gms.uid", String.valueOf(info.uid));
            emit(detail, "gms.enabled", String.valueOf(info.enabled));
            emit(detail, "gms.sourceDir", String.valueOf(info.sourceDir));
            String version = info.metaData == null
                    ? "no metaData"
                    : String.valueOf(info.metaData.get("com.google.android.gms.version"));
            emit(detail, "gms.metaData[com.google.android.gms.version]", version);
        } catch (Throwable e) {
            emit(detail, "gms.applicationInfo", threw(e));
        }
        try {
            String[] packages = pm.getPackagesForUid(uidOf(pm, GMS));
            emit(detail, "gms.getPackagesForUid", join(packages));
        } catch (Throwable e) {
            emit(detail, "gms.getPackagesForUid", threw(e));
        }
    }

    /**
     * (E/F) Provider resolution <b>and</b> acquisition.
     *
     * <p>Both halves matter and they fail differently. {@code resolveContentProvider} is a
     * PackageManager lookup — it says whether the guest can <em>see</em> the provider.
     * {@code acquireContentProviderClient} actually crosses into the ActivityManager and
     * publishes a binder — it says whether the guest can <em>reach</em> it. A guest that
     * resolves a provider but cannot acquire it is the classic missing-provider-
     * virtualization signature, and it is invisible to a resolution-only probe.
     */
    private static void providers(Context context, PackageManager pm, StringBuilder detail) {
        for (String[] entry : PROVIDERS) {
            String label = entry[0];
            String authority = entry[1];
            String resolved;
            try {
                ProviderInfo info = pm.resolveContentProvider(authority, 0);
                resolved = info == null
                        ? "NOT RESOLVED"
                        : info.packageName + "/" + info.name + " exported=" + info.exported;
            } catch (Throwable e) {
                resolved = threw(e);
            }
            emit(detail, "provider.resolve[" + authority + "]", resolved + "   (" + label + ")");

            String acquired;
            ContentProviderClient client = null;
            try {
                client = context.getContentResolver()
                        .acquireUnstableContentProviderClient(Uri.parse("content://" + authority));
                acquired = client == null ? "NULL (could not acquire)" : "acquired";
            } catch (Throwable e) {
                acquired = threw(e);
            } finally {
                if (client != null) {
                    client.close();
                }
            }
            emit(detail, "provider.acquire[" + authority + "]", acquired);
        }
    }

    /**
     * (H) Service resolution for the failing and working APIs, with {@code GET_META_DATA}.
     *
     * <p>P6 measured this with flags {@code 0}. The meta-data is added here because Chimera
     * carries its module routing in service meta-data, so a component that resolves but
     * whose meta-data the guest cannot read would look identical to P6 and different to the
     * client library.
     */
    private static void serviceResolution(PackageManager pm, StringBuilder detail) {
        for (String[] entry : ACTIONS) {
            String label = entry[0];
            String action = entry[1];
            String value;
            try {
                Intent intent = new Intent(action).setPackage(GMS);
                List<ResolveInfo> found =
                        pm.queryIntentServices(intent, PackageManager.GET_META_DATA);
                if (found == null || found.isEmpty()) {
                    value = "matches=0";
                } else {
                    ResolveInfo first = found.get(0);
                    int metaCount = first.serviceInfo == null || first.serviceInfo.metaData == null
                            ? 0
                            : first.serviceInfo.metaData.size();
                    value = "matches=" + found.size()
                            + " component=" + (first.serviceInfo == null
                                    ? "null" : first.serviceInfo.name)
                            + " metaDataKeys=" + metaCount;
                }
            } catch (Throwable e) {
                value = threw(e);
            }
            emit(detail, "service[" + action + "]", value + "   (" + label + ")");
        }
    }

    private static int uidOf(PackageManager pm, String packageName) throws Exception {
        return pm.getApplicationInfo(packageName, 0).uid;
    }

    /**
     * SHA-256 over the package's first signing certificate.
     *
     * <p>Uses the deprecated {@code GET_SIGNATURES} deliberately: it is what the client
     * libraries' own compatibility paths still call on every API level this project
     * supports, and the point of the probe is to read what <em>they</em> read.
     */
    @SuppressWarnings("deprecation")
    private static String certDigest(PackageManager pm, String packageName) {
        try {
            PackageInfo info =
                    pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES);
            Signature[] signatures = info.signatures;
            if (signatures == null || signatures.length == 0) {
                return "NO SIGNATURES";
            }
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(signatures[0].toByteArray());
            StringBuilder hex = new StringBuilder(hash.length * 2);
            for (byte b : hash) {
                hex.append(String.format(Locale.US, "%02x", b));
            }
            return hex + " (count=" + signatures.length + ")";
        } catch (Throwable e) {
            return threw(e);
        }
    }

    private static String signatureMatchName(int code) {
        switch (code) {
            case PackageManager.SIGNATURE_MATCH: return "MATCH(0)";
            case PackageManager.SIGNATURE_NEITHER_SIGNED: return "NEITHER_SIGNED(1)";
            case PackageManager.SIGNATURE_FIRST_NOT_SIGNED: return "FIRST_NOT_SIGNED(-1)";
            case PackageManager.SIGNATURE_SECOND_NOT_SIGNED: return "SECOND_NOT_SIGNED(-2)";
            case PackageManager.SIGNATURE_NO_MATCH: return "NO_MATCH(-3)";
            case PackageManager.SIGNATURE_UNKNOWN_PACKAGE: return "UNKNOWN_PACKAGE(-4)";
            default: return "code=" + code;
        }
    }

    private static String join(String[] values) {
        if (values == null) {
            return "null";
        }
        List<String> list = new ArrayList<>();
        for (String value : values) {
            list.add(value);
        }
        return list.toString();
    }

    private static String threw(Throwable e) {
        return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
    }

    /** One differential line, formatted identically in both runs so a diff is readable. */
    private static void emit(StringBuilder detail, String key, String value) {
        DiagLog.line(DiagLog.TAG_PACKAGE, "P9 " + key + " = " + value);
        detail.append(key).append(" = ").append(value).append('\n');
    }
}
