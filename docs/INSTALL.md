# Installation

## Supported environment

- Ubuntu 24.04.x
- Pterodactyl Panel v1.15.2
- Node.js 22 or newer
- Yarn Classic 1.x
- Existing panel `node_modules/` and `yarn.lock`
- Working database backup utility: `mysqldump`/`mariadb-dump` for MySQL/MariaDB, or `sqlite3` for SQLite

PHP is inspection-only. The installer never changes PHP packages, extensions, configuration, or services.

## 1. Verify the panel

Independently confirm the installed panel version. The override is a manual assertion, not an automatic version detector:

```bash
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./analyze.sh
```

## 2. Install

```bash
chmod +x analyze.sh install.sh uninstall.sh
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./install.sh
```

Read the summary and type `INSTALL`. Before changing files, the installer validates all eight integration files against their official Pterodactyl v1.15.2 Git blob hashes, then creates a timestamped backup of panel files, `public/assets`, and the active database. If any core file is modified by another theme or administrator, it stops without overwriting it.

After confirmation, it copies the theme-owned files, applies the eight version-guarded core replacements, runs the three theme migrations, builds production frontend assets using the already-installed Node/Yarn dependencies, and clears view/config caches.

Do not continue if the backup or preflight reports an error. Do not use this candidate directly on a production VPS before staging validation.

## 3. Uninstall

```bash
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./uninstall.sh
```

Type `RESTORE`. Files and generated assets are restored from the latest installer backup. Database migrations are not rolled back and uploaded theme media are not deleted. Migration files remain in place to keep Laravel's migration history consistent.

## Backup location

`/var/backups/neobrutalism-pterodactyl/`

Do not delete this directory until the panel is verified and you no longer need to restore it.
