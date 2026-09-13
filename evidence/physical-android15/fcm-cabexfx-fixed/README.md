# FCM in a clone — Cabex FX, fixed and re-measured

**Result: A real FCM token was issued to a cloned Cabex FX on the physical device.**
This supersedes the UNSUPPORTED result in `../fcm-cabexfx/README.md` for the
configuration that ships today: a container with the bundled microG, and an engine
that no longer mixes the host's Google Play services splits into it.

Device: OnePlus CPH2605, Android 15 / API 35, arm64-v8a, `KNOJORMFV4GERKHM`.
Build: minified release app with the engine rebuild that includes
`engine-patches/0013-storage-install-keeps-its-own-splits.patch` and the runtime
overrides from `engine-patches/overrides/`.

## What was wrong

`VirtualAppInstaller` provisions the bundled microG (`com.google.android.gms`) into a
fresh container through the **storage** install path. Both `CopyExecutor` and
`PackageManagerCompat.generateApplicationInfo` fell back to the *host* package
manager's `splitSourceDirs` whenever the package brought no `splitCodePaths` of its
own — so the container ended up with microG's base APK plus **Google Play services'
split APKs**:

```
blackbox/data/app/com.google.android.gms/
    base.apk                              # microG (sha256 matches the bundled asset)
    split_AdsDynamite_installtime.apk     # Google Play services
    split_CronetDynamite_installtime.apk  # ...
    split_MapsDynamite_installtime.apk
    split_config.xxhdpi.apk
    ...
```

The guest bind then failed on this ROM:

```
W BActivityThread: makeApplication returned null, attempting fallback creation
E BActivityThread: Error creating application: null
E BActivityThread: Fallback application creation failed: null
D BActivityThread: Creating minimal application wrapper
E BActivityThread: Unable to instantiate service org.microg.gms.gcm.PushRegisterService:
    java.lang.NullPointerException ... ClassLoader.loadClass ... on a null object reference
```

No microG service could start, so checkin never completed and no token was issued.
Removing the stray split files instead made `createPackageContext` return null and
the bind abort on `assert packageContext != null`.

## What fixed it

`engine-patches/0013-storage-install-keeps-its-own-splits.patch`:

- `CopyExecutor`: only a `FLAG_SYSTEM` (by-name) install may borrow the host's split
  set. A storage install owns its splits.
- `PackageManagerCompat.generateApplicationInfo`: same rule for what the guest sees;
  a storage install drops recorded split paths whose files are gone (so already
  polluted containers repair themselves), and with no usable splits the splitDir
  fields are explicitly cleared rather than left at their persisted values.

## Measured after the fix

| Fact | Observation |
| --- | --- |
| microG checkin | `.../com.google.android.gms/shared_prefs/checkin.xml` written |
| GCM state | `.../com.google.android.gms/databases/gcmstatus` updated |
| Guest service | `PushRegisterService` bound; `SettingsProvider` published as `com.google.android.gms.microg.settings` |
| Login | Cabex FX logged in with the reviewer account and reached its dashboard |
| FCM token | stored by the guest app: `flutter.current_fcm_token` = `f9P41qPJ...:APA91b...` (redacted) |

No `GCM: Invalid caller`, no `SERVICE_NOT_AVAILABLE`, no `makeApplication` failure.

## Files

| Path | What |
| --- | --- |
| `engine-patches/0013-storage-install-keeps-its-own-splits.patch` | the engine fix |
| `docs/microg-container-spike.md` | the emulator measurement this now carries to a physical device |
