# First-launch onboarding

Two things happen before the home screen is usable, in this order:

| Step | Blocks the app? | Owned by |
| --- | --- | --- |
| Terms and data-collection disclosure | **Yes** | `TermsDialog` |
| Doze exemption offer | No | `BatteryOptimization.kt` |

`OnboardingController` owns the order and `OnboardingHost` owns how each step appears, so
the sequence is testable without pumping a single widget.

## Only one step is allowed to block

The terms are a genuine gate: declining closes the app, because nothing in Duplika is
usable without them, and parking someone on a screen that refuses to work is worse than
letting them leave.

The Doze exemption is not a gate, deliberately. It is a convenience: clones work without
it; they just get dozed along with the host. It is offered once, from a dismissible
banner, and a dismissal is permanent — re-asking every launch is the pattern this app is
trying not to be.

## No consent form, and no AdMob id

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
      `LegalConstants`, and set `policiesArePlaceholders = false`. Until then the terms
      dialog renders a development warning instead of dead links — presenting an
      unpublished `example.com` link as "our Privacy Policy" would be a lie in the one
      dialog that must not contain any.
- [ ] Re-read the disclosure text in `TermsDialog` against what the app actually collects.
      It is the text the user agrees to, so it has to stay true as the app changes.
- [ ] Justify `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` in the Play listing, alongside
      `QUERY_ALL_PACKAGES` and `MANAGE_EXTERNAL_STORAGE`. See `docs/SECURITY.md`.

The distribution blocker in the root `README` and `docs/DEPENDENCY_LICENSE_AUDIT.md` is
separate from all of this, and none of it is affected by finishing the list above.
