#!/bin/bash
# hearth/scripts/lib/ssh.sh — SSH helpers
# Read-only library — sourced by other scripts.

# Build SSH option string for a device
hearth_ssh_opts() {
  local connect_timeout="${1:-4}"
  local batch_mode="${2:-no}"
  echo "-o StrictHostKeyChecking=no -o ConnectTimeout=$connect_timeout -o BatchMode=$batch_mode -o LogLevel=ERROR"
}

# Run a command on a remote device via SSH, using the appropriate auth method.
# Args: device_name auth user address password_env key_path connect_timeout warmup remote_cmd
# Echoes stdout. Returns SSH exit code.
hearth_ssh_run() {
  local name="$1"
  local auth="$2"
  local user="$3"
  local addr="$4"
  local password_env="$5"
  local key_path="$6"
  local connect_timeout="$7"
  local warmup="$8"
  local remote_cmd="$9"

  local opts
  opts=$(hearth_ssh_opts "$connect_timeout" "no")

  # Optional warmup — first SSH to mobile/chroot devices often times out, ignore it
  if [ "$warmup" = "true" ]; then
    case "$auth" in
      ssh-pass)
        local pw="${!password_env:-}"
        sshpass -p "$pw" ssh $opts "$user@$addr" 'true' >/dev/null 2>&1 || true
        ;;
      ssh-key)
        ssh -i "$(eval echo "$key_path")" $opts "$user@$addr" 'true' >/dev/null 2>&1 || true
        ;;
    esac
    sleep 2
  fi

  # Real command
  case "$auth" in
    local)
      bash -c "$remote_cmd"
      ;;
    ssh-pass)
      if ! command -v sshpass >/dev/null 2>&1; then
        echo "ERROR: sshpass not installed but device $name uses auth: ssh-pass" >&2
        return 1
      fi
      local pw="${!password_env:-}"
      if [ -z "$pw" ]; then
        echo "ERROR: env var $password_env is empty for device $name" >&2
        return 1
      fi
      sshpass -p "$pw" ssh $opts "$user@$addr" "$remote_cmd"
      ;;
    ssh-key)
      ssh -i "$(eval echo "$key_path")" $opts -o BatchMode=yes "$user@$addr" "$remote_cmd"
      ;;
    http-only)
      # No SSH — caller should not have called this
      echo "ERROR: device $name is http-only, cannot run SSH commands" >&2
      return 1
      ;;
    *)
      echo "ERROR: unknown auth type '$auth' for device $name" >&2
      return 1
      ;;
  esac
}

# Test if a device responds to ping.
# Falls back cleanly if the platform ping lacks -W (BSD/macOS uses -W in ms,
# some minimal images lack ping entirely — in which case we report reachable=unknown
# by returning success so later layers still run and carry the real signal).
# Args: address [count] [timeout_seconds]
hearth_ping() {
  local addr="$1"
  local count="${2:-1}"
  local timeout="${3:-2}"

  if ! command -v ping >/dev/null 2>&1; then
    # No ping available; let SSH/HTTP layers be the reachability signal.
    return 0
  fi

  # GNU/Linux: -c count -W timeout(sec). BSD/macOS: -c count -t timeout(sec).
  if ping -c "$count" -W "$timeout" "$addr" >/dev/null 2>&1; then
    return 0
  fi
  # Retry with BSD-style flag before declaring unreachable.
  if ping -c "$count" -t "$timeout" "$addr" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}
