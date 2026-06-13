# AGENTS.md — `infra`

Homelab playbooks, inventory, host vars, and local roles.

## Before editing

- Read `README.md` and any `host_vars` you touch.
- New roles/collections used by playbooks belong in `requirements.yml`.

## Validation

```bash
ansible-playbook playbook-pi.yml --syntax-check
ansible-playbook playbook-mac.yml --syntax-check
```

For partial runs: `ansible-playbook playbook-pi.yml --check --tags <tag>`.

## Secrets

- Do not add or edit secret values in automation; the owner adds them under `host_vars/*/vault.yml`.
- Password-interactive commands: give the user a template to run locally.
