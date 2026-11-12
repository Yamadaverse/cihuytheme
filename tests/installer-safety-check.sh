#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export PANEL_DIR="$TMP/panel"
export BACKUP_ROOT="$TMP/backups"
export LOG_DIR="$TMP/logs"
mkdir -p "$PANEL_DIR"
printf '#!/usr/bin/env php\n' > "$PANEL_DIR/artisan"
chmod 0644 "$PANEL_DIR/artisan"
while IFS= read -r rel; do
  [[ -z "$rel" || "$rel" == \#* ]] && continue
  mkdir -p "$PANEL_DIR/$(dirname "$rel")"
  cp "$ROOT/payload/integration-reference/$rel" "$PANEL_DIR/$rel"
done < "$ROOT/payload/integration-manifest.txt"
mkdir -p "$PANEL_DIR/public/assets"
printf 'original asset\n' > "$PANEL_DIR/public/assets/test.js"
source "$ROOT/lib/common.sh"
log_init test
integration_preflight
create_backup
apply_owned_payload
apply_integrations
printf 'changed asset\n' > "$PANEL_DIR/public/assets/test.js"
if installation_state; then echo "Expected complete installed state (return 2)." >&2; exit 1; else [[ "$?" -eq 2 ]]; fi
[[ -f "$PANEL_DIR/app/Http/Controllers/Admin/ThemeSettingsController.php" ]]
# Applying twice must be idempotent.
apply_integrations
# Restore removes only theme-owned paths absent before installation and restores originals.
restore_backup_dir "$BACKUP_DIR"
[[ ! -e "$PANEL_DIR/app/Http/Controllers/Admin/ThemeSettingsController.php" ]]
[[ -f "$PANEL_DIR/resources/views/layouts/admin.blade.php" ]]
[[ "$(cat "$PANEL_DIR/public/assets/test.js")" == 'original asset' ]]
echo "Installer backup/apply/idempotence/restore checks passed."
