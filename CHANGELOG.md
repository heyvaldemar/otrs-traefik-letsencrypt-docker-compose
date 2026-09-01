# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

_(no unreleased changes yet)_

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

[Unreleased]: https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/releases/tag/v1.0.0
