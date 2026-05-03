# Changelog

All notable changes to hearth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial public release of the hearth OpenClaw skill
- 5-layer probe pattern (ping, uptime+load, memory+disk, services, app health)
- Per-device YAML configuration with env-var-based credentials
- Six device archetypes: linux-systemd, linux-nosystemd-chroot, raspberry-pi, windows-http-only, slurm-cluster, magento-server
- Tailscale connectivity check support
- Honest reporting for non-systemd and Windows hosts (reports "N/A" rather than faking)
- Read-only probes — never modifies remote state
- Self-contained orchestration script with per-device timeouts (no single hung host can block the run)

### Security
- All credentials via env vars or SSH keys — never in config files
- `.gitignore` blocks `devices.yaml`, `*.token`, `id_*`, `.env`, etc.
- Documentation explicitly warns against committing real configs

## [0.0.0] — initialised

- Project skeleton, license, README