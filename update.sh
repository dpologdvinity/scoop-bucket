#!/usr/bin/env bash
# Rewrites bucket/yonder.json for the latest yonder release. Prints "unchanged" or the new version.
set -euo pipefail
tag=$(curl -fsSL https://api.github.com/repos/dpologdvinity/yonder/releases/latest | sed -n 's/.*"tag_name": *"\(v[^"]*\)".*/\1/p')
ver=${tag#v}
if grep -q "\"version\": \"$ver\"" bucket/yonder.json 2>/dev/null; then echo unchanged; exit 0; fi
sums=$(curl -fsSL "https://github.com/dpologdvinity/yonder/releases/download/$tag/checksums.txt")
sum() { echo "$sums" | awk -v f="yonder_${ver}_windows_$1.zip" '$2==f {print $1}'; }
url="https://github.com/dpologdvinity/yonder/releases/download/$tag/yonder_${ver}_windows"
a=$(sum amd64); b=$(sum arm64)
[ -n "$a" ] && [ -n "$b" ] || { echo "missing checksum" >&2; exit 1; }
cat > bucket/yonder.json <<JSON
{
  "version": "$ver",
  "description": "your site, over yonder: share a localhost site or files with your phone via a QR code",
  "homepage": "https://github.com/dpologdvinity/yonder",
  "license": "MIT",
  "architecture": {
    "64bit": { "url": "${url}_amd64.zip", "hash": "$a" },
    "arm64": { "url": "${url}_arm64.zip", "hash": "$b" }
  },
  "bin": "yonder.exe"
}
JSON
echo "$ver"
