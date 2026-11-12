# Payload inventory and installer safeguards

## Theme-owned files

The eight files listed in `payload/manifest.txt` are copied into the panel after the installer has made backups. They include the settings controller/view, audio player partial, theme CSS and three database migrations.

## Modified Pterodactyl core files

Eight full-file integration references are stored under `payload/integration-reference/`. They are not copied blindly. `payload/integration-upstream-v1.15.2.sha1` contains the official Git blob SHA-1 for each pristine file at tag `v1.15.2`. The installer computes the Git blob hash of the live file and permits replacement only if it matches that exact upstream hash. It also recognizes the exact theme-integrated file hash to support safe detection of an already-installed theme.

If any file differs from both known states, the installer stops before modifying panel files. This avoids overwriting other themes or administrator customizations.

## Database migrations

The installer reads the active Laravel database configuration, creates a database backup first, and requires the administrator to type `INSTALL` before applying migrations. Supported backup methods:

- MySQL/MariaDB: `mysqldump` or `mariadb-dump`
- SQLite: `sqlite3` CLI `.backup`

There is no automatic `migrate:rollback`, `migrate:fresh`, or `db:wipe`. The uninstaller retains migration files and database tables to preserve migration history and user settings.

## Release gates

`payload/payload.conf` currently uses:

- `PAYLOAD_STATUS=complete`
- `INTEGRATION_STATUS=hash-guarded`
- `MIGRATIONS_STATUS=backup-gated`

These values enable the guarded installer workflow. They do not mean that a full end-to-end disposable Ubuntu/Pterodactyl test has passed. Staging validation remains required before production use.

## Exclusions

The ZIP excludes `.env`, secrets, database dumps, uploaded media, `storage/logs`, `vendor/`, `node_modules/`, generated build output, PHP/Nginx configuration and customer data.
