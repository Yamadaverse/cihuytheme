# Troubleshooting

## Installer says core file hash does not match

One of the eight Pterodactyl integration files differs from both the official v1.15.2 baseline and this theme's integrated version. This may mean the panel is a different release or has another customization. Do not force the replacement. Restore the exact upstream file or review the conflict manually first.

## Installer says the theme is already installed

Do not run installation again. Use `uninstall.sh` to restore the previous panel files, or keep the current installation. Re-running would otherwise replace the original uninstall baseline with a backup of the already-themed files.

## Installer detects a partial installation

The files appear to be a mixture of original and theme versions. The installer stops to avoid creating an unusable uninstall backup. Inspect the latest backup under `/var/backups/neobrutalism-pterodactyl/` and restore the previous state before retrying.

## Database backup fails

No panel files have been changed at that point. Install the appropriate backup utility (`mysqldump`/`mariadb-dump` or `sqlite3`) manually, verify database credentials and permissions, then rerun the preflight. The installer does not install system packages.

## Node.js or Yarn build prerequisites fail

The panel must have Node.js 22+ and Yarn Classic 1.x, plus its existing `node_modules/` and `yarn.lock`. Prepare these dependencies manually according to the official Pterodactyl build process. This installer does not install or upgrade Node.js/Yarn packages.

## Build or migration fails after installation starts

The installer restores panel files and generated frontend assets automatically. If the migration had started, the database is deliberately not rolled back automatically. The database backup remains inside the timestamped backup directory; restore it manually only after reviewing the failure and confirming the correct database.

## Uploaded media

The installer and uninstaller never remove `storage/app/public/theme/`. Background images, videos and music uploaded through Theme Settings are preserved.

## PHP compatibility

The scripts only inspect PHP. If PHP is incompatible, stop and let the administrator handle PHP manually. This project will not install, upgrade, downgrade, or reconfigure PHP.
