# Znuny (OTRS) + Traefik + Let's Encrypt on Docker Compose

[![Deployment Verification](https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml/badge.svg?branch=main)](https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This repository deploys **Znuny** (the community fork of OTRS) behind **Traefik** with automatic **Let's Encrypt TLS**, backed by **MariaDB**, with scheduled **backups** (database + application data) and companion **restore scripts**.

> ⚠️ **Upstream honesty note.** The community images this template builds on (`juanluisbaptiste/znuny` and its MariaDB companion) have not been rebuilt since May 2023. This template pins the exact digests CI verifies to boot and serve, and the weekly digest check will flag if upstream ever moves, but no new Znuny releases or security patches are flowing into these images. For a maintained open-source helpdesk, consider the [Zammad template](https://github.com/heyvaldemar/zammad-traefik-letsencrypt-docker-compose).

## Getting started

```bash
# 1. Clone
git clone https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose
cd otrs-traefik-letsencrypt-docker-compose

# 2. Create the two Docker networks the stack expects
docker network create traefik-network
docker network create otrs-network

# 3. Copy the environment template and fill in required values
cp .env.example .env
$EDITOR .env
# ^ Required: three generated passwords, OTRS_HOSTNAME,
#   TRAEFIK_HOSTNAME, TRAEFIK_ACME_EMAIL, TRAEFIK_BASIC_AUTH.

# 4. Deploy
docker compose -f otrs-traefik-letsencrypt-docker-compose.yml -p otrs up -d
```

First start installs the database. Give it a few minutes. Then `https://${OTRS_HOSTNAME}/otrs/index.pl` serves the agent login; sign in as `root@localhost` with `OTRS_ADMIN_PASSWORD`.

### What success looks like

```bash
docker compose -f otrs-traefik-letsencrypt-docker-compose.yml -p otrs ps
curl -fskL -o /dev/null -w "%{http_code}\n" "https://${OTRS_HOSTNAME}/otrs/index.pl"
```

### Common first-deploy issues

- **Cert issuance fails.** DNS hasn't propagated or port 80 isn't reachable from the internet.
- **`docker compose up` fails with `set in .env`.** A required variable is empty; the error names it.
- **Networks not found.** Step 2 was skipped.
- **Login page loops or 500s early on.** The first-start database installation is still running. Check `docker logs otrs-otrs-1`.

## Supply chain trust

Three images ([`traefik`](https://hub.docker.com/_/traefik), [`juanluisbaptiste/znuny`](https://hub.docker.com/r/juanluisbaptiste/znuny), [`juanluisbaptiste/otrs-mariadb`](https://hub.docker.com/r/juanluisbaptiste/otrs-mariadb)) pinned by digest as interpolation defaults in the compose `x-images` block. `git pull` alone delivers the tested combination.

Two override levels exist per image. `<PREFIX>_IMAGE_VERSION` in `.env` swaps only the version of that image (Compose then pulls the tag, without a digest) and leaves every other pin as tested; `<PREFIX>_IMAGE_TAG` replaces the whole reference, digest included. The variable names are listed in `.env.example`. Nested defaults need Docker Compose v2.5 or newer (2022); v2.0 to v2.4 leave the inner `${...}` unexpanded and `docker compose up` fails with an invalid reference instead of deploying something unexpected.

The daily `check-pin-freshness` CI job re-resolves each pin against its registry (digest drift) and compares the pinned Traefik version against the latest release. GitHub Actions are pinned by commit SHA; Dependabot keeps those fresh.

## Production checklist

- [ ] **Understand the upstream staleness** (see the note at the top) and have a migration plan.
- [ ] **Strong secrets**: three generated passwords at 24+ random characters; regenerate the Traefik dashboard hash.
- [ ] **Host-mount the backup volumes** for disaster recovery.
- [ ] **Verify Let's Encrypt cert issuance** in the Traefik logs on first start.

## Backups and restore

The `backups` container runs a `mysqldump | gzip` + `tar.gz`-of-data → prune → sleep loop (defaults: 30-minute warm-up, 24-hour interval, 7-day retention). Restore with the interactive scripts (`chmod +x *.sh` once): `./otrs-restore-database.sh`, then `./otrs-restore-application-data.sh`.

## Resource limits

Every service carries memory and CPU limits plus reservations as compose-level defaults, the same values CI boots the stack under. Override any of them in `.env` (the knobs and their defaults are listed in `.env.example`, e.g. `TRAEFIK_MEMORY_LIMIT=512m`) and the override survives every `git pull`. If a service is OOM-killed under real load, `docker inspect <container> --format '{{.State.OOMKilled}}'` says so; raise its `_MEMORY_LIMIT` and recreate.

## Container hardening

Every service runs with `security_opt: no-new-privileges:true`, so a process cannot gain privileges through setuid binaries even if it escapes its initial capability set. Infrastructure containers (the reverse proxy, databases, caches, backups) run with `cap_drop: [ALL]` and add back only what their entrypoints need: `NET_BIND_SERVICE` for Traefik to bind :80/:443, `CHOWN`/`SETUID`/`SETGID` (and friends) for database images to own their data directory and drop to their service user. Application containers keep the default capability set on purpose: upstream images assume it, and a wrong guess there is a boot loop in production rather than a hardening win. CI boots the stack under exactly these settings on every push, so what ships is what was tested.

## Testing

The [Deployment Verification](https://github.com/heyvaldemar/otrs-traefik-letsencrypt-docker-compose/actions/workflows/deployment-verification.yml?query=branch%3Amain) workflow runs on every push, pull request, and every day at 06:00 UTC: shellcheck + actionlint, Trivy scans of all three pinned images, the weekly digest check, and a deploy-and-test job that boots the stack with ephemeral credentials and requires the Znuny login page to answer through Traefik.

### Backup and restore, proven

`tests/e2e-backup-restore.sh` runs against the live stack and is what CI executes after the HTTPS smoke. The scenario that matters most is the restore roundtrip: insert a marker row, restore the earliest backup, assert the marker is gone. A backup that cannot be restored fails the build. Run it yourself against a running deployment with short intervals in `.env` (`BACKUP_INIT_SLEEP=15s`, `BACKUP_INTERVAL=60s`):

```bash
chmod +x tests/e2e-backup-restore.sh
./tests/e2e-backup-restore.sh
```

It stops the database container briefly to prove failure detection. Run it on a staging copy, not on production.

## Security Notes

- Credentials are read from `.env` at deploy time; `.env` is gitignored and compose fails fast on missing required variables.
- **Pre-rotation advisory.** Releases before v1.0.0 (2026-09-01) shipped a tracked `.env` with generated-looking database and admin passwords plus SMTP relay credentials. Rotate them all if your deployment reused them.
- The pinned application images date from May 2023. Treat the Trivy findings in the Security tab accordingly and keep this stack off the open internet if you can.

---

## About the maintainer

<div align="center">

**Maintained by [Vladimir Mikhalev](https://github.com/heyvaldemar)** · Docker Captain · IBM Champion · AWS Community Builder

[YouTube](https://www.youtube.com/channel/UCf85kQ0u1sYTTTyKVpxrlyQ?sub_confirmation=1) · [Blog](https://heyvaldemar.com) · [LinkedIn](https://www.linkedin.com/in/heyvaldemar/)

</div>
