# NEOBRUTALISM Theme Installer for Pterodactyl

**Release state: functional installer candidate — staging validation required before production use.** This package now performs a guarded installation: it backs up the panel files, backs up the configured database, replaces the theme-owned files, updates eight Pterodactyl core files only when their official v1.15.2 Git blob hashes match, runs the theme migrations after administrator confirmation, and builds the frontend assets.

## Supported target

- Ubuntu 24.04.x
- Pterodactyl Panel v1.15.2
- Node.js 22+ and Yarn Classic 1.x, with the panel's existing `node_modules` and `yarn.lock`
- PHP is inspection-only. This installer never installs, upgrades, downgrades, configures, or restarts PHP or PHP-FPM.

## Theme features in this source

- NEOBRUTALISM styling for the admin and user panels
- Admin Theme Settings page
- Light/dark background images
- Light/dark background videos
- Music player with floating volume control
- Dashboard server list styling
- Server navigation, console and power-button styling

## Install

First, verify the panel really is Pterodactyl v1.15.2. The version override is an explicit administrator assertion because upstream metadata can show `canary`; it is not automatic proof.

```bash
chmod +x analyze.sh install.sh uninstall.sh
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./analyze.sh
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./install.sh
```

The installer requires an interactive `INSTALL` confirmation. Before changing panel files, it:

1. checks Ubuntu and panel identity;
2. checks all eight core files against the official v1.15.2 Git blob hashes (or the already-installed theme hashes);
3. checks Node.js/Yarn build prerequisites;
4. backs up the files and `public/assets`;
5. backs up the active MySQL/MariaDB or SQLite database.

It then applies the theme files, applies the eight guarded integrations, runs `php artisan migrate --force`, builds `yarn run build:production`, and clears Laravel view/config caches. It does not install frontend dependencies or alter system packages.

## Uninstall

```bash
sudo PANEL_VERSION_OVERRIDE=1.15.2 ./uninstall.sh
```

Type `RESTORE` when prompted. The uninstaller restores panel files and generated frontend assets from the latest backup. It deliberately does **not** roll back the database, delete `theme_settings`, or remove user media. Theme migration files are retained so Laravel's migration history remains consistent.

## Backups and logs

- Backups: `/var/backups/neobrutalism-pterodactyl/`
- Installer logs: `logs/`
- The database dump is stored with restrictive permissions inside the timestamped backup directory.

Keep the backup directory until the panel has been checked and the theme is confirmed working.

## Data and PHP safety

- `storage/app/public/theme/` is never overwritten or deleted. Uploaded backgrounds, videos and music remain intact.
- `.env`, database dumps, `vendor/`, `node_modules/`, generated assets, server configuration and customer data are not included in the ZIP.
- No `migrate:fresh`, `db:wipe`, or automatic migration rollback is used.
- PHP version/extensions/configuration and PHP-FPM are only inspected, never modified.
- If a core file differs from the exact official baseline and from the theme version, installation stops before panel files are changed.

## Validation status

Static checks, PHP syntax checks, and isolated installer backup/apply/idempotence/restore checks pass. This package has **not** yet been tested end-to-end on a disposable Ubuntu 24.04 + Pterodactyl 1.15.2 machine. Test it on a staging clone with a restorable database backup before using it on a production panel.
