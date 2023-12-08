# artyorsh/homelab

*Work in progress*

Ansible playbooks to run a media/vpn server on Ubuntu-based machines.

It is initially inspired by [notthebee's easy-vpn setup](https://github.com/notthebee/ansible-easy-vpn).

Assumes a fresh Ubuntu Server 23.10 install with access to a user with sudo privileges and a public SSH key.

## Playbooks

- The [playbook-vpnhost](./playbook-medialab.yml) runs a wireguard server, configurable with [wg-easy](https://github.com/wg-easy/wg-easy).

- The [playbook-medialab](./playbook-medialab.yml) contains popular apps from the [linuxserver repository](https://fleet.linuxserver.io)

## Security

- [Authelia](https://hub.docker.com/r/authelia/authelia) (An authentication provider)
- [BunkerWeb](https://github.com/bunkerity/bunkerweb) (A NGINX-based web server focused on security)
- [Security role by @geerlingguy](https://github.com/geerlingguy/ansible-role-security)

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
ansible-playbook playbook-medialab.yml --extra-vars "ansible_ssh_port=22 ansible_user=root ansible_ssh_password=yourpassword"
```

For each host, adjust the variables. See in [./host_vars](https://github.com/artyorsh/selfhosted/blob/main/host_vars).

For secret variables, be sure to use [Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html#creating-encrypted-files).

For every subsequent run:
```
ansible-playbook playbook-medialab.yml
```