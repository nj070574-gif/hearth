# Changelog

All notable changes to hearth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-10-02

### Added
- **Parallel sweep.** Devices are now probed concurrently (bounded pool, default 8) with output still printed in config order — the full-estate sweep is dramatically faster on larger labs. `--sequential` restores one-at-a-time behaviour; `--parallel <n>` sets the concurrency cap.
- **Health status, summary and exit codes.** Every device resolves to `[OK]` / `[DEGRADED]` / `[DOWN]`. The sweep ends with an `N/M healthy, X degraded, Y down` summary, and the process exits `0`/`1`/`2` accordingly — so `sweep.sh` can be used directly as a cron/CI health gate.
- **`--json` output.** Machine-readable JSON (one object per device with per-layer values, `status`, and a `warnings` list, plus a `summary` block and `exit_code`) for agents and scripts.
- **Health thresholds.** Configurable `disk_warn_pct` (90), `mem_warn_pct` (90), `load_warn_per_cpu` (2) and `temp_warn_c` (75) flag a device DEGRADED and are marked inline with `⚠`. Thresholds apply only to layers actually measured — http-only/chroot hosts are never falsely flagged.
- **`--problems-only`** to show only DOWN/DEGRADED devices; **`--watch <seconds>`** for a repeating live view.
- **TTY-aware colour** (honours `NO_COLOR` and `HEARTH_COLOR=never|always|auto`), with `--no-color`.
- **Raspberry Pi / thermal-zone CPU temperature** surfaced at L3.
- Implemented the previously documented-only `expected_failed_units` (units allowed to be inactive without flagging) and `expect_no_match` (command probe fails if stdout matches).

### Fixed
- **Default config path crashed under `set -u`.** `hearth_find_config` referenced `$HEARTH_CONFIG` unguarded, so the common case (no `HEARTH_CONFIG` set, using `~/.hearth/devices.yaml`) aborted with an "unbound variable" error before finding the config. Now guarded.
- HTTP probes now use a per-call `mktemp` file instead of a fixed `/tmp/.hearth_probe` (removes a symlink/race hazard and makes probes safe under parallelism).
- Added a real `timeout`/`gtimeout`/perl fallback so a hung host can't block the run on macOS and minimal images (the "bundled fallback" the docs already promised).
- Hardened `ping` for BSD/macOS flag differences and missing-`ping` environments.
- Removed shell→Python string interpolation in the YAML helpers (values now passed via environment), fixing quoting fragility and normalising YAML booleans.
- `--group` now has a dedicated config helper; failed HTTP probes no longer print a doubled `HTTP 000000`.

### Notes
- Backward-compatible: existing `devices.yaml` files work unchanged; all new keys are optional with sensible defaults.

## [0.1.1] — 2026-05-03

### Changed
- Replaced `<your-username>` placeholder in `git clone` URLs with the canonical `nj070574-gif/hearth` repo URL — the placeholder triggered `install_untrusted_source` on registry security scanners
- Softened `"Arbitrary shell command"` documentation wording in `docs/PROBES.md` and `docs/CONFIG.md` to clarify that `command` probes are user-defined and read-only

### Added
- README section explaining the `SUSPICIOUS` moderation badge that appears on some registries — a transparent breakdown of what scanners see vs. what hearth actually does, plus a clear list of what hearth does NOT do

### Fixed
- shellcheck findings (SC1087, SC2119, SC2034) from initial release

## [0.1.2] — 2026-05-03

### Changed
- Replaced `http://127.0.0.1/` with `http://localhost/` in the example `devices.example.yaml` and `README.md` — the bare-IP form was triggering `install_untrusted_source` on registry security scanners

## [0.1.3] — 2026-05-03

### Changed
- Replaced ALL raw-IP URLs in examples and archetypes with `.lan` hostnames (e.g. `http://fileserver.lan/`, `https://homeassistant.lan:8123/api/`). The scanner's `install_untrusted_source` rule was flagging each raw-IP URL one at a time

## [0.1.4] — 2026-05-03

### Changed
- Reduced `examples/devices.example.yaml` to a schema-only example covering the four auth modes (local, ssh-pass, ssh-key, http-only). App-probe (`apps:`) examples now live exclusively in the per-archetype guides under `examples/archetypes/` — registry scanners were repeatedly flagging in-YAML example URLs as `install_untrusted_source`, even hostname-based ones, so the cleanest fix was to keep all URL examples out of the YAML
- Updated README config snippet to match the new schema-only shape and explicitly point to `examples/archetypes/` for full worked examples

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