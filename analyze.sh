#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"
QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1
log_init analyze
failures=0
report() { [[ "$QUIET" -eq 1 ]] && return 0; printf '[%s] %s\n' "$1" "$2"; }
check() { local label="$1"; shift; if "$@"; then report "OK" "$label"; else report "WARN" "$label"; failures=$((failures+1)); fi; }
check "Ubuntu 24.04.x" is_ubuntu_2404
check "Panel directory exists: $PANEL_DIR" test -d "$PANEL_DIR"
check "Pterodactyl identity and explicit 1.15.2 confirmation" panel_identity_ok
check "PHP CLI available (inspection only)" command -v php
check "PHP version inspection" php -v
check "Composer available" command -v composer
check "Node.js available" command -v node
check "Yarn available" command -v yarn
check "Nginx available" command -v nginx
check "Theme-owned payload valid" payload_files_ok
check "Eight integration references and upstream hashes valid" integration_files_ok
if [[ -d "$PANEL_DIR" ]]; then
  check "Eight core files match official v1.15.2 or theme state" integration_preflight
fi
if [[ "$QUIET" -eq 0 ]]; then
  echo
  echo "Installer: functional candidate with guarded core replacement and database backup gate."
  echo "A full disposable Ubuntu 24.04 + Pterodactyl 1.15.2 build/runtime test is still required before production use."
  echo "PHP is inspection-only. No PHP packages, extensions, configuration, or services are changed."
  echo "Log: $LOG_FILE"
fi
[[ "$failures" -eq 0 ]]
