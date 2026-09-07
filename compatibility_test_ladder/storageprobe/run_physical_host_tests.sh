#!/bin/sh
set -eu

SERIAL="${1:-KNOJORMFV4GERKHM}"
ADB="${ADB:-/Users/tdevs/Library/Android/sdk/platform-tools/adb}"
PACKAGE="com.example.duplikaladder.storageprobe"
ACTIVITY="$PACKAGE/.MainActivity"
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

run_one() {
  label="$1"
  apk="$2"
  echo "=== $label ==="
  "$ADB" -s "$SERIAL" install -r "$apk"
  "$ADB" -s "$SERIAL" shell am force-stop "$PACKAGE"
  "$ADB" -s "$SERIAL" shell am start -n "$ACTIVITY"
  sleep 1
  "$ADB" -s "$SERIAL" shell uiautomator dump "/sdcard/storageprobe-$label.xml" >/dev/null
  "$ADB" -s "$SERIAL" shell cat "/sdcard/storageprobe-$label.xml" \
    | sed 's/></>\n</g' \
    | grep -E 'VLC Storage|context.getExternalFilesDirs|environment.isExternal|vlc\.|permission\.|appops\.|native\.|internalPersistence'
}

"$ADB" -s "$SERIAL" shell getprop ro.product.model
"$ADB" -s "$SERIAL" shell getprop ro.build.version.sdk
run_one host-debug "$ROOT/build/outputs/apk/debug/storageprobe-debug.apk"
run_one host-release "$ROOT/build/outputs/apk/release/storageprobe-release.apk"

cat <<'EOF'

Host tests complete. Guest tests must use Duplika's actual multi-file/user-facing
import flow. Do not install the probe directly and call that a guest result.
EOF
