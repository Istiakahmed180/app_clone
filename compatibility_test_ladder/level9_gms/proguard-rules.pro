# Level 9 runs Release with minification ON so that R8 behaviour is part of the test.
# These rules exist only so that a Release result means what it says.

# The diagnostic classes are named in the report and in logcat. Without this, a Release
# failure would be reported against an obfuscated name that cannot be matched to a test.
-keep class com.example.duplikaladder.level9gms.** { *; }

# Test E loads these by name through Class.forName to see whether the guest's class
# loader can reach them at all. R8 cannot see a reflective load, so without a keep rule
# it would strip the unused ones and Test E would report a Release "failure" that is
# really just shrinking -- the exact false signal Level 9 must avoid.
-keep class com.google.android.gms.common.GoogleApiAvailability { *; }
-keep class com.google.android.gms.common.ConnectionResult { *; }
-keep class com.google.android.gms.common.api.GoogleApi { *; }
-keep class com.google.android.gms.tasks.Tasks { *; }
-keep class com.google.firebase.FirebaseApp { *; }
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
