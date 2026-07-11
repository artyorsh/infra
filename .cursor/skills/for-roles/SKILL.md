---
name: for-roles
description: >-
  Loop over all ansible-role-* Forgejo repos and run a per-role instruction.
  Use when the user says /for-roles or asks to run something across all role repos.
---

# For Roles

Pure function: forRoles(instruction).

Source helpers once at the start of shell work (bash). Helpers `cd` into this skill directory before any `fj` call — do not skip that by running `fj` yourself from the meta-workspace root (unborn `main` there breaks `fj`).

```bash
cd infra/.cursor/skills/for-roles
source ./helpers.sh
```

All `fj` commands must pass `-H "$HOST"`. `for_roles_resolve_fj` sets `HOST`/`USER`; use them in `PER_ROLE_CMD` too (`fj -H $HOST repo view $repo`, etc.).

## Example

/for-roles check whether the README mentions the role name

See Step 2 for how that becomes PER_ROLE_CMD.

## Step 0 — Resolve first fj auth list entry

```bash
for_roles_resolve_fj
```

## Step 1 — List roles

```bash
for_roles_list "$HOST" "$USER"
```

Abort if empty. Keep the list for confirmation and the loop.

## Step 2 — Prepare per-role command

Translate the user's instruction into one shell command template before anything runs:

```bash
PER_ROLE_CMD='<per-role-shell-command>'
```

Use $role, $repo, $HOST, $USER where needed. This same string is classified, confirmed against, and passed to for_roles_run — prepare it once here. Prefer $role over ${role}; do not nest $repo inside ${...}.

Forgejo SSH clone: `ssh://git@$HOST:2222/$repo.git` (port 2222). For `fj` in `PER_ROLE_CMD`, always `-H $HOST`.

## Step 3 — Classify PER_ROLE_CMD

Read the prepared command, not the original natural-language request.

Updating if PER_ROLE_CMD would push, delete, commit, remove files, tag, or force-write. Read-only (view, grep, echo, syntax-check, test) skips Step 4.

## Step 4 — Confirm once (updating only)

One AskQuestion for the whole batch — never per role.

Prompt: Confirm updating N repositories: vaultwarden, dnsmasq, … (comma-separated names from Step 1)

Options: y to proceed, N to abort. Continue to Step 5 only on y.

## Step 5 — Loop

```bash
for_roles_run "$HOST" "$USER" "$PER_ROLE_CMD"
```
