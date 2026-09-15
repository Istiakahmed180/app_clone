#!/usr/bin/env bash
#
# Starts the release APK build on GitHub and waits for it. arm64-v8a only.
#
#   ./scripts/build-apk.sh                 # build it; downloading needs a GitHub login
#   ./scripts/build-apk.sh --public        # also attach it to a release anyone can download
#   ./scripts/build-apk.sh --ref my-branch # build a ref other than the default branch
#
# Nothing is built on an ordinary push; this script is the trigger.
set -euo pipefail

WORKFLOW="build-apk.yml"
PUBLISH="false"
REF=""

while [ $# -gt 0 ]; do
  case "$1" in
    --public)  PUBLISH="true" ;;
    --ref)     REF="${2:?--ref needs a branch or tag}"; shift ;;
    # Prints the header comment, so the usage text has exactly one home.
    -h|--help) awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"; exit 0 ;;
    *)         echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

command -v gh >/dev/null || { echo "gh is not installed: https://cli.github.com" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh is not logged in. Run: gh auth login" >&2; exit 1; }

REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
[ -n "$REF" ] || REF="$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)"

echo "Building the release APK from $REPO@$REF"
[ "$PUBLISH" = "true" ] && echo "It will also be attached to the public latest-build release."

# The run id is not returned by `gh workflow run`, so the newest run of this workflow is
# taken just after dispatching. Recorded first so a run already in flight is not mistaken
# for the new one.
BEFORE="$(gh run list --workflow "$WORKFLOW" --limit 1 --json databaseId --jq '.[0].databaseId // 0')"
gh workflow run "$WORKFLOW" --ref "$REF" -f "publish=$PUBLISH"

printf 'Waiting for the run to appear'
RUN_ID=""
for _ in $(seq 1 30); do
  sleep 2
  RUN_ID="$(gh run list --workflow "$WORKFLOW" --limit 1 --json databaseId --jq '.[0].databaseId // 0')"
  [ "$RUN_ID" != "$BEFORE" ] && [ "$RUN_ID" != "0" ] && break
  printf '.'
done
echo
[ -n "$RUN_ID" ] && [ "$RUN_ID" != "$BEFORE" ] || {
  echo "The run did not appear. Check: gh run list --workflow $WORKFLOW" >&2
  exit 1
}

# Streams progress and exits non-zero if the build fails, so this script's exit status is
# the build's.
gh run watch "$RUN_ID" --exit-status

echo
echo "Done. To install it:"
echo "  gh run download $RUN_ID -n duplika-apk -D /tmp/duplika"
echo "  adb uninstall co.tdevs.duplika; adb install /tmp/duplika/duplika-arm64-v8a-*.apk"
if [ "$PUBLISH" = "true" ]; then
  echo
  echo "Anyone can download it, no GitHub account needed:"
  echo "  https://github.com/$REPO/releases/download/latest-build/duplika-arm64-v8a.apk"
fi
