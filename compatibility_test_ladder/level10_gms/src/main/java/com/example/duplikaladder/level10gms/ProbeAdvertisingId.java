package com.example.duplikaladder.level10gms;

import android.content.Context;

import com.google.android.gms.ads.identifier.AdvertisingIdClient;

/**
 * P1 — a real Google API reached by a DIRECT AIDL SERVICE BIND, not by the GoogleApi
 * client framework.
 *
 * <p>This is the discriminator the whole of Level 10 is built around. Level 9 established
 * two facts that look contradictory: a guest can bind
 * {@code com.google.android.gms/.chimera.GmsApiService} and receive a live
 * {@code IGmsServiceBroker}, yet a {@code GoogleApi} client call comes back
 * {@code DEVELOPER_ERROR}. Those two live at different layers, and a single probe cannot
 * tell them apart.
 *
 * <p>{@link AdvertisingIdClient#getAdvertisingIdInfo(Context)} separates them. It performs
 * a plain {@code bindService} to {@code com.google.android.gms.ads.identifier.service.START}
 * and talks its own AIDL over the returned binder. It never constructs a
 * {@code GoogleApi}, so it never sends the framework's {@code GetServiceRequest} carrying
 * the caller's package name for validation against the Binder calling UID.
 *
 * <p>So the pair (P1, P2) is a controlled comparison. Both need no Google account, no API
 * key and no runtime permission; they differ only in which client layer they use:
 *
 * <ul>
 *   <li>P1 succeeds and P2 fails → the boundary is the GoogleApi framework's caller
 *       validation, and plain GMS AIDL services are usable from a container.</li>
 *   <li>both fail → the boundary is lower, at any GMS call that identifies its caller.</li>
 *   <li>both succeed → Level 9's DEVELOPER_ERROR was specific to that one API.</li>
 * </ul>
 *
 * <p>Nothing is spoofed to obtain a result. The advertising ID returned is the host
 * device's real one; it is a resettable, non-permanent identifier that any app may read,
 * and it is deliberately NOT written to the log — only its presence, length and the
 * limit-ad-tracking flag are recorded, because the value is a device identifier and the
 * evidence files do not need it.
 */
final class ProbeAdvertisingId {

    private ProbeAdvertisingId() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P1 — direct AIDL GMS service (AdvertisingIdClient, no framework)");
        StringBuilder detail = new StringBuilder();
        detail.append("path: plain bindService -> com.google.android.gms.ads.identifier.service.START\n");
        detail.append("client layer: none (own AIDL) — does NOT use the GoogleApi framework\n");
        detail.append("credentials: no account, no API key, no runtime permission\n");

        // getAdvertisingIdInfo is documented as blocking and must not run on the main
        // thread; it is called from the worker the runner already provides.
        try {
            long started = System.currentTimeMillis();
            AdvertisingIdClient.Info info = AdvertisingIdClient.getAdvertisingIdInfo(context);
            long elapsed = System.currentTimeMillis() - started;

            if (info == null) {
                DiagLog.line(DiagLog.TAG, "AdvertisingIdClient returned null Info");
                detail.append("Info was null\n");
                return finish(Verdict.FAIL, "bind returned no Info object", detail);
            }

            String id = info.getId();
            boolean present = id != null && !id.isEmpty();
            // The identifier itself is not logged. Its presence and shape are enough to
            // prove the AIDL round-trip completed, and the value is a device identifier.
            DiagLog.line(DiagLog.TAG, "AdvertisingIdClient OK in " + elapsed + " ms"
                    + " idPresent=" + present
                    + " idLength=" + (id == null ? 0 : id.length())
                    + " limitAdTrackingEnabled=" + info.isLimitAdTrackingEnabled());
            detail.append("round-trip completed in ").append(elapsed).append(" ms\n");
            detail.append("idPresent=").append(present)
                    .append(" idLength=").append(id == null ? 0 : id.length())
                    .append(" limitAdTracking=").append(info.isLimitAdTrackingEnabled()).append('\n');
            detail.append("(the identifier value is deliberately not recorded)\n");

            if (!present) {
                // A blank id with limit-ad-tracking on is a legitimate answer from the
                // service, so the call still worked; it is only PARTIAL because the probe
                // cannot then confirm a payload came back.
                return finish(Verdict.PARTIAL,
                        "service answered but returned an empty identifier", detail);
            }
            return finish(Verdict.PASS,
                    "direct-AIDL GMS service call completed in the guest", detail);
        } catch (Throwable e) {
            // GooglePlayServicesNotAvailableException / GooglePlayServicesRepairableException
            // and IOException all land here, as does NoClassDefFoundError under a bad R8
            // configuration. The class name is recorded so those stay distinguishable.
            DiagLog.failure(DiagLog.TAG, "AdvertisingIdClient failed", e);
            detail.append("threw ").append(e.getClass().getName())
                    .append(": ").append(e.getMessage()).append('\n');
            return finish(Verdict.FAIL,
                    "direct-AIDL call threw " + e.getClass().getSimpleName(), detail);
        }
    }

    private static TestResult finish(Verdict verdict, String summary, StringBuilder detail) {
        DiagLog.line(DiagLog.TAG, "P1 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P1", "Direct AIDL GMS service", verdict, summary, detail.toString());
    }
}
