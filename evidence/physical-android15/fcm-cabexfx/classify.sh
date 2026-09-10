#!/usr/bin/env bash
# Classifies a capture.sh log: is a GMS failure the documented caller-identity boundary
# (docs/level10-gms-caller-identity-boundary.md section 5 -- UNSUPPORTED, must not be fixed),
# or something else?
#
# Note on the refusal pattern below. The first version of this script searched only for the
# GmsServiceBroker wording and therefore MISCLASSIFIED the Cabex FX FCM failure as "not the
# boundary". Play services refuses caller-scoped requests in more than one place, with
# different wording, from different processes. Match all of them.
set -uo pipefail
LOG="${1:?usage: classify.sh <raw-*.log>}"

REFUSALS='Unknown calling package name|Invalid caller'

hits() { grep -cE "$1" "$LOG" 2>/dev/null | head -1; }

echo "=== 1. Caller-identity refusal, any known wording ==="
grep -nE "$REFUSALS" "$LOG" | head -8
echo "    GmsServiceBroker  'Unknown calling package name' : $(hits 'Unknown calling package name')"
echo "    GCM subsystem     'Invalid caller'               : $(hits 'Invalid caller')"

echo
echo "=== 2. GoogleApi broker refusals ==="
echo "    Failed to get service from broker : $(hits 'Failed to get service from broker')"
echo "    DEVELOPER_ERROR                   : $(hits 'DEVELOPER_ERROR|statusCode=10')"

echo
echo "=== 3. The FCM failure itself ==="
grep -nE "SERVICE_NOT_AVAILABLE|FirebaseMessaging|FirebaseInstanceId|Topic sync" "$LOG" | head -12

echo
echo "=== 4. Container resolution gaps (fixable class, may be secondary) ==="
grep -nE "PackageManagerStub: queryIntent(Services|Receivers): \[\]|Failed to resolve IID" "$LOG" | head -6
echo "    getPackagesForUid references : $(hits 'getPackagesForUid')"

echo
echo "=== 5. Timeout / transport signals ==="
echo "    TIMEOUT               : $(hits 'TIMEOUT|timed out|SocketTimeout')"
echo "    AUTHENTICATION_FAILED : $(hits 'AUTHENTICATION_FAILED')"

echo
echo "=== VERDICT ==="
if [ "$(hits "$REFUSALS")" -gt 0 ]; then
  echo "  Caller-identity boundary is PRESENT."
  echo "  Play services refused to attribute the request to a package that does not belong"
  echo "  to the Binder calling UID. This is the documented UNSUPPORTED boundary and must"
  echo "  NOT be 'fixed' -- every route requires package-identity or UID spoofing."
else
  echo "  No caller-identity refusal in any wording this script knows."
  echo "  Investigate as a timeout or resolution defect; those are legitimately fixable."
  echo "  If a new refusal wording appears, add it to REFUSALS above."
fi
