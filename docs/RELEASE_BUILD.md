# Release builds

> **Note on the captured output below.** These runs predate the rename from *Virtual Space*
> to **Duplika**, so device transcripts here still show the old host package
> `com.example.virtualspacedemo` and the old app label. Nothing else about them changed; the
> host package is now `co.tdevs.duplika`.

The release build minifies. The virtualization engine does not survive
minification without help, and the way it fails is silent and total, so this is
worth understanding before changing anything here.

## What went wrong

AGP 9 enables R8 for release builds by default. Nothing in `build.gradle.kts`
asked for it, and nothing in the build output pointed at it. The result was a
release APK in which the engine was dead:

```
E VirtualSpace.Engine: Engine attach failed
E VirtualSpace.Engine: java.lang.ExceptionInInitializerError
E VirtualSpace.Engine:     at ...VirtualSpaceApplication.attachBaseContext
E VirtualSpace.Engine: Caused by: java.lang.RuntimeException:
                           Not found @BlackClass or @BlackStrClass
E VirtualSpace.Engine:     at top.niunaijun.blackbox.BlackBoxCore.<init>
```

The engine reaches hidden Android framework APIs through one annotated interface
stub per mirrored class. Nothing references those stubs statically -- they are
resolved by annotation at runtime -- so R8 read them as dead code, exactly as it
is designed to. In the release mapping file:

```
black.android.accounts.BRIAccountManagerStub -> R8$$REMOVED$$CLASS$$112
top.niunaijun.blackreflection.BlackReflection -> w4.c
```

The failure happens in `Application.attachBaseContext`, before Flutter starts,
so every clone is unusable and the UI shows only "The virtualization engine
failed to start on this device." Debug builds do not minify, which is why this
was invisible during development.

## Why the AAR's own rules were not enough

`bcore.aar` ships a `proguard.txt` that keeps `top.niunaijun.blackbox.**`,
`top.niunaijun.jnihook.**` and `mirror.**`. Those rules are applied, and they
did protect the engine core. They miss the two things that actually broke:

- The stubs live in `black.**`. `mirror.**` is this engine lineage's *former*
  package name; the rule was never updated after the rename.
- `BlackReflection` itself ships as `libs/black-reflection.jar`. A plain JAR
  cannot carry consumer rules at all, so nothing was keeping it.

`android/app/proguard-rules.pro` covers both, and restates the engine-core keeps
so the build does not depend on consumer-rule processing for a local file
dependency.

## Verified

Built with `flutter build apk --release`, installed on an emulator
(`sdk_gphone64_arm64`, Android 17 / API 37), with no `DEBUGGABLE` flag:

- `Engine attached in process com.example.virtualspacedemo`
- 0 classes removed from `black.**`; `BlackReflection` keeps its name
- a clone launches into `top.niunaijun.blackbox.proxy.ProxyActivity$P0`
- state stays isolated: clone at counter 4 / "Test User" while the normal
  install of the same package sat at counter 0 / "Alice"

## If you change the engine or its dependencies

Minification failures do not show up as build errors. After changing the AAR,
the reflection JAR, or these rules, build release and confirm on a device that a
clone actually launches -- a healthy banner on the home screen is not proof, and
`run-as` is unavailable because release builds are not debuggable.
