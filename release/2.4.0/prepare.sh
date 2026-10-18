#!/bin/bash
# Vendors the dependencies of a yq 2.4.0 checkout so it can be built with GO111MODULE=off.
#
# Usage: prepare.sh <yq-2.4.0-checkout>
#
# The checkout must live at $GOPATH/src/github.com/mikefarah/yq.
# By default the deps come from vendor-2.4.0.tar.gz, committed next to this script, so the build
# needs no third-party repositories. Set VENDOR_FROM_NETWORK=1 to fetch them with govendor instead.

set -euo pipefail

SRC="$(cd "${1:?usage: prepare.sh <yq-2.4.0-checkout>}" && pwd -P)"
GOPATH="${GOPATH:?GOPATH must be set}"
export GOPATH GO111MODULE=off

GOVENDOR_REV=e31350db9750308ce016ebef8350a8ff1e0a37d0
YAML_REPO=https://github.com/mikefarah/yaml.git
YAML_REV=e175af14aaa1d0eff2ee04b691e4a4827a111416
VENDOR_TARBALL="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/vendor-2.4.0.tar.gz"

if [[ "$SRC" != "$(cd "$GOPATH" && pwd -P)/src/github.com/mikefarah/yq" ]]; then
  echo "error: $SRC must be at \$GOPATH/src/github.com/mikefarah/yq" >&2
  exit 1
fi

# govendor is archived, so build a pinned revision in its own GOPATH
TOOLS="${TOOLS_GOPATH:-$GOPATH/../gopath-tools}"
GOVENDOR="$TOOLS/bin/govendor"
if [[ ! -x "$GOVENDOR" ]]; then
  GOVENDOR_SRC="$TOOLS/src/github.com/kardianos/govendor"
  rm -rf "$GOVENDOR_SRC"
  git clone -q https://github.com/kardianos/govendor.git "$GOVENDOR_SRC"
  git -C "$GOVENDOR_SRC" checkout -q "$GOVENDOR_REV"
  (cd "$GOVENDOR_SRC" && GOPATH="$TOOLS" GOBIN="$TOOLS/bin" go install .)
fi

cd "$SRC"

sync_from_network() {
  # The first sync clones gopkg.in/mikefarah/yaml.v2 into govendor's cache but cannot check
  # out the pinned revision, which is no longer on any branch. GitHub still serves it by SHA.
  "$GOVENDOR" sync || true
  local cache="$GOPATH/.cache/govendor/gopkg.in/mikefarah/yaml.v2"
  git -C "$cache" cat-file -e "$YAML_REV^{commit}" 2>/dev/null \
    || git -C "$cache" fetch -q "$YAML_REPO" "$YAML_REV"
  "$GOVENDOR" sync
}

if [[ -n "${VENDOR_FROM_NETWORK:-}" ]]; then
  sync_from_network
else
  find vendor -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
  tar -xzf "$VENDOR_TARBALL" -C "$SRC"
fi

# Verifies every vendored package against checksumSHA1 in vendor/vendor.json
"$GOVENDOR" status
echo "vendor/ verified against vendor.json"

# The release attaches the committed tarball (see .goreleaser.yaml)
cp "$VENDOR_TARBALL" "$SRC/../vendor-2.4.0.tar.gz"
