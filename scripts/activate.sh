#!/usr/bin/env bash
# Sole activation entrypoint for Hermes remote profile API ports.
# OWNER: Hermes Grok Bot serverId 4425834
# Requires: HERMES_REMOTE (e.g. admin@<magicdns>) — never commit real hosts/IPs.
set -euo pipefail

if [[ -z "${HERMES_REMOTE:-}" ]]; then
  echo "Set HERMES_REMOTE to admin@<tailscale-magicdns-or-host> before running." >&2
  exit 1
fi

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new)
REMOTE_ENV='export PATH="$HOME/.local/bin:$PATH"'

PROFILES=(amp analyst archivist atelier curate dealcrusher deckhand dsh forge helm hirekit kinetic ledger moodboard mule playmaker polish radar scribe shotcaller strike taste vaultkeeper warroom wireframe)

usage() {
  cat <<USAGE
Usage: $(basename "$0") <status|activate|list|probe|deactivate> [profile]
Env: HERMES_REMOTE=admin@<host> (required)
USAGE
}

ssh_remote() {
  ssh "${SSH_OPTS[@]}" "$HERMES_REMOTE" "$REMOTE_ENV; $*"
}

cmd_status() { ssh_remote 'hermes gateway status; echo; hermes gateway list'; }
cmd_list() { ssh_remote 'hermes gateway list'; }

cmd_activate() {
  local out
  out=$(ssh_remote 'hermes gateway status 2>&1') || true
  if echo "$out" | grep -qiE 'supervised by launchd|Gateway is supervised'; then
    echo "OK: multiplexed gateway already running (localhost:8642)."
    return 0
  fi
  echo "Starting gateway…"
  ssh_remote 'hermes gateway start'
  ssh_remote 'hermes gateway status; hermes gateway list'
}

cmd_deactivate() {
  echo "Safe pause only (no wipe)."
  ssh_remote 'hermes pause' || true
}

cmd_probe() {
  local target="${1:-}" list
  if [[ -n "$target" ]]; then list=("$target"); else list=("${PROFILES[@]}"); fi
  local joined="${list[*]}"
  ssh_remote "for p in $joined; do code=\$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 \"http://localhost:8642/p/\$p/v1/models\" || echo FAIL); echo \"\$p \$code\"; done"
}

main() {
  local op="${1:-}"; shift || true
  case "$op" in
    status) cmd_status ;;
    activate) cmd_activate ;;
    list) cmd_list ;;
    probe) cmd_probe "${1:-}" ;;
    deactivate) cmd_deactivate ;;
    -h|--help|help|"") usage; exit 1 ;;
    *) echo "Unknown: $op"; usage; exit 2 ;;
  esac
}
main "$@"
