# Level 10 — GMS provider architecture

Companion to `level10-gms-provider-audit.md` (what existed before) and
`level10-gms-provider-migration.md` (what changed).

## Why this exists

To let a second Google-service backend be added later without touching the Real GMS path
that works. No microG is implemented.

**Updated by Phase 7 (provisioning retirement).** The abstraction phase itself changed no
behaviour. Phase 7 then retired the legacy container-GMS-provisioning opt-in that this
abstraction had made safe to reason about — see `level10-gms-provider-migration.md`.

## The one constraint that shaped everything

The audit established that **Duplika's production code makes no Google API calls of its
own**. No `GoogleApiAvailability`, no `GoogleApi` client, no `LocationServices`, no
Firebase; nothing in `pubspec.yaml`. Google APIs are called by the **guest apps** inside
containers, directly against the host's real Play services through the engine's IPC.
Duplika is the substrate under that call path, not a participant in it.

So the capability model has exactly two entries, because that is exactly how many
Google-service operations Duplika performs. `LocationServiceCapability`,
`MessagingServiceCapability` and `GoogleApiCapability` were considered and **deliberately
not created** — they would abstract nothing, and an interface with no implementation and no
caller invites a future provider to implement a contract nobody verified.

## Architecture

```
Flutter (Dart, GetX)
  compatibility_sheet  ->  CloneDecision { proceed }
        |                  (no GMS opt-in: retired in Phase 7)
        v  MethodChannel arg "installGms"  -- always false from production flows
  NativeBridge.kt  ->  RealVirtualizationEngine.kt  ->  VirtualAppInstaller.kt
        |
        |  provisionGmsIfRequested(virtualUserId, wanted = false)
        v
  GoogleServiceProviderResolver.resolve(GmsProviderMode)      <-- the only decision point
        |
        +--> RealGmsProvider ------> VirtualizationEngineAdapter ---> bcore.aar
        |      (default; works)        .isGmsSupported()
        |                              .installGms(userId)
        +--> MicroGProvider            (placeholder; no implementation)
        |
        +--> UnsupportedProvider       (deterministic refusals)
```

The abstraction sits **below** the Flutter boundary, in Kotlin, next to the engine calls it
adapts. No Android implementation detail is exposed to Flutter.

The Dart layer retains an `installGms` parameter through the engine interface, bridge and
controllers, but **no production flow sets it** — it is documented as retired/diagnostics
only, so the native capability stays reachable without a user-facing path to it.

## Capability model

| Capability | Meaning | Backed by | Status |
| --- | --- | --- | --- |
| `HOST_GMS_PRESENCE` | Does the **host** have legitimate Google Play services | `adapter.isGmsSupported()` | **Supported** — this is how host GMS passthrough is gated |
| `CONTAINER_GMS_PROVISIONING` | Provision Google packages **into a container** | `adapter.installGms(userId)` | **RETIRED (Phase 7)** — no production flow requests it; modelled so a provider can decline it explicitly |

### Why `CONTAINER_GMS_PROVISIONING` is retired but still modelled

Phase 7 removed the only way to request it (the compatibility sheet checkbox). It stays in
the capability enum deliberately: the honest answer to "can you provision a container?" is
better than the capability silently not existing, and it is the hook a future provider would
use if it ever had a legitimate reason to provision. Retired means *unreachable from
production*, not *deleted*.

Two measured reasons it was retired:

- **It shadowed the path that works.** Every hook in the engine's `IPackageManagerProxy`
  answers from the container first and only falls back to the host. A provisioned container
  therefore answered GMS queries from its own copy, and the host's genuine Play services was
  never consulted — so opting in *removed* working host passthrough from that clone.
- **The copy could not start.** It failed its Chimera module bootstrap
  (`app_chimera/current_config.fb: ENOENT`, then `GmsProxy: Failed to get gms service
  binder`); availability came back `SERVICE_INVALID(9)`.

`capabilities()` is **environment-dependent**, not a static declaration: `RealGmsProvider`
on a device without Play services reports an *empty* set rather than claiming a capability
it would then fail. An empty set is a legitimate answer and callers handle it.

`HOST_GMS_PRESENCE` being available is a weaker claim than "Google APIs work in a guest".
Level 10 evidence is explicit that some do (`AdvertisingIdClient`, AppSet ID) and some do
not (`LocationServices`).

## Provider lifecycle

Providers are **stateless and cheap**; there is no init/shutdown. The resolver constructs
nothing lazily and caches nothing.

`resolve()` is deliberately **not memoised**. Play services can be disabled or uninstalled
while Duplika runs, so a cached provider could assert a backend that has since gone — the
exact fabricated-availability failure this layer exists to prevent. `RealGmsProvider` asks
the engine on every `availability()` call for the same reason. Each check is a cheap engine
query.

## Selection rules (deterministic)

| Mode | Outcome |
| --- | --- |
| `AUTO` (default) | Real GMS if the host genuinely has it → else a real microG implementation if one ever exists → else `UnsupportedProvider`. |
| `REAL_GMS` | Real GMS if genuinely available; else `UnsupportedProvider` with a stated reason. **No fallback.** |
| `MICROG` | microG if genuinely available (never, today); else `UnsupportedProvider` saying it is not implemented. **Never falls back to Real GMS** — someone who asked for microG and quietly got Google's Play services has been given the opposite of what they asked for. |
| `DISABLED` | `UnsupportedProvider`, always. |

A provider is selected only on the strength of its **own** report, and every mode is checked
against that report:

