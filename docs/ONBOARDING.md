# First-launch onboarding

Two things happen on first launch:

| Step | Blocks the app? | Owned by |
| --- | --- | --- |
| Data-and-permissions disclosure | **Yes** — until accepted | `OnboardingController` + `DataDisclosure` |
| Doze exemption offer | No | `BatteryOptimization.kt` |

`OnboardingController` owns the order and `OnboardingHost` owns how each step appears, so
the sequence is testable without pumping a single widget.

## The disclosure is the one thing that blocks

The data disclosure is a gate, and that is a deliberate exception to the rule below, not
an oversight. Play requires a **prominent disclosure** for the installed-app inventory
`QUERY_ALL_PACKAGES` makes readable, and a policy the user is never shown is not a
disclosure. The gate holds until the user taps *Agree and continue*, it is shown before
the clone picker is reachable — so before any installed-app data is read — and the answer
is remembered. Nothing else blocks.

## Nothing else is allowed to block

The Doze exemption is not a gate, deliberately. It is a convenience: clones work without
it; they just get dozed along with the host. It is offered once, from a dismissible
banner, and a dismissal is permanent — re-asking every launch is the pattern this app is
trying not to be.

## No terms dialog and no consent form — but a disclosure that gates

The old first-launch terms dialog was removed, and it is not coming back in that form. What
returned is narrower and truthful: `DataDisclosure` states what Duplika reads (the
installed-app list), that it stays on-device, and that the battery and all-files requests
are optional — and it gates the app until accepted. That is the prominent disclosure Play
requires for `QUERY_ALL_PACKAGES`, and it lives in the app rather than only in a linked
policy the user is never shown.

Earlier builds ran Google's User Messaging Platform (UMP) consent form at first launch.
It is gone, along with the `com.google.android.ump` dependency, the
`com.google.android.gms.ads.APPLICATION_ID` manifest entry and `ConsentManager.kt`.

A GDPR/TCF consent form is required of an app that serves ads or shares personal data for
ad personalisation. Duplika does neither — there is no ads SDK, no analytics, no crash
reporter and no HTTP client in the dependency set — so the form asked users to consent to
data sharing that never happens. Showing a consent statement that is not true about the
app is worse than showing none, and it would not have matched the Play Data safety
declaration either.

The id in the manifest was Google's public sample id, so the form that appeared was
branded "Publisher Test Ads" and named partners this app has never spoken to.

**If ads are ever added**, the form comes back with them, and it needs a real AdMob
application id plus a message configured in the AdMob console. Do not restore it ahead of
that.

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

- [ ] Publish the Privacy Policy and Terms of Service, put their URLs in
      `LegalConstants`, and set `policiesArePlaceholders = false`. Until then Settings
      hides the rows rather than pointing them at dead `example.com` links.
- [x] The data-collection disclosure lives in `DataDisclosure` and gates the app until
      accepted — the prominent disclosure `QUERY_ALL_PACKAGES` requires. See above.
- [ ] Submit the Play Console declarations for `QUERY_ALL_PACKAGES` and
      `MANAGE_EXTERNAL_STORAGE`, and put the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
      justification in the listing and review notes. The paste-ready text, the video
      script and the fallbacks if a declaration is rejected are prepared in
      `docs/PLAY_PERMISSION_DECLARATIONS.md`; what remains is the submission itself.

The distribution blocker in the root `README` and `docs/DEPENDENCY_LICENSE_AUDIT.md` is
separate from all of this, and none of it is affected by finishing the list above.
