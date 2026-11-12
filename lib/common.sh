#!/usr/bin/env bash
# Shared installer helpers. PHP is inspection-only; no PHP package/config/service is changed.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PANEL_DIR="${PANEL_DIR:-/var/www/pterodactyl}"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/neobrutalism-pterodactyl}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/logs}"

log_init() {
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/${1}-$(date +%Y%m%d-%H%M%S).log"
  touch "$LOG_FILE"
}
log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" | tee -a "${LOG_FILE:-/dev/null}"; }
die() { log "ERROR: $*"; exit 1; }
require_root() { [[ "${EUID}" -eq 0 ]] || die "Jalankan dengan sudo/root."; }

is_ubuntu_2404() {
  [[ -r /etc/os-release ]] || return 1
  . /etc/os-release
  [[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 24.04 ]]
}

panel_identity_ok() {
  [[ -f "$PANEL_DIR/artisan" && -f "$PANEL_DIR/composer.json" && -f "$PANEL_DIR/package.json" ]] || return 1
  grep -Eq '"name"[[:space:]]*:[[:space:]]*"pterodactyl/panel"' "$PANEL_DIR/composer.json" || return 1
  grep -Eq '"name"[[:space:]]*:[[:space:]]*"pterodactyl-panel"' "$PANEL_DIR/package.json" || return 1
  [[ "${PANEL_VERSION_OVERRIDE:-}" == "1.15.2" ]]
}

check_supported_target() {
  is_ubuntu_2404 || die "OS tidak didukung. Target: Ubuntu 24.04.x."
  [[ -d "$PANEL_DIR" && ! -L "$PANEL_DIR" ]] || die "Panel tidak ditemukan atau PANEL_DIR berupa symlink: $PANEL_DIR"
  panel_identity_ok || die "Identitas panel belum dikonfirmasi. Verifikasi versi 1.15.2 lalu gunakan PANEL_VERSION_OVERRIDE=1.15.2."
  [[ -f "$PANEL_DIR/vendor/autoload.php" ]] || die "Composer dependencies tidak ditemukan (vendor/autoload.php)."
  [[ ! -L "$PANEL_DIR/public/assets" ]] || die "public/assets berupa symlink; build dibatalkan demi keamanan."
  [[ ! -e "$PANEL_DIR/public/assets" || -d "$PANEL_DIR/public/assets" ]] || die "public/assets ada tetapi bukan direktori."
}

safe_relative_path() {
  local rel="$1"
  [[ -n "$rel" && "$rel" != /* && "$rel" != *$'\n'* && "$rel" != *$'\r'* ]] || return 1
  [[ "$rel" != "." && "$rel" != ".." && "$rel" != ../* && "$rel" != */../* && "$rel" != */.. ]] || return 1
  [[ "$rel" != *"//"* && "$rel" != *\\* ]]
}

no_symlink_ancestors() {
  local rel="$1" current="$PANEL_DIR" part
  local -a parts
  IFS='/' read -r -a parts <<< "$rel"
  for part in "${parts[@]}"; do
    current="$current/$part"
    [[ ! -L "$current" ]] || return 1
  done
}

git_blob_sha1() {
  local file="$1" size
  size="$(wc -c < "$file" | tr -d ' ')"
  { printf 'blob %s\0' "$size"; cat -- "$file"; } | sha1sum | awk '{print $1}'
}

payload_files_ok() {
  local manifest="$ROOT_DIR/payload/manifest.txt" rel
  [[ -s "$manifest" ]] || return 1
  while IFS= read -r rel; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    safe_relative_path "$rel" || return 1
    [[ -f "$ROOT_DIR/payload/owned/$rel" && ! -L "$ROOT_DIR/payload/owned/$rel" ]] || return 1
  done < "$manifest"
  [[ "$(grep -vcE '^[[:space:]]*(#|$)' "$manifest")" -eq 8 ]]
}

