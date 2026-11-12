#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"
require_root
log_init uninstall
[[ -d "$BACKUP_ROOT" ]] || die "Folder backup tidak ditemukan: $BACKUP_ROOT"
if [[ -f "$BACKUP_ROOT/LATEST" ]]; then
  latest="$(cat "$BACKUP_ROOT/LATEST")"
else
  latest="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' -printf '%T@ %p\n' | sort -nr | head -n1 | cut -d' ' -f2-)"
fi
[[ -n "${latest:-}" && "$latest" == "$BACKUP_ROOT/"* ]] || die "Backup terbaru tidak valid."
[[ -d "$latest" && ! -L "$latest" && -f "$latest/.neobrutalism-backup" ]] || die "Folder backup bukan backup installer yang valid."
check_supported_target
integration_preflight
if installation_state; then
  install_state=0
else
  install_state=$?
fi
[[ "$install_state" -eq 2 ]] || die "Kondisi file panel tidak lagi sama dengan instalasi theme. Uninstall otomatis dihentikan agar tidak menimpa perubahan administrator atau upgrade panel."
echo "Backup yang akan dipulihkan: $latest"
echo "Database tidak di-rollback; tabel theme_settings dan file media tetap dipertahankan."
read -r -p "Ketik RESTORE untuk melepas theme dan memulihkan file panel: " answer
[[ "$answer" == "RESTORE" ]] || die "Dibatalkan."
PRESERVE_THEME_MIGRATIONS=1 restore_backup_dir "$latest"
(cd "$PANEL_DIR" && php artisan view:clear && php artisan config:clear)
log "Pemulihan file selesai. Database dan storage/app/public/theme tidak disentuh. File migrasi theme dipertahankan untuk menjaga riwayat migrasi Laravel."
