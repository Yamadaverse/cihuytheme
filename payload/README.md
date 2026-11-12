# Payload

`owned/` contains the eight theme-owned files installed after backup.

`integration-reference/` contains the eight complete Pterodactyl core files with the theme changes. They are applied only when the installed file's Git blob hash exactly matches the official v1.15.2 baseline listed in `integration-upstream-v1.15.2.sha1`, or are already identical to the theme reference.

`manifest.txt` lists theme-owned files. `integration-manifest.txt` lists the guarded core files. The installer backs up all of them before making changes.

The installer candidate includes database backup and explicit migration confirmation. Full end-to-end disposable-environment testing is still required before production deployment.
