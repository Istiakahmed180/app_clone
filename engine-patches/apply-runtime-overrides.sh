#!/usr/bin/env bash
set -euo pipefail

# Rebuilds the vendored AAR's Java classes from the small, auditable overrides
# in overrides/. The native engine and all unrelated classes remain unchanged.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
WORK="$(mktemp -d)"

unzip -q "$ROOT/android/app/libs/bcore.aar" -d "$WORK/aar"
mkdir -p "$WORK/classes" "$WORK/src"
cp "$WORK/aar/classes.jar" "$WORK/classes.jar"
find "$ROOT/engine-patches/overrides" -name '*.java' -print > "$WORK/sources.txt"

javac -source 8 -target 8 \
  -cp "$SDK/platforms/android-35/android.jar:$WORK/classes.jar:$ROOT/android/app/libs/black-reflection.jar" \
  -d "$WORK/classes" \
  $(<"$WORK/sources.txt")

jar uf "$WORK/classes.jar" -C "$WORK/classes" .
cp "$WORK/classes.jar" "$WORK/aar/classes.jar"

OUT="$ROOT/android/app/libs/bcore-runtime-fixed.aar"
# Git Bash on Windows ships unzip but not zip; jar is already a build requirement, so use it
# when zip is unavailable. Both produce a plain zip, which is what an AAR is.
if command -v zip >/dev/null 2>&1; then
  (cd "$WORK/aar" && zip -qr "$OUT" .)
else
  (cd "$WORK/aar" && jar cfM "$OUT" .)
fi
mv "$OUT" "$ROOT/android/app/libs/bcore.aar"
echo "Installed runtime overrides into android/app/libs/bcore.aar"
