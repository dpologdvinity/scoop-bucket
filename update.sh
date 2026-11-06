#!/usr/bin/env bash
# Rewrites bucket/<app>.json for the latest release of every app listed at the bottom.
# Prints "unchanged", or the updated apps with their new versions ("yonder 0.6.2, depwhy 1.0.0").
set -euo pipefail

# Authenticated API calls get a far higher rate limit than anonymous ones from shared runners.
auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")

updated=()

# update <app> <description>: the repository dpologdvinity/<app> must publish
# <app>_<version>_windows_{amd64,arm64}.zip and checksums.txt (GoReleaser defaults),
# with <app>.exe inside the zip.
update() {
  local app=$1 desc=$2 tag ver sums url a b
  tag=$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/dpologdvinity/$app/releases/latest" | sed -n 's/.*"tag_name": *"\(v[^"]*\)".*/\1/p')
  [ -n "$tag" ] || { echo "$app: no release tag found" >&2; exit 1; }
  ver=${tag#v}
  if grep -q "\"version\": \"$ver\"" "bucket/$app.json" 2>/dev/null; then return; fi
  sums=$(curl -fsSL "https://github.com/dpologdvinity/$app/releases/download/$tag/checksums.txt")
  sum() { echo "$sums" | awk -v f="${app}_${ver}_windows_$1.zip" '$2==f {print $1}'; }
  url="https://github.com/dpologdvinity/$app/releases/download/$tag/${app}_${ver}_windows"
  a=$(sum amd64); b=$(sum arm64)
  [ -n "$a" ] && [ -n "$b" ] || { echo "$app: missing checksum" >&2; exit 1; }
  cat > "bucket/$app.json" <<JSON
{
  "version": "$ver",
  "description": "$desc",
  "homepage": "https://github.com/dpologdvinity/$app",
  "license": "MIT",
  "architecture": {
    "64bit": { "url": "${url}_amd64.zip", "hash": "$a" },
    "arm64": { "url": "${url}_arm64.zip", "hash": "$b" }
  },
  "bin": "$app.exe"
}
JSON
  updated+=("$app $ver")
}

update yonder "your site, over yonder: share a localhost site or files with your phone via a QR code"
update depwhy "Explains why a package is in your dependency tree, from the lockfile, offline"

if [ ${#updated[@]} -eq 0 ]; then
  echo unchanged
else
  out=$(printf '%s, ' "${updated[@]}")
  echo "${out%, }"
fi
