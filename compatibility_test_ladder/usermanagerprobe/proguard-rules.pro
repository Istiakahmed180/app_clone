# Probe class names appear in the report and in logcat, so keep them: a Release failure must
# be attributable to a named probe rather than to an obfuscated one.
-keep class com.example.duplikaladder.umprobe.** { *; }
