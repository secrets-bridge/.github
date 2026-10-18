#!/usr/bin/env bash
# Preflight for a shared Secrets Bridge release. Reads every repo through
# the GitHub API (no clones needed) and reports what still blocks tagging
# vX.Y.Z, then prints the tag commands in release order.
#
#   scripts/release-check.sh 0.1.0        # or v0.1.0, or 0.1.0-rc.1
#
# Needs `gh` signed in with read access to secrets-bridge/*. Exits 1 when
# anything blocks the release, 0 when everything is ready.
set -uo pipefail

ORG=secrets-bridge
# Release order: core first (agent and controller pin it), api before
# worker (worker's tag build pins api at the same tag), charts last (the
# chart job checks every release image exists).
ORDER=(core api worker agent controller ui charts)
CORE_USERS=(agent controller)

[[ $# -eq 1 ]] || { echo "usage: $0 X.Y.Z" >&2; exit 2; }
V=${1#v}
TAG=v$V
if ! [[ "$TAG" =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "$TAG is not a semver tag (vMAJOR.MINOR.PATCH or vMAJOR.MINOR.PATCH-pre)" >&2
  exit 2
fi

blocked=0
ok()   { printf '  ok    %s\n' "$*"; }
warn() { printf '  warn  %s\n' "$*"; }
bad()  { printf '  FAIL  %s\n' "$*"; blocked=1; }
raw()  { gh api -H 'Accept: application/vnd.github.raw' "repos/$ORG/$1/contents/$2" 2>/dev/null; }

declare -A HEAD
for r in "${ORDER[@]}"; do
  echo "$r"
  sha=$(gh api "repos/$ORG/$r/commits/main" --jq .sha 2>/dev/null) || { bad "can't read main"; continue; }
  HEAD[$r]=$sha

  if gh api "repos/$ORG/$r/git/ref/tags/$TAG" >/dev/null 2>&1; then
    bad "$TAG already exists (tags are never moved; release the next version instead)"
  fi

  # Every workflow run on main's head commit finished green. A run that
  # was cancelled because a newer push replaced it doesn't count.
  runs=$(gh api "repos/$ORG/$r/actions/runs?branch=main&head_sha=$sha&per_page=50" \
    --jq '[.workflow_runs[] | select(.event == "push") | {name, status, conclusion}]')
  if [[ $(jq length <<<"$runs") -eq 0 ]]; then
    warn "no push runs on main ${sha:0:7} (a path-filtered docs-only commit, or runs not started yet)"
  else
    pending=$(jq -r '[.[] | select(.status != "completed") | .name] | join(", ")' <<<"$runs")
    failed=$(jq -r '[.[] | select(.status == "completed" and .conclusion != "success" and .conclusion != "skipped" and .conclusion != "cancelled") | "\(.name)=\(.conclusion)"] | join(", ")' <<<"$runs")
    [[ -n "$pending" ]] && bad "runs still going on ${sha:0:7}: $pending"
    [[ -n "$failed" ]] && bad "runs not green on ${sha:0:7}: $failed"
    [[ -z "$pending$failed" ]] && ok "main ${sha:0:7} is green"
  fi

  if changelog=$(raw "$r" CHANGELOG.md); then
    if grep -q "^## \[$V\]" <<<"$changelog"; then
      ok "CHANGELOG has [$V]"
    else
      bad "CHANGELOG has no [$V] section (move [Unreleased] to [$V] - $(date -u +%Y-%m-%d))"
    fi
  fi

  if [[ $r == charts ]]; then
    for c in secrets-bridge agent; do
      cv=$(raw charts "$c/Chart.yaml" | awk '/^version:/ {print $2; exit}')
      if [[ "$cv" == "$V" ]]; then ok "$c/Chart.yaml version $cv"; else bad "$c/Chart.yaml version is $cv, the tag needs $V"; fi
    done
  fi

  for u in "${CORE_USERS[@]}"; do
    [[ $r == "$u" ]] || continue
    pin=$(raw "$r" go.mod | awk '$1 == "github.com/secrets-bridge/core" {print $2; exit}')
    if [[ "$pin" == "$TAG" ]]; then
      ok "go.mod pins core $pin"
    else
      bad "go.mod pins core $pin; after tagging core, bump it to $TAG (go get github.com/secrets-bridge/core@$TAG)"
    fi
  done
done

echo
if [[ $blocked -ne 0 ]]; then
  echo "Not ready for $TAG. Fix the FAIL lines and run this again. Core can be"
  echo "tagged on its own first, since the core pins can only move after it."
else
  echo "Ready for $TAG."
fi
echo
echo "Tag in this order, each from main's head (annotated and signed):"
for r in "${ORDER[@]}"; do
  sha=${HEAD[$r]:-<main sha>}
  printf '  %-11s git -C %s tag -s %s -m %s %s && git -C %s push origin %s\n' \
    "$r" "$r" "$TAG" "$TAG" "${sha:0:12}" "$r" "$TAG"
done
echo "Wait for each repo's publish and release jobs before the next step;"
echo "charts goes last because its job checks the $V images exist."
exit "$blocked"
