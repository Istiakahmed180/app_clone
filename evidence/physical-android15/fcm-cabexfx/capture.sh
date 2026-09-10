#!/usr/bin/env bash
# Captures the evidence needed to classify the Cabex FX FCM failure inside a Duplika clone.
#
# The question this answers, and only this: is the failure the documented caller-identity
# boundary (docs/level10-gms-caller-identity-boundary.md -- UNSUPPORTED, must not be fixed),
# or is it something else (a timeout, or the open getPackagesForUid defect in section 6b,
# both of which are legitimately fixable)?
#
# Usage:  evidence/physical-android15/fcm-cabexfx/capture.sh [serial]
#         Then, while it runs: open Duplika, launch the Cabex FX clone, wait ~90s.
#         Ctrl-C when the failure has appeared.
set -uo pipefail

SERIAL="${1:-}"
ADB=(adb); [ -n "$SERIAL" ] && ADB=(adb -s "$SERIAL")
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "==> device"
"${ADB[@]}" shell getprop ro.product.model
"${ADB[@]}" shell getprop ro.build.version.release
"${ADB[@]}" shell dumpsys package com.google.android.gms | grep -m1 versionName || true

echo "==> clearing the log buffer"
"${ADB[@]}" logcat -c 2>/dev/null || true

echo
echo "    NOW: open Duplika and launch the Cabex FX clone."
echo "    Wait until the FCM failure appears (about 60-90s), then press Ctrl-C."
echo

# -v threadtime keeps pid/tid so guest and host lines can be told apart.
# Everything is captured raw; classification happens afterwards, not by a grep that could
# hide the line that mattered.
"${ADB[@]}" logcat -v threadtime "*:V" | tee "$OUT/raw-$STAMP.log"
