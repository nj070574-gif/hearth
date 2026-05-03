---
name: hearth
description: Run a fast, configurable health-check sweep across every device in a homelab. Use this when the user asks about server status, host health, lab status, or asks "are my servers up", "check all servers", "how is the lab", "health check", "what's running", "device health", "is X up". Supports Linux, macOS, Raspberry Pi, Android (Termux/chroot), and Windows hosts (HTTP-only). Returns a 5-layer per-device snapshot (ping, uptime+load, memory+disk, services, app health) in seconds. Read-only — never modifies remote state.
---

## What hearth does

hearth runs a per-device health probe in five layers across a user-defined list of homelab hosts. It is **configuration-driven** — the skill itself contains zero knowledge of any specific lab. The user describes their devices in `~/.hearth/devices.yaml` (or wherever `HEARTH_CONFIG` points), and hearth reads that config to drive its probes.

## Triggering

Invoke hearth when the user asks anything in this family:

- "server status", "lab status", "homelab status"
- "check all servers", "check the lab", "check my hosts"
- "is X up?" (where X is a device name from their config)
- "how is the lab?", "how is X?"
- "health check", "health sweep", "device health"
- "what's running?", "what's down?"

If the user names a single device, run `hearth check-device <name>` (or scope the sweep to one device with `--device <name>`).

## Operation

hearth is implemented as a thin wrapper around two scripts that ship with the project:

- `scripts/sweep.sh` — runs the full estate sweep, or a subset
- `scripts/check-device.sh` — runs the 5-layer probe on one device

Run from the user's hearth installation directory (typically `~/hearth/`):

```bash
./scripts/sweep.sh                    # full sweep
./scripts/sweep.sh --device <name>    # one device
./scripts/sweep.sh --group <name>     # named group of devices
./scripts/sweep.sh --dry-run          # validate config, no probes
```

Show the user the raw output. The output is already designed to be human-readable; do not re-summarise unless the user explicitly asks for analysis.

## Output format

Each device's status is printed in this exact format:

```
=== <ip-or-hostname> <name> [(<role>)] ===
  L1 ping:    OK | UNREACHABLE
  L2 uptime:  <duration>, load: <1m> <5m> <15m>
  L3 mem:     used <X> / <Y>, <Z> avail | disk: / <pct>% used, <free> free
  L4 svc:     <service1>=active <service2>=active ...
  L5 app:     <app1>=<status> | <app2>=<status> ...
```

Special cases:

- **`UNREACHABLE` at L1** — device fails ping. L2-L5 are skipped, sweep continues.
- **`SSH FAILED` at L2-L4** — device pings but SSH is unresponsive. L5 may still be attempted for HTTP probes.
- **`unmanaged-host (no SSH)` at L2-L4** — device is configured `auth: http-only` (e.g. Windows host without SSH). L5 carries the health signal.
- **`no-systemd (chroot — N/A)` at L4** — device is a chroot or has no systemd. L2/L3 still apply, L5 carries app-health.

## Triggers requiring extra care

- **"restart X" / "kill X" / "deploy X"** — hearth is read-only. If the user asks for write actions, do NOT use hearth — explain that hearth doesn't modify remote state and ask if they want to do that another way.
- **"add a new device"** — direct the user to edit `~/.hearth/devices.yaml`. Reference `examples/devices.example.yaml` and `docs/CONFIG.md` in the project for schema.
- **"why is X down?"** — first run `./scripts/sweep.sh --device <X>` to confirm the failure mode, then suggest investigation paths based on which layer failed (L1 = network, L4 = services, L5 = app).

## What hearth never does

- **Never modify remote hosts.** No `systemctl restart`, no `apt-get install`, no file writes beyond `/tmp/.hearth_*` ephemera.
- **Never reveal credentials.** Passwords and tokens live in env vars and SSH keys; hearth does not echo them.
- **Never make claims it can't verify.** If L4 can't be probed (chroot, Windows), hearth says so explicitly rather than reporting a fake green.
- **Never fabricate device data.** Every line of output comes from a real probe of a real device. If a probe times out, the output says so.

## Adding hearth to a new lab

If the user has not yet set up hearth:

1. Direct them to clone the repo and copy `examples/devices.example.yaml` to `~/.hearth/devices.yaml`
2. They edit the YAML with their real devices
3. They set credential env vars (`HEARTH_PASS_<DEVICE>`, etc.)
4. They run `./scripts/sweep.sh --dry-run` to validate
5. They run `./scripts/sweep.sh` for the first sweep

See `docs/INSTALL.md` for platform-specific install steps.

## Adding a new device archetype

If the user has a device type not covered by the 6 ship-included archetypes (linux-systemd, linux-nosystemd-chroot, raspberry-pi, windows-http-only, slurm-cluster, magento-server), help them craft a new entry by:

1. Reading `examples/archetypes/` for the closest existing match
2. Probing the device manually with `ssh user@host 'uname -srm; uptime; systemctl list-units --type=service --state=running --no-pager | head -20'` to discover its services
3. Adding a new device entry to their `devices.yaml`
4. Running `./scripts/sweep.sh --device <new-name>` to test

Encourage them to contribute the new archetype back upstream if it's broadly useful.

## Failure modes and what to tell the user

| Symptom | Likely cause | Suggested action |
|---------|-------------|------------------|
| L1 UNREACHABLE on a normally-reachable device | Network drop, host powered off | Check physical/UPS, check switch, ping the gateway |
| SSH FAILED but L1 OK | SSH daemon down, firewall, fail2ban ban | SSH manually from another host to confirm |
| L4 service shows `inactive` for a service the user expects active | Service crashed, unit name wrong | `journalctl -u <unit>` on the device |
| L5 HTTP probe shows `HTTP 000` | App is down or port closed | `curl -v <url>` from the bridgehead |
| L5 HTTP probe shows `HTTP 502/503` | App is up but failing | Check app's own logs |
| Sweep takes >30s for 10 devices | One device is timing out | Re-run with `--device <name>` to isolate |

## Privacy

hearth is designed to be safe to run in a public/agentic context:

- Reads only the user's own config file (no broader filesystem snooping)
- Writes only to `/tmp/.hearth_*` (cleaned up immediately)
- Does NOT log device IPs, hostnames, or output to any remote service
- Does NOT include telemetry of any kind

If asked about specific configuration values (passwords, tokens), hearth does NOT have access to those — they're in the user's env vars, only readable by the running process when invoking SSH/curl.

## Version

0.1.3 — moderation-friendly clarity pass. OpenClaw skill mode.