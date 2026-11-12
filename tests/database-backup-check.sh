#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export PANEL_DIR="$TMP/panel"
export BACKUP_ROOT="$TMP/backups"
export LOG_DIR="$TMP/logs"
mkdir -p "$PANEL_DIR" "$TMP/bin" "$TMP/backup"
cat > "$TMP/bin/php" <<'MOCKPHP'
#!/usr/bin/env bash
printf 'mysql\n127.0.0.1\n3306\ntheme_test\nmockuser\nmock-secret\n\n'
MOCKPHP
cat > "$TMP/bin/mysqldump" <<'MOCKDUMP'
#!/usr/bin/env bash
[[ "${MYSQL_PWD:-}" == mock-secret ]] || exit 9
printf 'MOCK DATABASE DUMP\n'
MOCKDUMP
chmod +x "$TMP/bin/php" "$TMP/bin/mysqldump"
export PATH="$TMP/bin:$PATH"
source "$ROOT/lib/common.sh"
BACKUP_DIR="$TMP/backup"
log_init test
backup_database
[[ "$(cat "$BACKUP_DIR/database.sql")" == 'MOCK DATABASE DUMP' ]]
[[ "$(stat -c '%a' "$BACKUP_DIR/database.sql")" == 600 ]]
echo "Database backup command/mode checks passed."
