# artyorsh/homelab

[![Test (Ubuntu 22.04)](https://github.com/artyorsh/infra/actions/workflows/test-roles-ubuntu-lts.yml/badge.svg?event=push)](https://github.com/artyorsh/infra/actions/workflows/test-roles-ubuntu-lts.yml)

## Usage (macOS)

Install Ansible

```
brew install ansible
```

Install required packages

```
ansible-galaxy install -r requirements.yml
```

Create a Keychain item to automate Vault password input

```
security add-generic-password -a $(whoami) -s ansible-vault-password -w
```

### Run the playbook

When running the playbook on a freshly installed machine, make sure its ssh keys exist locally.

```
ssh-copy-id root@IP_ADDRESS
```

Then use --extra-vars to proceed using servers' initial settings

```
ansible-playbook playbook-pi.yml --extra-vars "ansible_ssh_port=22 ansible_user=root ansible_ssh_password=yourpassword"
```

For each host, adjust the variables. See in [./host_vars](https://github.com/artyorsh/selfhosted/blob/main/host_vars).

For secret variables, be sure to use [Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html#creating-encrypted-files).

For every subsequent run:

```
ansible-playbook playbook-pi.yml
```
