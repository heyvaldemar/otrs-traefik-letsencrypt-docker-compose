# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

## [1.1.0] - 2026-09-02

### Fixed

- **A file changing while the data archive is written no longer marks
  the backup as failed.** GNU `tar` exits 1 when a live application
  touched a file mid-read; the archive is complete and usable. The loop
  now treats exit 1 as success (noting it in the log line) and only a
  real `tar` failure (exit 2) produces `FAILED`. CI's archive check now
  reads the file name from the `backup OK` log line instead of racing an
  archive that may still be being written.

### Added

- **`tests/e2e-backup-restore.sh`** — seven end-to-end scenarios against
  the live stack, run by CI on every push and by you locally: the
  required-variable guard fires, a backup is produced, it is a readable
  archive with real dump content (and a readable data `tar.gz` where the
  stack has one), a database outage is reported as `FAILED`, **restore
  genuinely replaces database state** (a marker row inserted after the
  baseline backup is gone after restoring it), and pruning removes only
  old files.

### Fixed

- **A failed database dump no longer produces a silent, corrupt backup.**
  The old loop piped the dump into `gzip` and only checked `gzip`'s exit
  status, so a dump that failed halfway (database down, wrong password,
  disk full) still left a small `.gz` that looked like a backup. The loop
  now runs with `pipefail`, logs `Database backup OK: <file> (<bytes>
  bytes)` or `Database backup FAILED` per cycle, keeps a failed dump as
  `<file>.failed` for diagnosis, and prunes only its own files. Retention
  set to `0` disables pruning instead of deleting everything.

### Added

- CI now waits for the first backup cycle and proves the produced
  archive is readable and contains a real dump header (plus a readable
  `tar.gz` for the data backup where the stack has one).

## [1.0.0] - 2026-09-01

First semver release. Brings this template to the fleet standard established
in [keycloak-traefik-letsencrypt-docker-compose](https://github.com/heyvaldemar/keycloak-traefik-letsencrypt-docker-compose)
v1.2.0.

### Changed

- **Both application images pinned by digest.** ❗ Be aware: the
  community images this template builds on
  (`juanluisbaptiste/znuny`, `juanluisbaptiste/otrs-mariadb`) have not
  been rebuilt upstream since May 2023. The pins freeze the exact
  build CI verifies; the weekly digest check will tell you if upstream
  ever moves again. For a maintained helpdesk stack, consider the
  [zammad template](https://github.com/heyvaldemar/zammad-traefik-letsencrypt-docker-compose).
- **Traefik 3.2 → 3.7** (3.2's Docker client cannot talk to Docker
  Engine 29).
- **SMTP is off by default** — set the `OTRS_SMTP_*` variables to
  enable outgoing mail.

### Security

- **Credentials untracked from git.** The tracked `.env` carried
  generated-looking database and admin passwords plus SMTP relay
  credentials — rotate them all if reused.

### Fixed

- Backup-loop variables are `$$`-escaped so the container shell resolves
  them at runtime; shellcheck findings in both restore scripts.

### Added

- **Deployment Verification workflow**: shellcheck + actionlint; Trivy
  scans of all three pinned images; weekly digest-drift check; and a
  deploy-and-test job that boots the stack and requires the Znuny login
  page to answer through Traefik.

[Unreleased]: https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
