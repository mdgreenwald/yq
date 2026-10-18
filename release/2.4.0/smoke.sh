#!/bin/bash
# Smoke-tests a yq 2.4.0 binary on the machine it was built for.
#
# Usage: smoke.sh <path-to-yq-binary>

set -euo pipefail

YQ="${1:?usage: smoke.sh <path-to-yq-binary>}"
chmod +x "$YQ" 2>/dev/null || true

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

fail() {
  echo "FAIL: $1" >&2
  echo "  expected: $2" >&2
  echo "  actual:   $3" >&2
  exit 1
}

check() {
  local name="$1" expected="$2" actual
  actual="$(cat)"
  actual="${actual//$'\r'/}"
  [[ "$actual" == "$expected" ]] || fail "$name" "$expected" "$actual"
  echo "ok: $name"
}

# Same document as upstream's examples/sample.yaml
cat > "$WORK/sample.yaml" <<'EOF'
a: Easy! as one two three
b:
  c: 2
  d: [3, 4]
  e:
    - name: fred
      value: 3
    - name: sam
      value: 4
EOF

"$YQ" --version | check "version" "yq version 2.4.0"

# Upstream's scripts/acceptance.sh
"$YQ" w "$WORK/sample.yaml" b.c 3 | "$YQ" r - b.c | check "acceptance (write | read)" "3"

"$YQ" r "$WORK/sample.yaml" 'b.e[*].name' | check "splat read" "- fred
- sam"

"$YQ" r -j "$WORK/sample.yaml" b.d | check "json output" "[3,4]"

# The numeric key behaviour introduced in 2.4.0
"$YQ" n 'thing[+].cat' fred | check "new with [+] creates an array" "thing:
- cat: fred"
"$YQ" n 'thing[0].cat' fred | check "new with [0] creates a map key" "thing:
  \"0\":
    cat: fred"

echo "all smoke tests passed for $YQ"
