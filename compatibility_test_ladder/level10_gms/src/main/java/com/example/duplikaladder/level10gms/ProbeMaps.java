package com.example.duplikaladder.level10gms;

import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.MapsInitializer;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * P15 — the Google Maps SDK, taken apart into stages.
 *
 * <p>Maps is the most demanding Google SDK a guest is likely to meet: it loads a Chimera
 * renderer module into the process (P13), inflates native views from that module's
 * resources, and authorises the calling app against an API key registered to a package name
 * and signing certificate. "Maps works / does not work" is therefore a useless verdict, and
 * this probe deliberately refuses to produce one. It measures four stages that fail for
 * different reasons and have different classifications:
 *
 * <ol>
 *   <li><b>SDK initialisation</b> — {@code MapsInitializer.initialize}. Pulls the renderer
 *       module. Nothing here is caller-attributed.</li>
 *   <li><b>MapView construction</b> — instantiating the view. Exercises the module's
 *       resources and class loader inside the guest process, which is where a
 *       virtualization defect in asset or resource handling would appear.</li>
 *   <li><b>GoogleMap callback</b> — {@code getMapAsync}. The renderer is live.</li>
 *   <li><b>A basic map operation</b> — a camera move. Deliberately not a location call:
 *       {@code setMyLocationEnabled} is permission- and identity-bound and is exactly the
 *       kind of thing this phase is not chasing.</li>
 * </ol>
 *
 * <h2>On the API key — read this before interpreting a failure</h2>
 *
 * <p>The manifest declares a <b>placeholder key registered to nobody</b>
 * ({@code AIzaSyPLACEHOLDER-NOT-A-REAL-KEY-diagnostics-only}), and this is deliberate in
 * both directions.
 *
 * <p>A real key is issued against a package name and signing certificate. Borrowing
 * someone's key, or using one registered to this diagnostic's identity, would be the
 * identity manoeuvre the brief forbids — and would not work anyway, because the container
 * cannot present that identity to Google. So no real key is used and none must be added.
 *
 * <p>But declaring <em>nothing</em> turned out to measure nothing. The first host run
 * (recorded in {@code evidence/.../host-p15-maps-no-key.txt}) failed at stage 1 with
 * {@code RuntimeException: API key not found} — a check the SDK makes against the app's own
 * manifest, before any Google contact at all. With that, host and guest fail identically at
 * the first step and the interesting stages are never reached.
 *
 * <p>The placeholder gets past that local presence check and <b>bypasses no validation</b>:
 * Google's authorisation still runs and is still expected to fail, identically in both
 * columns, because the key belongs to no project. What it buys is the stages in between —
 * renderer module load, resource access, view inflation — which are the parts a container
 * can actually break. The host column remains the control, so the reading rule is
 * unchanged: <b>a stage that passes on host and fails in the guest is a virtualization
 * defect; a stage that fails in both is the key.</b>
 */
final class ProbeMaps {

    private static final long STAGE_TIMEOUT_MS = 12_000;

    private ProbeMaps() {
    }

