# Chrome per-app-locale crash — cause and fix

Emulator `sdk_gphone64_arm64`, Android 15 / API 35. Chrome 152.0.7977.82.

## Before (engine `23689bce…`)

Chrome reached its first-run screen and then died on the main thread:

```
FATAL EXCEPTION: main    Process: com.android.chrome, PID: 10409
java.lang.SecurityException: getApplicationLocales: Neither user 10234 nor current
    process has android.permission.READ_APP_SPECIFIC_LOCALES.
  at android.app.LocaleManager.getApplicationLocales(LocaleManager.java:126)
  at tj7.queueIdle
```

10234 is the host UID. The call arrives from an **idle handler**, seconds after the UI is
up — which is why the crash looks like it is caused by whatever the user tapped. The
"Continue" button and, in the earlier investigation, "Stay signed out" both took the blame
for this. Neither causes it.

## Cause

`LocaleManager.getApplicationLocales()` invokes
`ILocaleManager.getApplicationLocales(packageName, userId)`. The platform requires
`READ_APP_SPECIFIC_LOCALES` unless the caller owns the package it asks about. In a container
the Binder calling UID is the host's while the package argument is the guest's.

Bcore had **no hook for this service at all** — no `ILocaleManagerProxy`, and `"locale"` was
never registered — so the call went to the real service unchanged. Per-app locales are API
33+, newer than most of Bcore's proxy set.

## Fix

`engine-patches/0009-localemanager-application-locales-api35.patch`. Same approach as patch
0006: rewrite the package argument to the host package, which the calling UID genuinely owns.

## After (engine `249a00b5…`)

| Check | Result |
| --- | --- |
| `READ_APP_SPECIFIC_LOCALES` occurrences | **0** (was fatal) |
| `FATAL EXCEPTION` | **none** |
| `ILocaleManagerProxy` installed | yes — "Hooked LocaleManagerService" |
| Chrome process after 60 s | **alive** |
| Onboarding progress | past "Welcome to Chrome / Continue", now at "Make Chrome your own" |

Capture: `after-patch0009.log` (gitignored; regenerate with the steps above).

## Not fixed by this patch, and not claimed to be

- `GoogleApiManager: Unknown calling package name 'com.android.chrome'` still appears. That
  is the documented caller-identity boundary
  (`docs/level10-gms-caller-identity-boundary.md`) and is non-fatal for Chrome.
- Renderer stability and actual page rendering — criteria 6 and 7 of
  `docs/patch0008-isolated-service-android15-verification.md` — are separate and still open.
  Getting past onboarding requires accepting Chrome's Terms of Service, which is the device
  owner's decision to make, so that step was left to them.
