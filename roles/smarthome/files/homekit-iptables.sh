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
# Must run before WireGuard's "lookup main suppress_prefixlength 0" rule,
# otherwise LAN /24 in main via wg0 wins and table 100 is never consulted.
PRIO_LAN="${PRIO_LAN:-5169}"
PRIO_LAN_PREVIOUS="${PRIO_LAN_PREVIOUS:-5172}"
PRIO_LAN_LEGACY="${PRIO_LAN_LEGACY:-5175}"
MANGLE_CHAIN="${MANGLE_CHAIN:-SPLITRT}"
FILTER_CHAIN="${FILTER_CHAIN:-FILTERS}"
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

apply_filter() {
  local action="$1"
  shift
  if iptables -C "${FILTER_CHAIN}" "$@" 2>/dev/null; then
    [[ "${action}" == "-A" ]] && return 0
  else
    [[ "${action}" == "-D" ]] && return 0
  fi
  iptables "${action}" "${FILTER_CHAIN}" "$@"
}

ensure_homekit_input() {
  if ! iptables -L "${FILTER_CHAIN}" -n >/dev/null 2>&1; then
    echo "Filter chain ${FILTER_CHAIN} absent; skipping HAP INPUT rule" >&2
    return 0
  fi

  if iptables -C "${FILTER_CHAIN}" -m state --state NEW -p tcp -m tcp --dport "${HOMEKIT_PORT}" -j ACCEPT 2>/dev/null; then
    return 0
  fi

  reject_line="$(iptables -L "${FILTER_CHAIN}" --line-numbers -n | awk '/reject-with icmp-host-prohibited/{print $1; exit}')"
  if [[ -n "${reject_line}" ]]; then
    iptables -I "${FILTER_CHAIN}" "${reject_line}" -m state --state NEW -p tcp -m tcp --dport "${HOMEKIT_PORT}" -j ACCEPT
  else
    iptables -A "${FILTER_CHAIN}" -m state --state NEW -p tcp -m tcp --dport "${HOMEKIT_PORT}" -j ACCEPT
  fi
}

remove_homekit_input() {
  if ! iptables -L "${FILTER_CHAIN}" -n >/dev/null 2>&1; then
    return 0
  fi

  apply_filter -D -m state --state NEW -p tcp -m tcp --dport "${HOMEKIT_PORT}" -j ACCEPT
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

  ensure_homekit_input

  echo "Applied HomeKit iptables routing (connmark + INPUT)."
}

revert() {
  ip rule del fwmark "${FMARK_LAN}" lookup "${TABLE_LAN}" priority "${PRIO_LAN}" 2>/dev/null || true
  ip rule del fwmark "${FMARK_LAN}" lookup "${TABLE_LAN}" priority "${PRIO_LAN_PREVIOUS}" 2>/dev/null || true
  ip rule del fwmark "${FMARK_LAN}" lookup "${TABLE_LAN}" priority "${PRIO_LAN_LEGACY}" 2>/dev/null || true
  ip route flush table "${TABLE_LAN}" 2>/dev/null || true

  remove_jump_rules
  flush_chain
  remove_homekit_input

  echo "Reverted HomeKit iptables routing (connmark + INPUT)."
}

status() {
  echo "=== ip rules ==="
  ip rule list | grep -E "${PRIO_LAN}|${PRIO_LAN_PREVIOUS}|${PRIO_LAN_LEGACY}|table ${TABLE_LAN}|fwmark ${FMARK_LAN}" || echo "(none)"
  echo "=== table ${TABLE_LAN} ==="
  ip route show table "${TABLE_LAN}" || true
  echo "=== mark ${FMARK_LAN} sample route ==="
  ip route get "${LAN_SUBNET%/*}" mark "${FMARK_LAN}" 2>/dev/null || ip route get 10.24.2.1 mark "${FMARK_LAN}" 2>/dev/null || true
  echo "=== mangle ${MANGLE_CHAIN} ==="
  iptables -t mangle -L "${MANGLE_CHAIN}" -n -v 2>/dev/null || echo "(chain absent)"
  echo "=== filter ${FILTER_CHAIN} (HAP) ==="
  iptables -L "${FILTER_CHAIN}" -n -v 2>/dev/null | grep -E "dpt:${HOMEKIT_PORT}|^Chain" || echo "(no HAP rule)"
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
