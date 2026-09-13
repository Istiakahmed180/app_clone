# Play Console — restricted-permission declarations

Paste-ready material for the Play Console **Permissions Declaration Form** and the review
notes, covering the three policy-sensitive permissions Duplika declares.

**Status: prepared, not yet submitted.** Submission needs Play Console access. The policy
quotes below were taken from the live Play Console Help pages (checked 2026-09-11):

- QUERY_ALL_PACKAGES — `support.google.com/googleplay/android-developer/answer/10158779`
- MANAGE_EXTERNAL_STORAGE — `.../answer/10467955`
- Declaration process — `.../answer/9214102`

## What each permission triggers

| Permission | Declared at | Play requirement |
| --- | --- | --- |
| `QUERY_ALL_PACKAGES` | `AndroidManifest.xml:89` | Permissions Declaration Form (App content → Permission declarations) |
| `MANAGE_EXTERNAL_STORAGE` | `AndroidManifest.xml:166` | Permissions Declaration Form, as an **exception** — app cloning is not an enumerated permitted use |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | `AndroidManifest.xml:102` | No declaration form (normal permission). Play still reviews the use case, so it must be documented in the store description and the review instructions |

The declaration form has the same shape for both permissions: state the core functionality,
justify why no privacy-friendlier API suffices, give review instructions, and link a
demonstration video. Ready-to-paste text for each field follows.

---

## 1. QUERY_ALL_PACKAGES

### How Duplika actually uses it (verified, not asserted)

The only caller is `InstalledAppsProvider.listLaunchableApps()`, which runs
`PackageManager.queryIntentActivities(ACTION_MAIN + CATEGORY_LAUNCHER)` once per picker
refresh. It reads only what a launcher already shows — label, package name, icon, version,
install/update times, shipped ABIs (`describe()` in the same file). No app's content,
account data or private files are touched. The result is processed entirely on-device:
the dependency set contains no HTTP client, no ads, no analytics and no crash reporter,
so the inventory is never transmitted, sold or shared.

### Form: core functionality

> Duplika is an app-cloning tool: it runs a second, isolated copy of any installed app on
> one device — for example two WhatsApp or Telegram accounts with separate data. Its core
> feature is the clone picker, which must show the user every launchable app installed on
> the device so they can choose what to clone. Without visibility of the installed-app
> inventory the picker is empty and the app cannot perform its main purpose at all.

### Form: why a less intrusive method is not sufficient

> Android's scoped visibility (`<queries>`) requires naming packages or intent signatures
> in advance. Any installed app is a candidate for cloning, so the set is unknowable in
> advance and every fixed allow-list silently makes arbitrary apps invisible and
> uncloneable — the app appears broken. QUERY_ALL_PACKAGES is the only mechanism that
> enumerates launchable apps on Android 11+. The use is for awareness and
> interoperability with the apps the user chooses to clone, which is the eligibility
> basis this permission is granted under.

### Honest risk note (internal, not for the form)

The enumerated permitted uses are device search, antivirus, file managers and browsers;
everything else is discretionary under "awareness or interoperability purposes". Cloning
tools are not named, but every shipping product in this category (Parallel Space, Dual
Space and similar) declares this permission, and the picker argument is the strongest one
available. Expect scrutiny; a rejection would force a redesign of the picker, so appeal
with the video before redesigning.

---

## 2. MANAGE_EXTERNAL_STORAGE

### How Duplika actually uses it (verified, not asserted)

Declared only — `AndroidManifest.xml:152-166` carries the reasoning. Duplika's own code
**never requests it at runtime** (there is no `ACTION_MANAGE_ALL_FILES_ACCESS_SETTINGS`
anywhere in the codebase; only the diagnostics probes read
`Environment.isExternalStorageManager()` as a passive state check). It is not surfaced by
the permission bridge either — it is signature/special-access, so the runtime dialog can
never deliver it.

It exists because guests run under Duplika's UID: when a cloned media player or file
manager touches shared storage, Android checks **Duplika's** grant. Removing the
declaration was tried and made the engine refuse outright —
`All files access not granted for launching: <package>` — leaving a cloned VLC stuck with
no way for the user to fix it. With the declaration present, the user can grant access
through Settings → Special app access → All files access, and only that user's chosen
clones are affected.

### Form: core functionality (exception request)

> Duplika runs user-chosen apps inside isolated containers. Containerized apps execute
> under Duplika's own UID, so when a cloned file manager, media player or document app
> accesses shared storage, Android checks Duplika's grant — the permission must be held
> by the host on behalf of the guest apps the user explicitly chooses to clone. Duplika
> itself performs no shared-storage operations: its code reads, writes, lists and uploads
> no user files, and it never requests the grant programmatically. The grant can only be
> made by the user, on the system's All files access screen.

### Form: why SAF / MediaStore are not sufficient