integration_files_ok() {
  local manifest="$ROOT_DIR/payload/integration-manifest.txt" rel
  [[ -s "$manifest" && -s "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1" ]] || return 1
  while IFS= read -r rel; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    safe_relative_path "$rel" || return 1
    [[ -f "$ROOT_DIR/payload/integration-reference/$rel" && ! -L "$ROOT_DIR/payload/integration-reference/$rel" ]] || return 1
  done < "$manifest"
  local expected hash_path
  while read -r expected hash_path; do
    [[ -z "${expected:-}" || "$expected" == \#* ]] && continue
    [[ "$expected" =~ ^[a-f0-9]{40}$ ]] || return 1
    safe_relative_path "$hash_path" || return 1
    grep -Fxq "$hash_path" "$manifest" || return 1
  done < "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1"
  [[ "$(grep -vcE '^[[:space:]]*(#|$)' "$manifest")" -eq 8 ]] || return 1
  [[ "$(grep -vcE '^[[:space:]]*(#|$)' "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1")" -eq 8 ]]
}

validate_payload() {
  payload_files_ok || die "Payload theme-owned tidak lengkap atau manifest tidak aman."
  integration_files_ok || die "Payload integrasi core tidak lengkap."
  grep -qx 'PAYLOAD_STATUS=complete' "$ROOT_DIR/payload/payload.conf" || die "Payload theme belum lengkap."
  grep -qx 'INTEGRATION_STATUS=hash-guarded' "$ROOT_DIR/payload/payload.conf" || die "Integrasi core belum memiliki baseline hash yang diwajibkan."
  grep -qx 'MIGRATIONS_STATUS=backup-gated' "$ROOT_DIR/payload/payload.conf" || die "Strategi migrasi belum mengaktifkan backup database."
}

integration_preflight() {
  local expected rel current target
  while read -r expected rel; do
    [[ -z "${expected:-}" || "$expected" == \#* ]] && continue
    safe_relative_path "$rel" || die "Path integrasi tidak aman: $rel"
    no_symlink_ancestors "$rel" || die "Symlink terdeteksi: $rel"
    [[ -f "$PANEL_DIR/$rel" ]] || die "File inti panel tidak ditemukan: $rel"
    current="$(git_blob_sha1 "$PANEL_DIR/$rel")"
    target="$(git_blob_sha1 "$ROOT_DIR/payload/integration-reference/$rel")"
    if [[ "$current" != "$expected" && "$current" != "$target" ]]; then
      die "File inti berbeda dari baseline resmi v1.15.2 dan bukan versi theme. Dibatalkan: $rel"
    fi
  done < "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1"
  log "Semua 8 file integrasi cocok dengan baseline resmi v1.15.2 atau sudah terpasang."
}


installation_state() {
  local rel expected total_owned=0 matched_owned=0 total_core=0 matched_core=0 current target
  while IFS= read -r rel; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    if [[ "$rel" == database/migrations/2026_11_11_*.php ]]; then
      if [[ -e "$PANEL_DIR/$rel" && "$(git_blob_sha1 "$PANEL_DIR/$rel")" != "$(git_blob_sha1 "$ROOT_DIR/payload/owned/$rel")" ]]; then
        return 1
      fi
      continue
    fi
    total_owned=$((total_owned + 1))
    if [[ -f "$PANEL_DIR/$rel" ]] && [[ "$(git_blob_sha1 "$PANEL_DIR/$rel")" == "$(git_blob_sha1 "$ROOT_DIR/payload/owned/$rel")" ]]; then
      matched_owned=$((matched_owned + 1))
    fi
  done < "$ROOT_DIR/payload/manifest.txt"
  while read -r expected rel; do
    [[ -z "${expected:-}" || "$expected" == \#* ]] && continue
    total_core=$((total_core + 1))
    if [[ -f "$PANEL_DIR/$rel" ]]; then
      current="$(git_blob_sha1 "$PANEL_DIR/$rel")"
      target="$(git_blob_sha1 "$ROOT_DIR/payload/integration-reference/$rel")"
      [[ "$current" == "$target" ]] && matched_core=$((matched_core + 1))
    fi
  done < "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1"

  if [[ "$matched_owned" -eq 0 && "$matched_core" -eq 0 ]]; then
    return 0
  elif [[ "$matched_owned" -eq "$total_owned" && "$matched_core" -eq "$total_core" ]]; then
    return 2
  fi
  return 1
}

build_preflight() {
  command -v node >/dev/null 2>&1 || die "Node.js tidak ditemukan. Installer tidak memasang atau mengubah Node.js."
  command -v yarn >/dev/null 2>&1 || die "Yarn tidak ditemukan. Installer tidak memasang dependency sistem."
  [[ -d "$PANEL_DIR/node_modules" && -f "$PANEL_DIR/yarn.lock" ]] || die "node_modules/yarn.lock tidak ditemukan. Jalankan persiapan dependency frontend secara manual terlebih dahulu."
  node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 22 ? 0 : 1)' || die "Node.js minimal versi 22 diperlukan oleh Pterodactyl 1.15.2."
  grep -q '"build:production"' "$PANEL_DIR/package.json" || die "Script build:production tidak ditemukan di package.json."
  local yarn_major
  yarn_major="$(yarn --version 2>/dev/null | cut -d. -f1)"
  [[ "$yarn_major" == 1 ]] || die "Diperlukan Yarn Classic 1.x sesuai toolchain panel; installer tidak mengganti Yarn."
}

combined_manifest() {
  { grep -vE '^[[:space:]]*(#|$)' "$ROOT_DIR/payload/manifest.txt"; grep -vE '^[[:space:]]*(#|$)' "$ROOT_DIR/payload/integration-manifest.txt"; } | awk '!seen[$0]++'
}

create_backup() {
  local stamp target rel
  mkdir -p -m 0700 "$BACKUP_ROOT"
  [[ ! -L "$BACKUP_ROOT" ]] || die "BACKUP_ROOT tidak boleh berupa symlink."
  chmod 0700 "$BACKUP_ROOT"
  local backup_real panel_real
  backup_real="$(realpath -e "$BACKUP_ROOT")"; panel_real="$(realpath -e "$PANEL_DIR")"
  [[ "$backup_real" != "$panel_real" && "$backup_real" != "$panel_real/"* ]] || die "Backup harus disimpan di luar direktori panel."
  stamp="$(date +%Y%m%d-%H%M%S)-$$"
  target="$BACKUP_ROOT/$stamp"
  mkdir -p -m 0700 "$target/files"
  chmod 0700 "$target"
  printf '%s\n' "$target" > "$target/.neobrutalism-backup"
  combined_manifest > "$target/manifest.txt"
  : > "$target/absent.txt"
  while IFS= read -r rel; do
    safe_relative_path "$rel" || die "Path manifest tidak aman: $rel"
    no_symlink_ancestors "$rel" || die "Symlink terdeteksi pada path target: $rel"
    if [[ -e "$PANEL_DIR/$rel" ]]; then
      [[ -f "$PANEL_DIR/$rel" ]] || die "Target bukan file biasa: $rel"
      mkdir -p "$target/files/$(dirname "$rel")"
      cp -a -- "$PANEL_DIR/$rel" "$target/files/$rel"
    else
      printf '%s\n' "$rel" >> "$target/absent.txt"
    fi
  done < "$target/manifest.txt"

  if [[ -d "$PANEL_DIR/public/assets" ]]; then
    tar -C "$PANEL_DIR" -cpf "$target/public-assets.tar" public/assets
    printf 'present\n' > "$target/public-assets.state"
  else
    printf 'absent\n' > "$target/public-assets.state"
  fi
  printf '%s\n' "$target" > "$BACKUP_ROOT/LATEST"
  BACKUP_DIR="$target"
  log "Backup file dan public/assets dibuat: $target"
}

backup_database() {
  local -a cfg
  local connection host port database username password sqlite_path socket
  mapfile -t cfg < <(cd "$PANEL_DIR" && php -r '
    require "vendor/autoload.php";
    $app = require "bootstrap/app.php";
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();
    $connection = $app["config"]->get("database.default");
    $db = $app["config"]->get("database.connections." . $connection, []);
    foreach ([$connection, $db["host"] ?? "127.0.0.1", $db["port"] ?? "3306", $db["database"] ?? "", $db["username"] ?? "", $db["password"] ?? "", $db["unix_socket"] ?? ""] as $v) {
      echo str_replace(["\r", "\n"], "", (string) $v), PHP_EOL;
    }
  ')
  connection="${cfg[0]:-mysql}"; host="${cfg[1]:-127.0.0.1}"; port="${cfg[2]:-3306}"
  database="${cfg[3]:-}"; username="${cfg[4]:-}"; password="${cfg[5]:-}"; socket="${cfg[6]:-}"
  [[ -n "$database" ]] || die "DB_DATABASE kosong; tidak bisa membuat backup database otomatis."
  case "$connection" in
    mysql|mariadb)
      local dump_bin
      if command -v mariadb-dump >/dev/null 2>&1; then dump_bin="$(command -v mariadb-dump)"
      elif command -v mysqldump >/dev/null 2>&1; then dump_bin="$(command -v mysqldump)"
      else die "mysqldump/mariadb-dump tidak ditemukan. Backup database wajib sebelum migrasi."; fi
      if [[ -n "$socket" ]]; then
        MYSQL_PWD="$password" "$dump_bin" --single-transaction --routines --triggers --hex-blob --no-tablespaces --socket="$socket" --user="$username" "$database" > "$BACKUP_DIR/database.sql" || die "Backup database MySQL gagal. Tidak ada file panel yang diubah."
      else
        MYSQL_PWD="$password" "$dump_bin" --single-transaction --routines --triggers --hex-blob --no-tablespaces --host="$host" --port="$port" --user="$username" "$database" > "$BACKUP_DIR/database.sql" || die "Backup database MySQL gagal. Tidak ada file panel yang diubah."
      fi
      [[ -s "$BACKUP_DIR/database.sql" ]] || die "File backup SQL kosong."
      chmod 0600 "$BACKUP_DIR/database.sql"
      log "Backup database MySQL tersimpan (password tidak dicatat)."
      ;;
    sqlite)
      sqlite_path="$database"
      [[ "$sqlite_path" = /* ]] || sqlite_path="$PANEL_DIR/$sqlite_path"
      [[ -f "$sqlite_path" ]] || die "File database SQLite tidak ditemukan: $sqlite_path"
      command -v sqlite3 >/dev/null 2>&1 || die "sqlite3 CLI tidak ditemukan; backup SQLite konsisten wajib tersedia sebelum migrasi."
      local sqlite_dest="${BACKUP_DIR//\'/\'\'}"
      sqlite3 "$sqlite_path" ".backup '$sqlite_dest/database.sqlite'" || die "Backup database SQLite gagal."
      [[ -s "$BACKUP_DIR/database.sqlite" ]] || die "File backup SQLite kosong."
      chmod 0600 "$BACKUP_DIR/database.sqlite"
      log "Backup database SQLite tersimpan."
      ;;
    *) die "Driver database '$connection' belum didukung backup otomatis. Tidak ada file panel yang diubah." ;;
  esac
}

apply_owned_payload() {
  local rel owner group
  owner="$(stat -c '%U' "$PANEL_DIR/artisan")"; group="$(stat -c '%G' "$PANEL_DIR/artisan")"
  while IFS= read -r rel; do
    [[ -z "$rel" || "$rel" == \#* ]] && continue
    safe_relative_path "$rel" || die "Path tidak aman: $rel"
    no_symlink_ancestors "$rel" || die "Symlink terdeteksi: $rel"
    install -D -o "$owner" -g "$group" -m 0644 "$ROOT_DIR/payload/owned/$rel" "$PANEL_DIR/$rel"
    log "File theme dipasang: $rel"
  done < "$ROOT_DIR/payload/manifest.txt"
}

apply_integrations() {
  local expected rel current target owner group
  owner="$(stat -c '%U' "$PANEL_DIR/artisan")"; group="$(stat -c '%G' "$PANEL_DIR/artisan")"
  while read -r expected rel; do
    [[ -z "${expected:-}" || "$expected" == \#* ]] && continue
    current="$(git_blob_sha1 "$PANEL_DIR/$rel")"
    target="$(git_blob_sha1 "$ROOT_DIR/payload/integration-reference/$rel")"
    if [[ "$current" == "$target" ]]; then
      log "Integrasi sudah terpasang, dilewati: $rel"
      continue
    fi
    [[ "$current" == "$expected" ]] || die "Baseline berubah setelah preflight: $rel"
    install -D -o "$owner" -g "$group" -m 0644 "$ROOT_DIR/payload/integration-reference/$rel" "$PANEL_DIR/$rel"
    log "Integrasi theme diterapkan setelah hash cocok: $rel"
  done < "$ROOT_DIR/payload/integration-upstream-v1.15.2.sha1"
}

restore_generated_assets() {
  local backup="$1"
  [[ -f "$backup/public-assets.state" ]] || return 0
  [[ ! -L "$PANEL_DIR/public/assets" ]] || die "public/assets berubah menjadi symlink; restore asset dibatalkan."
  rm -rf -- "$PANEL_DIR/public/assets"
  if [[ "$(cat "$backup/public-assets.state")" == present ]]; then
    tar -C "$PANEL_DIR" -xpf "$backup/public-assets.tar"
  fi
}

restore_backup_dir() {
  local backup="$1" rel
  [[ -d "$backup" && -f "$backup/.neobrutalism-backup" && -f "$backup/manifest.txt" ]] || die "Folder bukan backup installer yang valid."
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    safe_relative_path "$rel" || die "Path backup tidak aman: $rel"
    no_symlink_ancestors "$rel" || die "Symlink terdeteksi saat restore: $rel"
    if [[ -f "$backup/files/$rel" ]]; then
      mkdir -p "$PANEL_DIR/$(dirname "$rel")"
      cp -a --remove-destination "$backup/files/$rel" "$PANEL_DIR/$rel"
      log "Dipulihkan: $rel"
    fi
  done < "$backup/manifest.txt"
  if [[ -f "$backup/absent.txt" ]]; then
    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      safe_relative_path "$rel" || die "Path absent-list tidak aman: $rel"
      no_symlink_ancestors "$rel" || die "Symlink terdeteksi saat restore: $rel"
      if [[ "${PRESERVE_THEME_MIGRATIONS:-0}" == 1 && "$rel" == database/migrations/2026_11_11_*.php ]]; then
        log "File migrasi dipertahankan agar riwayat migrasi database tetap valid: $rel"
        continue
      fi
      [[ ! -e "$PANEL_DIR/$rel" ]] || rm -f -- "$PANEL_DIR/$rel"
      log "File baru yang sebelumnya tidak ada dihapus: $rel"
    done < "$backup/absent.txt"
  fi
  restore_generated_assets "$backup"
}

run_build() {
  (cd "$PANEL_DIR" && yarn run build:production)
}
