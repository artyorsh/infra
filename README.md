# artyorsh/selfhosted

An Ansible playbook that sets up an Ubuntu-based server with reasonable security and auto-updates.

This playbook is heavily inspired by [notthebee's easy-vpn setup](https://github.com/notthebee/ansible-easy-vpn) (and more likely goes into the direction of [his infra](https://github.com/notthebee/infra)).

It assumes a fresh Ubuntu Server 20.04 install with access to a user with sudo privileges and a public SSH key.

## Security

- [Authelia](https://hub.docker.com/r/authelia/authelia) (An authentication provider)
- [BunkerWeb](https://github.com/bunkerity/bunkerweb) (A NGINX-based web server focused on security)
- [fail2ban](https://github.com/fail2ban/fail2ban) (A Daemon to ban hosts that cause multiple authentication errors)
- Wireguard with WebUI via [wg-easy](https://github.com/WeeJeWel/wg-easy) (A VPN Server)
- [UFW](https://help.ubuntu.com/community/UFW) (A firewall)

## Apps

- [Gitea](https://github.com/go-gitea/gitea) (Git service) 
- [FreshRSS](https://github.com/FreshRSS/FreshRSS) and [RSSBridge](https://github.com/RSS-Bridge/rss-bridge) (An RSS reader + feed generator)
- [FireflyIII](https://github.com/firefly-iii/firefly-iii) (Personal finance manager)

## Roadmap

A few apps which I already run on another (not controlled by Ansible) machine will be added.

Apart from that, I am completely unsure about what will happen here, as I am new to Ansible and simply find it fun to play with. Use it on own risk :]

## Usage (macOS)

Install Ansible
```
brew install ansible
```

Clone the repo and install dependencies
```
git clone https://github.com/artyorsh/selfhosted
```

```
cd selfhosted && ansible-galaxy install -r requirements.yml
```

Create a Keychain item to automate Vault password input
```
security add-generic-password -a $(whoami) -s ansible-vault-password -w
```

Adjust the variables (see [./group_vars/all/vars.yml](https://github.com/artyorsh/selfhosted/blob/main/group_vars/all/vars.yml)).
For secret variables, be sure to use [Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html#creating-encrypted-files).

Run the playbook
```
ansible-playbook main.yml -K
# -K flag is only needed when running the playbook for first time
```

## Debugging

Before deploying changes to a real machine, it's always a good idea to check how it runs locally. This is where [Vagrant](https://www.vagrantup.com) is for the rescue.

Run the virtual machine
```
vagrant up
```

Run the playbook against vagrant host
```
ansible-playbook main.yml -l vagrant
```
