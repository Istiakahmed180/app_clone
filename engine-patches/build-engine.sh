#!/usr/bin/env bash
#
# Rebuilds the patched virtualization engine AAR from source and installs it at
# android/app/libs/bcore.aar. This makes the committed binary regenerable: anyone can verify
# or reproduce it from the pinned upstream commit plus the patches in this directory.
#
# Requirements: git, a JDK (17+), Android SDK, and NDK 29.0.13846066 installed. Point
# ANDROID_HOME (or ANDROID_SDK_ROOT) at the SDK if it is not the macOS default.
#
# Usage:  engine-patches/build-engine.sh
#
set -euo pipefail

COMMIT="89b59836c66f173756a4ae258cf379a957649820"
REPO="https://github.com/ALEX5402/NewBlackbox.git"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_DIR="$REPO_ROOT/engine-patches"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"

# Bcore builds on JDK 17 (this repo lowers its Java level below). If the shell's JAVA_HOME is
# unset or points at a directory with no java (a common stale-config problem), pick a real
# JDK 17 via java_home so the Gradle build does not fail with "invalid directory".
if [ ! -x "${JAVA_HOME:-}/bin/java" ]; then
    if [ -x /usr/libexec/java_home ] && /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
        JAVA_HOME="$(/usr/libexec/java_home -v 17)"; export JAVA_HOME
        echo "==> Using JAVA_HOME=$JAVA_HOME"
    else
        echo "WARNING: no valid JAVA_HOME and no JDK 17 found via java_home; the build may fail." >&2
    fi
fi
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Cloning $REPO @ $COMMIT"
git clone --filter=blob:none --no-checkout "$REPO" "$WORK/NewBlackbox"
git -C "$WORK/NewBlackbox" checkout --quiet "$COMMIT"

echo "==> Applying engine patches"
for p in "$PATCHES_DIR"/*.patch; do
    echo "    - $(basename "$p")"
    git -C "$WORK/NewBlackbox" apply "$p"
done

echo "==> Reconciling toolchain (Bcore pins Java 21; build with the JDK that is present)"
# The engine uses no Java 21 language features, so compiling at 17 is safe and lets the build
# run on a JDK 17 host. Harmless if the host already has JDK 21.
sed -i '' 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' \
    "$WORK/NewBlackbox/Bcore/build.gradle" 2>/dev/null || \
sed -i 's/JavaVersion.VERSION_21/JavaVersion.VERSION_17/g' \
    "$WORK/NewBlackbox/Bcore/build.gradle"

echo "sdk.dir=$SDK" > "$WORK/NewBlackbox/local.properties"

echo "==> Building :Bcore:assembleRelease (NDK compile + R8)"
( cd "$WORK/NewBlackbox" && chmod +x gradlew && \
  ANDROID_HOME="$SDK" ANDROID_SDK_ROOT="$SDK" ./gradlew :Bcore:assembleRelease --no-daemon )

OUT="$WORK/NewBlackbox/Bcore/build/outputs/aar/Bcore-release.aar"
[ -f "$OUT" ] || { echo "ERROR: build produced no AAR at $OUT"; exit 1; }

# Sanity: both ABIs must ship, and the fix must be present. List once into a variable so a
# short-circuiting `grep -q` cannot SIGPIPE the `unzip` under `set -o pipefail`.
LISTING="$(unzip -l "$OUT")"
case "$LISTING" in
    *"jni/arm64-v8a/libblackbox.so"*) ;;
    *) echo "ERROR: arm64-v8a libblackbox.so missing from build"; exit 1 ;;
esac
case "$LISTING" in
    *"jni/armeabi-v7a/libblackbox.so"*) ;;
    *) echo "ERROR: armeabi-v7a libblackbox.so missing from build"; exit 1 ;;
esac

cp "$OUT" "$REPO_ROOT/android/app/libs/bcore.aar"
echo "==> Installed $(du -h "$REPO_ROOT/android/app/libs/bcore.aar" | cut -f1) -> android/app/libs/bcore.aar"
echo "==> Done. Rebuild the app with: flutter build apk --release"
