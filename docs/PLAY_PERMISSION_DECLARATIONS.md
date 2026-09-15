# Play Console — restricted-permission declarations

What has to be filled in before Duplika can be submitted, and the wording to use. Every
"verified" claim below was checked against the code at the commit this file was written
on; where a figure is quoted, the command that produced it is given so it can be re-run.

> **Read the last section first.** Three declarations are winnable. A fourth problem —
> the SMS and Call Log permissions the virtualization engine contributes — is not a
> declaration to write but a decision to make, and nothing else on this page matters
> until it is made.

Policy references:

- Permissions Declaration Form — `support.google.com/googleplay/android-developer/answer/9214102`
- SMS and Call Log access — `support.google.com/googleplay/android-developer/answer/10208820`
- All files access — `support.google.com/googleplay/android-developer/answer/10467955`
- Foreground service types — `support.google.com/googleplay/android-developer/answer/13392821`

## What the shipped manifest actually declares

Measured on the merged release manifest, not on the source file:

```
python3 - <<'PY'
import xml.etree.ElementTree as ET
A='{http://schemas.android.com/apk/res/android}'
r=ET.parse('build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml').getroot()
print(len({p.get(A+'name') for p in r.findall('uses-permission')}))
PY
```

| | count |
| --- | --- |
| Permissions in the release APK | 115 |
| Declared by Duplika's own manifest | 8 |
| Inherited from the virtualization engine (`bcore.aar`) | 107 |
| Already stripped with `tools:node="remove"` | 138 |
| Runtime ("dangerous") permissions among the 115 | 33 |

Duplika's own eight: `QUERY_ALL_PACKAGES`, `MANAGE_EXTERNAL_STORAGE`,
`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_SPECIAL_USE`, `POST_NOTIFICATIONS`, `USE_BIOMETRIC`,
`CREDENTIAL_MANAGER_SET_ALLOWED_PROVIDERS`.

## 1. QUERY_ALL_PACKAGES

### How Duplika uses it (verified)

The only caller is `InstalledAppsProvider.listLaunchableApps()`
(`InstalledAppsProvider.kt:36`), which runs
`PackageManager.queryIntentActivities(ACTION_MAIN + CATEGORY_LAUNCHER)` once per picker
refresh. It reads only what a launcher already shows — label, package name, icon,
version, install and update times, shipped ABIs. No app's content, account data or
private files are touched.

The result stays on the device. The dependency set is `get`, `flutter_screenutil`,
`shared_preferences`, `uuid`, `file_picker`, `path_provider`, `url_launcher`, `crypto`,
`local_auth` — no HTTP client, no ads, no analytics, no crash reporter — so the inventory
cannot be transmitted, sold or shared.

### Form: core functionality

> Duplika is an app-cloning tool: it runs a second, isolated copy of an installed app on
> one device — for example two messaging accounts with separate data. Its core feature is
> the clone picker, which must show the user every launchable app installed on the device
> so they can choose what to clone. Without visibility of the installed-app inventory the
> picker is empty and the app cannot perform its main purpose at all.

### Form: why a less intrusive method is not sufficient

> Android's scoped visibility (`<queries>`) requires naming packages or intent signatures
> in advance. Any installed app is a candidate for cloning, so the set is unknowable in
> advance and every fixed allow-list silently makes arbitrary apps invisible and
> uncloneable — the app appears broken. QUERY_ALL_PACKAGES is the only mechanism that
> enumerates launchable apps on Android 11+. The use is for awareness and
> interoperability with the apps the user chooses to clone, which is the eligibility
> basis this permission is granted under.

### Risk note (internal, not for the form)

The enumerated permitted uses are device search, antivirus, file managers and browsers;
everything else is discretionary under "awareness or interoperability purposes". Cloning
tools are not named, but every shipping product in this category declares this
permission, and the picker argument is the strongest one available. Expect scrutiny; a
rejection would force a redesign of the picker, so appeal with the video before
redesigning.

## 2. MANAGE_EXTERNAL_STORAGE

### How Duplika uses it (verified)

Declared only. Duplika's own code never requests it at runtime — there is no
`ACTION_MANAGE_ALL_FILES_ACCESS_SETTINGS` anywhere in the codebase, and only the
diagnostics probes read `Environment.isExternalStorageManager()` as a passive state
check. It is special access, so no runtime dialog could deliver it in any case.

It exists because guests run under Duplika's UID: when a cloned media player or file
manager touches shared storage, Android checks **Duplika's** grant. Removing the
declaration was tried and made the engine refuse outright —
`All files access not granted for launching: <package>` — leaving a cloned VLC stuck with
no way for the user to fix it. With the declaration present the user can grant access
through Settings → Special app access → All files access, and only the clones they chose
are affected.

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

### Fallback if rejected (implemented, not planned)

