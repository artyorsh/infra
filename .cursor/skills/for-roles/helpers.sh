#!/usr/bin/env bash

_for_roles_script_dir() {
  local src
  if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    src="${BASH_SOURCE[0]}"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    src="${(%):-%x}"
  else
    src="$0"
  fi
  cd "$(dirname "$src")" && pwd
}

_FOR_ROLES_DIR="$(_for_roles_script_dir)"

_for_roles_cd_safe() {
  # fj picks up cwd git context; meta-workspace root has an unborn main branch.
  cd "$_FOR_ROLES_DIR"
}

for_roles_resolve_fj() {
  _for_roles_cd_safe
  local line
  line=$(fj auth list | head -1)
  [[ -z "$line" ]] && line=$(fj --style minimal whoami | sed -n 's/.*signed in to //p')
  [[ -z "$line" && -n "${FOR_ROLES_FJ_HOST:-}" ]] \
    && line=$(fj -H "$FOR_ROLES_FJ_HOST" --style minimal whoami | sed -n 's/.*signed in to //p')
  USER="${line%%@*}"
  HOST="${line##*@}"
  [[ -z "$USER" || -z "$HOST" ]] && { echo "fj not logged in" >&2; return 1; }
  export USER HOST
}

for_roles_list() {
  local host=$1 user=$2 page=1
  [[ -n "$host" && -n "$user" ]] || { echo "usage: for_roles_list <host> <user>" >&2; return 1; }

  _for_roles_cd_safe
  while true; do
    local lines=() line full
    while IFS= read -r line; do
      [[ -n "$line" ]] && lines+=("$line")
    done < <(
      fj -H "$host" --style minimal user repos "$user" --sort name --page "$page" \
        | sed -n 's/^- //p'
    )
    [[ ${#lines[@]} -eq 0 ]] && break
    for full in "${lines[@]}"; do
      [[ "$full" == */ansible-role-* ]] || continue
      echo "${full##*/ansible-role-}"
    done
    page=$((page + 1))
  done | sort -u
}

for_roles_run() {
  local host=$1 user=$2 per_role_cmd=$3
  [[ -n "$host" && -n "$user" && -n "$per_role_cmd" ]] \
    || { echo "usage: for_roles_run <host> <user> <per-role-command>" >&2; return 1; }

  _for_roles_cd_safe
  set -euo pipefail
  local role repo cmd
  while IFS= read -r role; do
    repo="${user}/ansible-role-${role}"
    cmd="${per_role_cmd//\$\{role\}/$role}"
    cmd="${cmd//\$\{repo\}/$repo}"
    cmd="${cmd//\$role/$role}"
    cmd="${cmd//\$repo/$repo}"
    cmd="${cmd//\$HOST/$host}"
    cmd="${cmd//\$USER/$user}"
    echo "==> ${role}"
    bash -c "$cmd"
  done < <(for_roles_list "$host" "$user")
}
