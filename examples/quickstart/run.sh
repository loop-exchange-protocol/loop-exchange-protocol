#!/usr/bin/env bash
set -euo pipefail

TMP="${1:-${TMPDIR:-/tmp}/lxp-quickstart}"
BIN="${LXP_BIN:-lxp}"
PUBLISHER="$TMP/publisher"
CONSUMER="$TMP/consumer"
CONTINUED="$TMP/continued"
FIRST="$TMP/generation-1.lxpz"
SECOND="$TMP/generation-2.lxpz"

rm -rf "$TMP"
command -v "$BIN" >/dev/null 2>&1 || {
  printf 'lxp CLI not found; set LXP_BIN=/absolute/path/to/lxp\n' >&2
  exit 1
}

printf '%s\n' '[1/7] Init a workspace with one Git Component'
"$BIN" init "$PUBLISHER"
mkdir "$PUBLISHER/source"
git -C "$PUBLISHER/source" init -b main >/dev/null
printf 'base\n' > "$PUBLISHER/source/README.md"
git -C "$PUBLISHER/source" add README.md
git -C "$PUBLISHER/source" -c user.name='LXP Quickstart' -c user.email='lxp@example.test' commit -m initial >/dev/null
printf 'selected by LXP\n' >> "$PUBLISHER/source/README.md"
printf 'must stay untracked\n' > "$PUBLISHER/source/draft.txt"

printf '%s\n' '[2/7] Discover the repository and select one change'
(cd "$PUBLISHER" && "$BIN" status --format json > "$TMP/status-before.json")
grep -q 'source' "$TMP/status-before.json"
if (cd "$PUBLISHER" && "$BIN" export "$TMP/blocked.lxpz") >"$TMP/blocked.out" 2>&1; then
  printf '%s\n' 'expected Export to reject an unowned repository' >&2
  exit 1
fi
grep -q 'unregistered paths' "$TMP/blocked.out"
(cd "$PUBLISHER" && "$BIN" add source/README.md)
(cd "$PUBLISHER" && "$BIN" status --format json > "$TMP/status-after.json")
grep -q '"source"' "$TMP/status-after.json"
grep -q 'draft.txt' "$TMP/status-after.json"

printf '%s\n' '[3/7] Export and inspect generation 1'
(cd "$PUBLISHER" && "$BIN" export "$FIRST")
"$BIN" inspect "$FIRST" > "$TMP/generation-1.manifest.yaml"
grep -q 'provider: git' "$TMP/generation-1.manifest.yaml"
grep -q 'distribution: embedded' "$TMP/generation-1.manifest.yaml"
"$BIN" requirements --format json "$FIRST" > "$TMP/generation-1.requirements.json"
grep -q '"ready":true' "$TMP/generation-1.requirements.json"

printf '%s\n' '[4/7] Delete the publisher and import the standalone Artifact'
rm -rf "$PUBLISHER"
"$BIN" import "$FIRST" "$CONSUMER"
test "$(cat "$CONSUMER/source/README.md")" = $'base\nselected by LXP'
test ! -e "$CONSUMER/source/draft.txt"
test "$(git -C "$CONSUMER/source" diff --cached --name-only)" = 'README.md'

printf '%s\n' '[5/7] Continue work and export generation 2'
printf 'generation 2\n' >> "$CONSUMER/source/README.md"
(cd "$CONSUMER" && "$BIN" add source/README.md)
(cd "$CONSUMER" && "$BIN" export "$SECOND")
"$BIN" inspect "$SECOND" > "$TMP/generation-2.manifest.yaml"
grep -q 'parent: sha256:' "$TMP/generation-2.manifest.yaml"

printf '%s\n' '[6/7] Delete generation 1 and import generation 2'
rm -rf "$CONSUMER" "$FIRST"
"$BIN" import "$SECOND" "$CONTINUED"
test "$(cat "$CONTINUED/source/README.md")" = $'base\nselected by LXP\ngeneration 2'

printf '%s\n' '[7/7] Show the generated exchange YAML'
sed -n '1,220p' "$TMP/generation-2.manifest.yaml"
printf '%s\n' "PASS: git-only init/add/status/export/import/continue ($TMP)"
