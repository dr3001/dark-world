#!/bin/bash
# Fetch latest successful build-launcher artifacts from GitHub and deploy to CDN.
# Requires GITHUB_TOKEN env or token embedded in git remote.
set -euo pipefail

ROOT="/opt/darkworld"
REPO="dr3001/dark-world"
WORKFLOW="build-launcher.yml"

token="${GITHUB_TOKEN:-}"
if [ -z "$token" ]; then
  remote=$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)
  token=$(echo "$remote" | sed -n 's|.*ghp_\([^@]*\)@.*|\1|p')
  token="ghp_${token}"
fi

if [ -z "$token" ] || [ "$token" = "ghp_" ]; then
  echo "ERROR: Set GITHUB_TOKEN or configure git remote with token"
  exit 1
fi

api() { curl -sS -H "Authorization: Bearer $token" -H "Accept: application/vnd.github+json" "$@"; }

echo "Checking workflow runs..."
runs_json=$(api "https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/runs?per_page=5")
in_progress=$(echo "$runs_json" | python3 -c "import sys,json; print(any(r['status']=='in_progress' for r in json.load(sys.stdin)['workflow_runs']))" 2>/dev/null || echo false)

run_id=$(echo "$runs_json" | python3 -c "import sys,json; print(next((r['id'] for r in json.load(sys.stdin)['workflow_runs'] if r['conclusion']=='success'), ''))" 2>/dev/null || true)

if [ -z "$run_id" ]; then
  if [ "$in_progress" = "True" ]; then
    echo "Workflow in progress — wait and re-run this script."
    exit 0
  fi
  echo "No successful run yet — dispatching workflow..."
  api -X POST "https://api.github.com/repos/${REPO}/actions/workflows/${WORKFLOW}/dispatches" \
    -d '{"ref":"main"}' >/dev/null
  echo "Workflow dispatched. Re-run this script after completion (~15 min)."
  exit 0
fi

echo "Run ID: $run_id"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for artifact in darkworld-launcher-windows darkworld-launcher-macos; do
  url=$(api "https://api.github.com/repos/${REPO}/actions/runs/${run_id}/artifacts" | \
    python3 -c "import sys,json; arts=json.load(sys.stdin)['artifacts']; print(next(a['archive_download_url'] for a in arts if a['name']=='${artifact}'))" 2>/dev/null || true)
  if [ -n "$url" ]; then
    echo "Downloading $artifact..."
    curl -sSL -H "Authorization: Bearer $token" -H "Accept: application/vnd.github+json" "$url" -o "$tmpdir/${artifact}.zip"
    unzip -qo "$tmpdir/${artifact}.zip" -d "$tmpdir/${artifact}"
  fi
done

mkdir -p "$ROOT/build/launcher" "$ROOT/build/launcher-mac"
find "$tmpdir" -name 'DarkWorld-Launcher.exe' -exec cp {} "$ROOT/build/launcher/" \;
find "$tmpdir" -name 'DarkWorld-Launcher-mac.tar.gz' -exec cp {} "$ROOT/build/launcher-mac/" \;

bash "$ROOT/scripts/deploy-launcher-artifacts.sh"
