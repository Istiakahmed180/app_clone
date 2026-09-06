# R8 / ProGuard rules for the release build.
#
# AGP 9 minifies release builds by default, and the virtualization engine does
# not survive minification unaided: it resolves hidden Android framework APIs
# through annotated interface stubs that nothing references statically. R8
# correctly reads those stubs as dead code and deletes or renames them, after
# which BlackBoxCore.<clinit> throws
#   java.lang.RuntimeException: Not found @BlackClass or @BlackStrClass
# during Application.attachBaseContext -- so the engine is dead before Flutter
# starts and every clone is unusable. See docs/RELEASE_BUILD.md.

# -- Hidden-API mirror stubs -------------------------------------------------
# One interface per mirrored framework class, reached only by annotation lookup.
# bcore.aar's own consumer rules keep "mirror.**", which is this engine's former
# package name; the stubs actually live in "black.**", so they were unprotected.
-keep class black.** { *; }
-keep interface black.** { *; }

# -- The reflection engine that reads those stubs ----------------------------
# Ships as libs/black-reflection.jar. A plain JAR cannot carry consumer rules,
# so nothing was keeping it and BlackReflection itself was renamed to w4.c.
-keep class top.niunaijun.blackreflection.** { *; }

# -- Engine core and its JNI hooks -------------------------------------------
# bcore.aar's consumer rules already cover these. Restated so the build does not
# silently depend on consumer-rule processing for a local file dependency.
-keep class top.niunaijun.blackbox.** { *; }
-keep class top.niunaijun.jnihook.** { *; }

# -- Hidden-API access bootstrap ---------------------------------------------
-keep class me.weishu.reflection.** { *; }

# -- Attributes the reflection layer reads at runtime ------------------------
# The annotations ARE the hidden-API mapping; R8 strips them by default, which
# leaves a kept stub with no usable target.
-keepattributes *Annotation*
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeVisibleTypeAnnotations
-keepattributes AnnotationDefault
# Mirrored member lookup resolves declared types and nesting.
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
