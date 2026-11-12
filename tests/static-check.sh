#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
for f in "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/analyze.sh" "$ROOT/lib/common.sh" "$ROOT"/tests/*.sh; do bash -n "$f"; done
while IFS= read -r rel; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  [[ -f "$ROOT/payload/owned/$rel" ]] || { echo "Missing owned payload: $rel" >&2; exit 1; }
done < "$ROOT/payload/manifest.txt"
while IFS= read -r rel; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  [[ -f "$ROOT/payload/integration-reference/$rel" ]] || { echo "Missing integration reference: $rel" >&2; exit 1; }
done < "$ROOT/payload/integration-manifest.txt"
while read -r sha rel; do
  [[ -z "${sha:-}" || "$sha" == \#* ]] && continue
  [[ "$sha" =~ ^[a-f0-9]{40}$ ]] || { echo "Invalid upstream blob hash: $rel" >&2; exit 1; }
  grep -Fxq "$rel" "$ROOT/payload/integration-manifest.txt" || { echo "Hash path not in integration manifest: $rel" >&2; exit 1; }
  size="$(wc -c < "$ROOT/payload/integration-reference/$rel" | tr -d ' ')"
  actual="$( { printf 'blob %s\0' "$size"; cat "$ROOT/payload/integration-reference/$rel"; } | sha1sum | awk '{print $1}')"
  [[ "$actual" != "$sha" ]] || { echo "Integration target unexpectedly equals upstream baseline: $rel" >&2; exit 1; }
done < "$ROOT/payload/integration-upstream-v1.15.2.sha1"
grep -qx 'PAYLOAD_STATUS=complete' "$ROOT/payload/payload.conf"
grep -qx 'INTEGRATION_STATUS=hash-guarded' "$ROOT/payload/payload.conf"
grep -qx 'MIGRATIONS_STATUS=backup-gated' "$ROOT/payload/payload.conf"
# PHP files are syntax-checked only; no PHP packages or settings are changed.
if command -v php >/dev/null 2>&1; then
  find "$ROOT/payload/owned" -type f -name '*.php' -print0 | while IFS= read -r -d '' f; do php -l "$f" >/dev/null; done
fi
echo "Static checks passed. Installer is hash-guarded and backup-gated; disposable live-stack test is still required."
