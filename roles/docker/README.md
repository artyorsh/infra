# selfhosted.docker

Installs Docker and optionally configures automatic backups and system pruning.

## Role Variables

More variables are inherited from [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker) role.

- `docker_dir`
  - Default: `/opt/docker`
  - Description: The directory where Docker apps will be installed.
  - Type: str
  - Required: no
- `docker_autobackup_enabled`
  - Default: `false`
  - Description: When set to `true`, the [docker-backup.sh](./templates/docker-backup.sh.j2) script will be created and added to the root cron.
  Additionaly, the [docker-restore.sh](./templates/docker-restore.sh.j2) script will be created. See [Automatic Backups](#automatic-backups).
  - Type: bool
  - Required: no
- `docker_autobackup_dest_dir`
  - Default: `{{ docker_dir }}/.backups`
  - Description: The directory where the backups will be stored.
  - Type: str
  - Required: no
- `docker_autobackup_containers`
  - Default: `[]`
  - Description: A list of containers to backup. Each container should have a `name` and a list of `volumes`.
  - Type: list
  - Required: no
- `docker_autobackup_schedule`
  - Default: See [docker_autobackup_schedule](./defaults/main.yml)
  - Description: The schedule for the backup cron (in Ansible cron format).
  - Type: dict
  - Required: no
- `docker_autoprune_enabled`
  - Default: `false`
  - Description: When set to `true`, the [docker-prune.sh](./templates/docker-prune.sh.j2) script will be added to the root cron to remove unused Docker resources.
  See [docs](https://docs.docker.com/reference/cli/docker/system/prune) for more information.
  See [Automatic Pruning](#automatic-pruning).
  - Type: bool
  - Required: no
- `docker_autoprune_schedule`
  - Default: See [docker_autoprune_schedule](./defaults/main.yml)
  - Description: The schedule for the prune cron (in Ansible cron format).
  - Type: dict
  - Required: no
- `docker_autoprune_until_hours`
  - Default: `720`
  - Description: only remove containers, images, and networks created before given number of hours.
  - Type: int
  - Required: no

## Dependencies

- [geerlingguy.docker](https://github.com/geerlingguy/ansible-role-docker)

## Example Playbook

```yaml
- hosts: localhost

  roles:
    - docker
``` 

## Automatic Backups

The configuration will backup all volumes of all containers listed in `docker_autobackup_containers` to the directory specified in `docker_autobackup_dest_dir`.

```yaml
- hosts: localhost

  vars:
    docker_autobackup_enabled: true
    docker_autobackup_dest_dir: "/opt/docker/backups/docker-volumes"
    docker_autobackup_schedule:
      weekday: "*"
      hour: 1
      minute: 30

    docker_autobackup_containers:
      - { name: "forgejo", volumes: ["/etc/gitea", "/var/lib/gitea"] }
      - { name: "paperlessngx", volumes: ["/usr/src/paperless/data", "/usr/src/paperless/media"] }
      - { name: "vaultwarden", volumes: ["/data"] }

  roles:
    - docker
```

## Automatic Pruning

The configuration will remove unused Docker resources (containers, images, and networks) created before the number of hours specified in `docker_autoprune_until_hours`.

```yaml
- hosts: localhost

  vars:
    docker_autoprune_enabled: true
    docker_autoprune_schedule:
      weekday: "*"
      hour: 1
      minute: 45
    docker_autoprune_until_hours: 72

  roles:
    - docker
```

