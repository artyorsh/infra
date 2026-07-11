#!/bin/bash
# Route HomeKit replies via LAN interface only (connmark).
# Does not mark wg0 traffic — VPN/LAN browsing stays unchanged.
#
# Usage: sudo homekit-iptables.sh apply|revert|status

set -euo pipefail

: "${LAN_IF:?}"
: "${LAN_IP:?}"
: "${LAN_SUBNET:?}"
: "${HOMEKIT_PORT:?}"

FMARK_LAN="${FMARK_LAN:-0x2}"
TABLE_LAN="${TABLE_LAN:-100}"
PRIO_LAN="${PRIO_LAN:-5175}"
MANGLE_CHAIN="${MANGLE_CHAIN:-SPLITRT}"
WAIT_SECONDS="${WAIT_SECONDS:-120}"

wait_for_lan_ip() {
  local elapsed=0
  while ! ip -4 addr show dev "${LAN_IF}" 2>/dev/null | grep -q "inet ${LAN_IP}/"; do
    if (( elapsed >= WAIT_SECONDS )); then
      echo "Timed out waiting for ${LAN_IP} on ${LAN_IF}" >&2
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
}

apply_iptables() {
  local action="$1"
  shift
  if iptables -t mangle -C "${MANGLE_CHAIN}" "$@" 2>/dev/null; then
    [[ "${action}" == "-A" ]] && return 0
  else
    [[ "${action}" == "-D" ]] && return 0
  fi
  iptables -t mangle "${action}" "${MANGLE_CHAIN}" "$@"
}

ensure_chain() {
  if ! iptables -t mangle -L "${MANGLE_CHAIN}" -n >/dev/null 2>&1; then
    iptables -t mangle -N "${MANGLE_CHAIN}"
  fi
  if ! iptables -t mangle -C PREROUTING -j "${MANGLE_CHAIN}" 2>/dev/null; then
    iptables -t mangle -A PREROUTING -j "${MANGLE_CHAIN}"
  fi
  if ! iptables -t mangle -C FORWARD -j "${MANGLE_CHAIN}" 2>/dev/null; then
    iptables -t mangle -A FORWARD -j "${MANGLE_CHAIN}"
  fi
}

remove_jump_rules() {
  iptables -t mangle -D PREROUTING -j "${MANGLE_CHAIN}" 2>/dev/null || true
  iptables -t mangle -D FORWARD -j "${MANGLE_CHAIN}" 2>/dev/null || true
}

flush_chain() {
  if iptables -t mangle -L "${MANGLE_CHAIN}" -n >/dev/null 2>&1; then
    iptables -t mangle -F "${MANGLE_CHAIN}"
    iptables -t mangle -X "${MANGLE_CHAIN}" 2>/dev/null || true
  fi
}

apply() {
  revert 2>/dev/null || true

  wait_for_lan_ip

  ip route replace table "${TABLE_LAN}" "${LAN_SUBNET}" dev "${LAN_IF}" src "${LAN_IP}"
  ip rule add fwmark "${FMARK_LAN}" lookup "${TABLE_LAN}" priority "${PRIO_LAN}" 2>/dev/null || true

  ensure_chain

  apply_iptables -A -m conntrack --ctstate NEW -i "${LAN_IF}" -d "${LAN_IP}" -p tcp -m tcp --dport "${HOMEKIT_PORT}" \
    -j CONNMARK --set-xmark "${FMARK_LAN}/0xffffffff"
  apply_iptables -A -j CONNMARK --restore-mark --nfmask 0xffffffff --ctmask 0xffffffff

  echo "Applied HomeKit iptables routing (connmark)."
}

revert() {
  ip rule del fwmark "${FMARK_LAN}" lookup "${TABLE_LAN}" priority "${PRIO_LAN}" 2>/dev/null || true
  ip route flush table "${TABLE_LAN}" 2>/dev/null || true

  remove_jump_rules
  flush_chain

  echo "Reverted HomeKit iptables routing (connmark)."
}

status() {
  echo "=== ip rules ==="
  ip rule list | grep -E "${PRIO_LAN}|table ${TABLE_LAN}" || echo "(none)"
  echo "=== table ${TABLE_LAN} ==="
  ip route show table "${TABLE_LAN}" || true
  echo "=== mangle ${MANGLE_CHAIN} ==="
  iptables -t mangle -L "${MANGLE_CHAIN}" -n -v 2>/dev/null || echo "(chain absent)"
}

case "${1:-}" in
  apply) apply ;;
  revert) revert ;;
  status) status ;;
  *)
    echo "Usage: $0 apply|revert|status" >&2
    exit 1
    ;;
esac
