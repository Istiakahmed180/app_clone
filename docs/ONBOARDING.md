# First-launch onboarding

Three things happen before the home screen is usable, in this order:

| Step | Blocks the app? | Owned by |
| --- | --- | --- |
| GDPR/TCF consent (Google UMP) | No | `ConsentManager.kt` |
| Terms and data-collection disclosure | **Yes** | `TermsDialog` |
| Doze exemption offer | No | `BatteryOptimization.kt` |

`OnboardingController` owns the order and `OnboardingHost` owns how each step appears, so
the sequence is testable without pumping a single widget.

## Only one step is allowed to block

The terms are a genuine gate: declining closes the app, because nothing in Duplika is
usable without them, and parking someone on a screen that refuses to work is worse than
letting them leave.

Consent and the Doze exemption are not gates, deliberately.

- **Consent** gathers nothing that Duplika acts on. The app shows no ads and sends no
  personal data anywhere. A form that will not load — no network, no configured message,
  a UMP outage — is logged through `ConsentState.failed` and the user carries on. Blocking
  on it would deny people their own clones to satisfy a form about data that is never
  collected.
- **The Doze exemption** is a convenience. Clones work without it; they just get dozed
  along with the host. It is offered once, from a dismissible banner, and a dismissal is
  permanent — re-asking every launch is the pattern this app is trying not to be.

## Consent, and the AdMob id

UMP has no identifier of its own. It reads the publisher identity from the AdMob
application id in the merged manifest, so `AndroidManifest.xml` carries:

```xml
<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
           android:value="${admobApplicationId}" />
```

The value comes from one place — `manifestPlaceholders["admobApplicationId"]` in
`app/build.gradle.kts` — and currently holds **Google's public sample id**. That is enough
to build and exercise the flow without an AdMob account, and not enough to serve a real
consent message. Swap it there before release.

The dependency is `com.google.android.ump:user-messaging-platform`, the standalone
artifact — deliberately **not** `google_mobile_ads`. This app serves no ads, and the full
Mobile Ads SDK would be dead weight in the APK for the sake of one form.

### Seeing the form outside the EEA

UMP only shows the form to real EEA/UK users, which makes the flow untestable anywhere
else. `LegalConstants.debugConsentGeography` forces `DEBUG_GEOGRAPHY_EEA` in debug builds;
UMP ignores it in a release build signed with a release key. Set it to the empty string to
see exactly what a user in your own region would see.

`resetConsent` on the bridge clears the stored answer so the form can be seen again.

### Withdrawal

The TCF requires consent to stay withdrawable once given. `showPrivacyOptions` re-opens
the form, and `ConsentState.privacyOptionsRequired` says when an entry point for it must
be shown. **There is no such entry point in the UI yet** — it belongs in the app menu
before any build that gathers real consent reaches a user.

## The Doze exemption

Guests run inside Duplika's process group, so when Android dozes the host it dozes every
clone with it: a cloned messenger silently stops delivering while the user believes it is
running. `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` enables the one-tap system dialog that
asks for the exemption.

That permission is Play-policy-sensitive, and it is treated the same way as
`QUERY_ALL_PACKAGES`: declared, never requested silently, and refusable. Android owns both
the dialog and the answer. On devices with no such dialog, `BatteryOptimization` falls
back to the battery-optimisation list and the UI says so, rather than reporting a success
that did not happen.

Opening a screen is not the same as being granted anything, so the banner stays up until
`isIgnoringBatteryOptimizations` confirms the exemption. `OnboardingHost` re-checks on
`AppLifecycleState.resumed`, which is the only reliable moment — the answer is given on a
system screen, outside this app.

## Before this ships

- [ ] Replace `admobApplicationId` in `app/build.gradle.kts` with the real AdMob id.
- [ ] Publish the Privacy Policy and Terms of Service, put their URLs in
      `LegalConstants`, and set `policiesArePlaceholders = false`. Until then the terms
      dialog renders a development warning instead of dead links — presenting an
      unpublished `example.com` link as "our Privacy Policy" would be a lie in the one
      dialog that must not contain any.
- [ ] Add a privacy-options entry point to the app menu (see **Withdrawal** above).
- [ ] Re-read the disclosure text in `TermsDialog` against what the app actually collects.
      It is the text the user agrees to, so it has to stay true as the app changes.
- [ ] Justify `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in the Play listing, alongside
      `QUERY_ALL_PACKAGES` and `MANAGE_EXTERNAL_STORAGE`. See `docs/SECURITY.md`.

The distribution blocker in the root `README` and `docs/DEPENDENCY_LICENSE_AUDIT.md` is
separate from all of this, and none of it is affected by finishing the list above.