Remove the declaration and let the compatibility layer refuse those apps up front.
`AppCompatibilityAnalyzer.storageFindingFor()` already does this: a guest declaring broad
storage gets `STORAGE_NOT_GRANTED` (non-blocking, points at Settings) when the host
declares but does not hold the grant, and `STORAGE_UNAVAILABLE` (**blocking**, so the
clone is refused before it is created) when the host does not declare it at all. That
trades a policy rejection for a real feature loss, so appeal first.

## 3. REQUEST_IGNORE_BATTERY_OPTIMIZATIONS

No declaration form exists — it is install-time and the system owns the runtime dialog.
Play reviews the use case at publish, so the justification belongs in the store listing
and the review instructions.

### How Duplika uses it (verified)

`BatteryOptimization.kt:46` opens `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, reached
from the Background activity row in Settings and from a one-time, dismissible home-screen
nudge that appears only once there is a clone to lose notifications for. A refusal is
respected and never re-asked automatically; where the dialog does not exist it falls back
to the battery optimisation settings list and says so; the app is fully usable without it.

### Review note (paste into review instructions)

> Cloned apps run inside Duplika's process group, so Android's battery optimisation
> treats every clone as Duplika. When Doze applies to Duplika, every clone pauses with
> it: a cloned messenger stops receiving messages while the user believes it is running.
> The exemption is offered from a Settings row and from a single dismissible prompt,
> through the system's own dialog; a refusal is respected and never re-asked. This
> matches the documented acceptable use for apps whose core function is impaired by Doze.

## 4. FOREGROUND_SERVICE_SPECIAL_USE

Not covered by the earlier draft of this file — `CloneKeepAliveService` was added after it
was written. Play requires a justification for `specialUse`, and the manifest already
carries the subtype (`AndroidManifest.xml`, property
`android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE` = `container_host_keepalive`).

### Form: why no other foreground service type fits

> The service keeps the host process alive while a user-launched clone is running. On
> aggressive OEM builds the host is killed the moment it stops being the foreground
> activity — which is exactly when the clone takes the foreground — and the clone dies
> with it. No existing foreground service type describes "keep the container host
> resident for a running guest": the work is not media playback, data sync, location or a
> connected device. The service starts with a clone, stops itself once no clone is
> running, and adds no persistence of its own.

## 5. The engine's inherited permissions — decide before submitting

**This is the blocker, and it is not a form.** 107 of the 115 permissions come from
`bcore.aar`'s merged manifest, and the main manifest keeps every dangerous one on purpose:
guests run under the host's identity, so a clone can only exercise a permission Duplika
itself declares, and stripping one silently and permanently denies that capability to
every clone. 138 permissions were already removed on the grounds that they are
signature-level or OEM-specific.

Among the 33 runtime permissions that remain are:

```
READ_SMS, RECEIVE_SMS, SEND_SMS, READ_CALL_LOG, WRITE_CALL_LOG,
PROCESS_OUTGOING_CALLS, ADD_VOICEMAIL, CALL_PHONE, USE_SIP
```

Google's SMS and Call Log policy restricts these to apps whose **core** function requires
them, and the permitted-use list is short and specific: default SMS handler, default
phone handler, default assistant, and a few named exceptions. A cloning tool is not on
it. Declaring them without an approved exception is grounds for rejection or removal, and
no wording on this page changes that.

Also present and requiring their own declarations or scrutiny:
`ACCESS_BACKGROUND_LOCATION` (background-location declaration plus a demonstration
video), `PACKAGE_USAGE_STATS`, `SYSTEM_ALERT_WINDOW`, `CAMERA`, `RECORD_AUDIO`,
`READ_CONTACTS`.

The choice is real and it has a cost either way:

| | keep them | strip them |
| --- | --- | --- |
| Play submission | effectively blocked | possible, subject to 1–4 above |
| Cloned apps | SMS OTP autofill, call-log features and telephony work as the guest expects | those features fail inside every clone, permanently and silently |

If they are stripped, it should be done the way the others were — `tools:node="remove"` in
the main manifest — and paired with compatibility findings so a guest that needs one is
refused up front rather than failing at runtime, the same pattern
`storageFindingFor()` already uses for storage.

## Store listing and review material still to produce

- **Store description** must state the permission use in user-facing terms (policy
  requirement for QUERY_ALL_PACKAGES and All files access).
- **Demonstration video** for the Permissions Declaration Form: show the picker listing
  installed apps, a clone being created, and a cloned file-manager reading storage.
- **Data safety form**: the installed-app inventory is read and never leaves the device;
  no collection, no sharing. The dependency list above is the evidence.
- **Review instructions**: paste the battery note from section 3 and the special-use note
  from section 4.

## Blocked on more than Play

Nothing here resolves the engine's licence provenance, which is recorded in
`BlackBoxEngineAdapter`'s class documentation: the virtualization engine descends from
projects that are unlicensed or expressly commercial, and that has to be closed by a
lawyer before any submission is made. The attribution artefacts (`NOTICE`, `licenses/`)
are also currently missing from the working tree and have to be restored before
distribution.