    static TestResult run(Context context) {
        DiagLog.section("P15 — Google Maps SDK, staged (placeholder key; authorisation expected to fail)");
        StringBuilder detail = new StringBuilder();

        detail.append("API key: PLACEHOLDER registered to nobody. Authorisation is EXPECTED\n");
        detail.append("to fail in both columns; the stages before it are the measurement.\n\n");

        // Stage 1 — renderer module.
        AtomicReference<String> initResult = new AtomicReference<>("not reached");
        CountDownLatch initLatch = new CountDownLatch(1);
        runOnMain(() -> {
            try {
                MapsInitializer.initialize(context, MapsInitializer.Renderer.LATEST, renderer ->
                        initResult.set("callback renderer=" + renderer));
                if ("not reached".equals(initResult.get())) {
                    initResult.set("initialize returned; renderer callback not yet fired");
                }
            } catch (Throwable e) {
                initResult.set("threw " + e.getClass().getSimpleName() + ": " + e.getMessage());
            } finally {
                initLatch.countDown();
            }
        });
        await(initLatch);
        emit(detail, "stage1.MapsInitializer.initialize", initResult.get());

        // Stage 2 + 3 — view construction and the renderer callback. Both must happen on
        // the main thread, and MapView requires its lifecycle callbacks to be driven by
        // hand when it is not hosted in a real Activity layout.
        AtomicReference<String> viewResult = new AtomicReference<>("not reached");
        AtomicReference<String> mapResult = new AtomicReference<>("not reached");
        AtomicReference<String> opResult = new AtomicReference<>("not reached");
        CountDownLatch mapLatch = new CountDownLatch(1);

        runOnMain(() -> {
            MapView mapView;
            try {
                mapView = new MapView(context);
                mapView.onCreate(new Bundle());
                viewResult.set("constructed " + mapView.getClass().getName());
            } catch (Throwable e) {
                viewResult.set("threw " + e.getClass().getSimpleName() + ": " + e.getMessage());
                // The stack matters as much as the message: it names which code performs
                // the check and therefore which lookup a container has to satisfy. P17
                // showed getPackageInfo(GET_PERMISSIONS) is answered correctly in a guest,
                // so whatever this frame calls is a different path.
                DiagLog.failure(DiagLog.TAG, "P15 stage2 MapView construction failed", e);
                mapLatch.countDown();
                return;
            }
            try {
                mapView.getMapAsync(googleMap -> {
                    mapResult.set("GoogleMap delivered " + googleMap.getClass().getName());
                    opResult.set(basicOperation(googleMap));
                    mapLatch.countDown();
                });
            } catch (Throwable e) {
                mapResult.set("getMapAsync threw " + e.getClass().getSimpleName()
                        + ": " + e.getMessage());
                mapLatch.countDown();
            }
        });
        await(mapLatch);

        emit(detail, "stage2.MapView construction", viewResult.get());
        emit(detail, "stage3.GoogleMap callback", mapResult.get());
        emit(detail, "stage4.camera operation", opResult.get());

        boolean initOk = !initResult.get().startsWith("threw");
        boolean viewOk = viewResult.get().startsWith("constructed");
        boolean mapOk = mapResult.get().startsWith("GoogleMap delivered");

        detail.append('\n').append("READING\n");
        detail.append("Compare stage by stage against the host run.\n");
        detail.append("  A stage that passes on host and fails in guest -> virtualization defect.\n");
        detail.append("  A stage that fails in BOTH -> the unregistered key, not virtualization.\n");

        Verdict verdict;
        String summary;
        if (initOk && viewOk && mapOk) {
            DiagLog.line(DiagLog.TAG, "P15 the Maps SDK initialised, constructed a MapView and"
                    + " delivered a GoogleMap for this caller. Rendering authorisation is a"
                    + " separate, key-bound question this fixture deliberately cannot answer.");
            detail.append("The SDK loaded, inflated and produced a live GoogleMap.\n");
            verdict = Verdict.PASS;
            summary = "SDK initialised, MapView built, GoogleMap delivered";
        } else if (initOk && viewOk) {
            verdict = Verdict.PARTIAL;
            summary = "SDK and MapView OK; no GoogleMap callback";
        } else if (initOk) {
            verdict = Verdict.PARTIAL;
            summary = "SDK initialised; MapView construction failed";
        } else {
            verdict = Verdict.FAIL;
            summary = "Maps SDK did not initialise";
        }

        DiagLog.line(DiagLog.TAG, "P15 verdict=" + verdict + " (" + summary + ")");
        return TestResult.of("P15", "Google Maps SDK", verdict, summary, detail.toString());
    }

    /**
     * A camera move — the most basic map operation there is, and pointedly not a location
     * one. Reading the camera position back is what distinguishes a real operation from a
     * call that was accepted and dropped.
     */
    private static String basicOperation(GoogleMap map) {
        try {
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(51.5074, -0.1278), 10f));
            CameraPosition position = map.getCameraPosition();
            return "moveCamera OK, readback zoom=" + position.zoom
                    + " lat=" + String.format(java.util.Locale.US, "%.4f", position.target.latitude);
        } catch (Throwable e) {
            return "threw " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    private static void runOnMain(Runnable action) {
        new Handler(Looper.getMainLooper()).post(action);
    }

    private static void await(CountDownLatch latch) {
        try {
            latch.await(STAGE_TIMEOUT_MS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static void emit(StringBuilder detail, String key, String value) {
        DiagLog.line(DiagLog.TAG, "P15 " + key + " = " + value);
        detail.append(key).append(" = ").append(value).append('\n');
    }
}
