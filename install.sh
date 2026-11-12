#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"
require_root
log_init install

BACKUP_DIR=""
INSTALL_COMMITTED=0
MIGRATION_STARTED=0
ROLLBACK_RUNNING=0

on_exit() {
  local rc=$?
  if [[ "$rc" -ne 0 && -n "$BACKUP_DIR" && "$INSTALL_COMMITTED" -ne 1 && "$ROLLBACK_RUNNING" -ne 1 ]]; then
    ROLLBACK_RUNNING=1
    set +e
    log "Instalasi gagal. Memulihkan file panel dan asset dari backup."
    if [[ "$MIGRATION_STARTED" -eq 1 ]]; then
      PRESERVE_THEME_MIGRATIONS=1 restore_backup_dir "$BACKUP_DIR"
      log "PERHATIAN: migrasi database sudah dimulai. Backup database tersedia di $BACKUP_DIR; pemulihan DB harus dilakukan manual jika diperlukan. Tidak ada migrate:rollback otomatis."
    else
      restore_backup_dir "$BACKUP_DIR"
    fi
    log "Rollback file selesai. Backup tetap disimpan: $BACKUP_DIR"
  fi
  exit "$rc"
}
trap on_exit EXIT

check_supported_target
validate_payload
integration_preflight
if installation_state; then
  install_state=0
else
  install_state=$?
fi
case "$install_state" in
  0) ;;
  2) die "Theme sudah terpasang lengkap. Jangan buat backup ulang; gunakan uninstall.sh bila ingin melepasnya." ;;
  *) die "Terdeteksi instalasi theme parsial/campuran. Dibatalkan agar backup uninstall tidak menyimpan kondisi setengah terpasang." ;;
esac
build_preflight
create_backup
backup_database

cat <<'NOTICE'

Installer NEOBRUTALISM akan:
 - memasang file theme milik project;
 - mengganti 8 file inti HANYA jika hash cocok dengan Pterodactyl v1.15.2 resmi;
 - menjalankan migrasi setelah backup database;
 - membangun asset frontend.

PHP tidak akan diinstal/di-upgrade/diubah. storage/app/public/theme tidak disentuh.
NOTICE
read -r -p "Ketik INSTALL untuk melanjutkan: " answer
[[ "$answer" == "INSTALL" ]] || die "Dibatalkan oleh administrator. Tidak ada file panel yang diubah. Backup audit: $BACKUP_DIR"

apply_owned_payload
apply_integrations
MIGRATION_STARTED=1
log "Menjalankan migrasi theme setelah backup database..."
(cd "$PANEL_DIR" && php artisan migrate --force)
log "Migrasi selesai. Tidak ada migrate:rollback yang dijalankan."
log "Membangun asset frontend menggunakan dependency yang sudah tersedia..."
run_build
(cd "$PANEL_DIR" && php artisan view:clear && php artisan config:clear)
INSTALL_COMMITTED=1
log "INSTALASI NEOBRUTALISM SELESAI."
log "Backup file dan database: $BACKUP_DIR"
log "Untuk melepas theme, jalankan sudo ./uninstall.sh dan konfirmasi RESTORE."