> The code that accesses shared storage belongs to the guest app, not to Duplika, and it
> uses the ordinary file-path APIs compiled into that app. Storage Access Framework
> requires an interactive picker per operation, which third-party guest apps do not
> implement for their internal file access, and MediaStore covers only media — a cloned
> file manager manages arbitrary documents and folders. Neither can be substituted
> without rewriting every clonable app, which is not possible for a cloning tool. Without
> the declaration the container runtime refuses to launch storage-dependent guests at
> all, so the core feature is broken for exactly the app categories users clone most.
>
> Privacy impact is mitigated: nothing is granted silently (the system owns the All files
> access screen), Duplika never exercises the grant for its own purposes, guests that do
> not declare storage needs are unaffected, and the user can revoke it at any time.

### Honest risk note (internal)

This is the highest-risk declaration of the three. Cloning is not a permitted use, so
this goes in as an exception, judged on the "no viable alternative" argument above — which
is genuine: the constraint is Android's UID model, not a design preference. **Fallback if
rejected:** remove the declaration and treat storage-dependent guests as a blocked
compatibility finding instead (the analyzer already has that machinery). That trades a
policy rejection for a real feature loss, so appeal first.

---

## 3. REQUEST_IGNORE_BATTERY_OPTIMIZATIONS

No declaration form exists for this permission — it is install-time, and the system owns
the runtime dialog. Play reviews the use case at publish, so the justification lives in
the store description (below) and in the review instructions.

### How Duplika actually uses it (verified, not asserted)

`BatteryOptimization.kt` opens `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` once, from a
dismissible first-launch banner (`docs/ONBOARDING.md`). A refusal is respected and never
re-asked automatically; where the dialog does not exist it falls back to the battery
optimisation settings list and says so; the banner stays until `isIgnoring()` confirms
the grant; the app is fully usable without it.

### Review note (paste into review instructions)

> Cloned apps run inside Duplika's process group, so Android's battery optimisation
> treats every clone as Duplika. When Doze applies to Duplika, every clone pauses with
> it: a cloned messenger stops receiving messages while the user believes it is running.
> The exemption is offered once, from a dismissible banner, through the system's own
> dialog; a refusal is respected and never re-asked. This matches the documented
> acceptable use for apps whose core function is impaired by Doze.

---

## Store description addition (required by policy)

Both declaration forms require the core functionality to be "prominently documented and
promoted in the app's description". Paste-ready paragraph:

> Duplika runs a second, isolated copy of almost any app on one device — two WhatsApp
> accounts, two game profiles, a work and a personal space — each with its own separate
> data. To let you choose what to clone, Duplika lists the apps installed on your device;
> this list never leaves your phone. Cloned apps run inside Duplika, so Android's battery
> and storage permissions apply to Duplika on their behalf: you may be asked once to
> exempt Duplika from battery optimisation so your cloned messengers keep delivering, and
> — only when you clone a file or media app — to grant All files access in Settings.
> Duplika never reads other apps' private data and contains no ads, analytics or
> trackers.

## Demonstration video (form step 4)

The form asks for a video of the feature that needs the permission. Suggested 60-second
script, one continuous recording from a cold start:

1. **0:00–0:10** — Open Duplika; the clone picker lists the device's installed apps
   (this is what QUERY_ALL_PACKAGES powers).
2. **0:10–0:25** — Pick an app; the compatibility sheet appears; create the clone.
3. **0:25–0:35** — Launch the clone; it opens in its own container with fresh, separate
   data.
4. **0:35–0:45** — Show the battery banner; tap it; the system's own Doze-exemption
   dialog appears.
5. **0:45–0:60** — Settings → Special app access → All files access → Duplika (grant
   manually); launch the cloned media app and play a file from shared storage.

## Data safety linkage

The Data safety form must stay consistent with these declarations. The installed-app
inventory is queried and displayed on-device and never leaves the device (no network
egress exists in the app), so under Play's definition of "collection" (transmission off
the device) it is **not collected**. The prominent-disclosure requirement attached to
QUERY_ALL_PACKAGES is **implemented**: `DataDisclosure`
(`lib/features/onboarding/widgets/data_disclosure.dart`) gates the app on first launch,
before the clone picker — and therefore before any installed-app read — is reachable, with
an explicit *Agree and continue*. See `docs/ONBOARDING.md`. The disclosure and the Data
safety form must still be kept in step whenever the read set changes.

## Remaining steps (need Play Console access)

- [x] In-app prominent disclosure implemented — `DataDisclosure` gates first launch before
      the picker is reachable (`docs/ONBOARDING.md`).
- [ ] Submit the declaration form for `QUERY_ALL_PACKAGES` (text above).
- [ ] Submit the declaration form for `MANAGE_EXTERNAL_STORAGE` as an exception (text above).
- [ ] Record and link the demonstration video.
- [ ] Add the store-description paragraph above to the listing.
- [ ] Paste the battery review note into the review instructions.
- [ ] Align the Data safety form (installed-app inventory: not collected).
- [ ] On any rejection: appeal with the video first; the fallbacks above are the last
      resort, not the first response.
- [ ] Policy requirement: re-submit the declaration whenever the use of these
      permissions changes.
