# Host vs guest comparison — LocationServices, Level 10 Phase 8
# OnePlus CPH2605 / Android 15 / API 35 / arm64-v8a, KNOJORMFV4GERKHM, 2026-09-09
# Same APK in both columns (com.example.duplikaladder.level10gms), so anything
# static about the app -- manifest, permissions declared, targetSdk, GMS library
# versions -- is identical by construction and cannot be the differentiator.

Measurement                                    | HOST                               | GUEST
-----------------------------------------------+------------------------------------+-----------------------------------
isGooglePlayServicesAvailable                  | 0 SUCCESS                          | 0 SUCCESS
GMS versionName                                | 26.32.34                           | 26.32.34 (identical)
PackageManager coherence (P0)                  | PASS                               | PASS
GMS declared services visible                  | 370                                | 370
GoogleLocationManagerService.START             | matches=1                          | matches=1 (same component)
auth.api.signin.service.START                  | matches=1                          | matches=1
common.service.START                           | matches=1                          | matches=1
appset.service.START                           | matches=0                          | matches=0 (chimera-routed)
Direct-AIDL GMS call (P1)                      | PASS                               | PASS
GoogleApi framework, AppSet (P2)               | PASS                               | PASS
LocationServices (P3)                          | PASS                               | FAIL DEVELOPER_ERROR
checkApiAvailability(LocationSvcs)             | available                          | DEVELOPER_ERROR
Device location_mode                           | 3 (on)                             | 3 (same device)
Caller uid GMS observes                        | level10gms uid                     | co.tdevs.duplika uid 10963

## Everything observable is identical except the Binder caller identity.

## Experiment 1 — host caller's location permission: REJECTED as cause
Duplika declares ACCESS_FINE/COARSE_LOCATION (inherited from Bcore, deliberately
not stripped) but they were granted=false. Granted them through the system
Settings UI (an ordinary user grant of a declared permission -- no spoofing),
re-ran the identical guest clone:
  before: ACCESS_FINE_LOCATION granted=false -> P3 FAIL DEVELOPER_ERROR
  after:  ACCESS_FINE_LOCATION granted=true  -> P3 FAIL DEVELOPER_ERROR (identical)
The grant was reverted afterwards; the device was left as found.
=> The host caller's location-permission state is NOT the cause.

## Experiment 2 — component resolution: REJECTED as cause
The first version of the probe guessed action names that returned 0 matches on the
HOST as well, while LocationServices worked there -- so that arm measured nothing.
Corrected to the real action, the guest resolves it exactly as the host does.
=> Component/service visibility is NOT the cause.

## What remains
The failure is decided client-side, per-API, before any IPC (~20 ms, no bind in
Play services' broker log, while AppSet binds and answers in ~100 ms through the
same framework). The only measured remaining difference is the caller identity the
GMS process resolves over Binder. NOT confirmed -- see root-cause section of
docs/level10-location-services-investigation.md.