```kotlin
provider.availability() == AVAILABLE && provider.capabilities().isNotEmpty()
```

The second clause is the important one: a provider claiming `AVAILABLE` while reporting no
capabilities cannot serve anything, and picking it would push failures to the call site
instead of returning an honest `UnsupportedProvider`. **No mode can conjure a capability.**
This is the property the unit tests pin down, and it is what makes the layer safe to extend.

### Scope of `DISABLED`

It governs what *Duplika* does — host-presence reporting and container provisioning. It
cannot and does not stop a guest app reaching the host's Play services through the engine;
that path does not run through this abstraction. Reading `DISABLED` as "guests get no
Google services" would be wrong, and the returned reason string says so.

## Result model

`ProviderResult<T>` — expected capability failures are values, not exceptions:

| Case | Means |
| --- | --- |
| `Success` | Completed; carries the value. |
| `Unavailable` | Implemented, but the environment cannot satisfy it now. Recoverable. |
| `Unsupported` | This provider will never implement this. Stop asking. |
| `NotImplemented` | Intended but unwritten — what every microG call returns today. |
| `SecurityRestricted` | Needs an identity/integrity guarantee a third-party container cannot legitimately give. **Nothing returns this today**; the case exists so a future account- or attestation-bound capability has somewhere honest to land instead of being reported as `Error`. |
| `Error` | Something genuinely went wrong. |

Every non-success names both the provider and the capability, so a log line says *who*
refused *what* without needing the call site.

`NotImplemented` is kept distinct from `Unavailable` on purpose: "not written" and "not
present on this device" are different facts, and collapsing them would let an unimplemented
provider look like a device problem.

### Diagnostics hygiene

`redactedDiagnostics` drops any value whose key matches a forbidden marker (`token`,
`oauth`, `bearer`, `credential`, `password`, `secret`, `account`, `email`, `advertisingId`,
`appsetId`) and records the drop in place of the value. The diagnostics this phase actually
produces contain no such values — it is a guard so a future call site cannot quietly start
leaking one. Call sites pass `redactedDiagnostics`, never `rawDiagnostics`.

## Real GMS integration

`RealGmsProvider` is an **adapter, not a reimplementation**. Both operations forward to the
same `VirtualizationEngineAdapter` calls `VirtualAppInstaller` made directly before this
phase, in the same order with the same arguments. It touches no package identity, UID
mapping, signature, certificate, account identity, Play Integrity or security check — it
cannot, because it only forwards two calls whose implementations live in the engine and were
not modified.

It does **not** make the guest see Play services. That is the engine's host-platform package
visibility patch (`engine-patches/0002-host-platform-package-visibility.patch`), which is
unrelated to and unaffected by this class.

One defensive detail: `isGmsSupported()` is wrapped so an engine surprise cannot propagate
into selection. An unreadable answer is treated as "no host GMS", which declines
provisioning rather than attempting it blind.

## microG placeholder

`MicroGProvider` reports `NOT_IMPLEMENTED`, **no** capabilities, and
`ProviderResult.NotImplemented` for every operation.

`availability()` is **unconditional — not a detection**. Detecting microG would imply the
rest of the class could serve it, and it cannot; a provider reporting `AVAILABLE` while
every operation returns `NotImplemented` is exactly the "pretend the APIs work" failure the
phase forbids. Because it reports no capabilities, `AUTO` can never select it.

Nothing is bundled, downloaded, installed or referenced. No proprietary Google component is
copied.

A real attempt to implement this — a bundled microG provisioned into a container — was made
and then **parked**, because guest apps' signature verification rejects an honestly-signed
microG. The implementation, the three measured blockers and what would have to change are
recorded in `docs/microg-integration.md`; the branch is `spike/microg-provider` (`f9fb159`).

## Future microG implementation plan

The order matters, and it is the opposite of what is tempting:

1. Make `availability()` a real detection of an actually-installed microG.
2. Implement **one** capability, and add it to `capabilities()` **only after it is verified
   on a device**.
3. Leave every unimplemented capability returning `NotImplemented`.
4. Add a Flutter-facing mode toggle only once there is a second backend that genuinely
   works — until then it is UI for a choice with one legitimate answer.

**The single most damaging possible change to that file** is adding a capability to
`capabilities()` before it works: `AUTO` would then prefer a backend that cannot serve.

## Adding a new capability

Only when Duplika itself starts calling such an API. Then:

1. Add the entry to `GmsCapability` with a comment saying what backs it.
2. Add the method to `GoogleServiceProvider`.
3. Implement it in `RealGmsProvider` as an adapter over whatever real call exists.
4. Return `NotImplemented` from `MicroGProvider` and `Unavailable` from
   `UnsupportedProvider`.
5. Include it in `RealGmsProvider.capabilities()` **only** when genuinely serveable.

If the capability turns out to need an identity assertion, the honest answer is
`SecurityRestricted` — not an attempt.

## Security boundaries

Unchanged by this phase, and restated because the abstraction must not become a place to
erode them:

- No spoofing of package identity, UID, signatures or certificates.
- No fake Google services, fake Play Store, fake tokens or fake accounts.
- No Play Integrity, SafetyNet, device-attestation or account-auth bypass.
- Google account sign-in and OAuth-bound APIs remain **UNSUPPORTED / SECURITY-BOUNDARY**.
- A provider may never fabricate availability. This is the one rule the whole layer exists
  to enforce, and `canServe` is where it is enforced.
