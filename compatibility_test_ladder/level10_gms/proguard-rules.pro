# Release keeps minification ON. These rules exist only so a Release result means what it
# says -- they never make a failing probe pass.

# Probe classes are named in the report and in logcat; without this a Release failure
# would be attributed to an obfuscated name that cannot be matched back to a probe.
-keep class com.example.duplikaladder.level10gms.** { *; }

# Loaded by name through Class.forName in ProbeApiSurface to test whether the guest's
# class loader can reach them. R8 cannot see a reflective load, so without a keep rule it
# would strip the unused ones and the probe would report a Release "failure" that is
# really just shrinking.
-keep class com.google.android.gms.common.GoogleApiAvailability { *; }
-keep class com.google.android.gms.common.ConnectionResult { *; }
-keep class com.google.android.gms.common.api.GoogleApi { *; }
-keep class com.google.android.gms.common.api.HasApiKey { *; }
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient { *; }
-keep class com.google.android.gms.ads.identifier.AdvertisingIdClient$Info { *; }
-keep class com.google.android.gms.appset.AppSet { *; }
-keep class com.google.android.gms.appset.AppSetIdClient { *; }
-keep class com.google.android.gms.auth.api.signin.GoogleSignIn { *; }

# Phase 9 cross-API discriminator. Reached through the GoogleApi framework and named in the
# report, so keep the entry points to stop a Release "failure" that is really just shrinking.
-keep class com.google.android.gms.location.ActivityRecognition { *; }
-keep class com.google.android.gms.location.ActivityRecognitionClient { *; }
