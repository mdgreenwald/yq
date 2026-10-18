#!/bin/bash
# Copies GoReleaser's output into a flat directory using the release asset names
# (yq_<os>_<arch>[.exe], vendor-2.4.0.tar.gz, checksums.txt) and verifies the checksums.
#
# Usage: stage.sh <goreleaser-dist-dir> <out-dir>

set -euo pipefail

DIST="$(cd "${1:?usage: stage.sh <dist> <out>}" && pwd -P)"
OUT="${2:?usage: stage.sh <dist> <out>}"
EXPECTED_BINARIES=23

mkdir -p "$OUT"

jq -r '.[] | select(.type == "Binary" and (.name | startswith("yq_"))) | "\(.name)\t\(.path)"' \
  "$DIST/artifacts.json" | while IFS=$'\t' read -r name path; do
  cp "$path" "$OUT/$name"
done
cp "$DIST/../vendor-2.4.0.tar.gz" "$DIST/checksums.txt" "$OUT/"

count="$(find "$OUT" -maxdepth 1 -name 'yq_*' | wc -l | tr -d ' ')"
if [[ "$count" != "$EXPECTED_BINARIES" ]]; then
  echo "error: expected $EXPECTED_BINARIES binaries in $OUT, found $count" >&2
  exit 1
fi

cd "$OUT"
if command -v sha256sum >/dev/null; then
  sha256sum -c checksums.txt
else
  shasum -a 256 -c checksums.txt
fi
