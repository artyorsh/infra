# Jobs

This document describes the automated tasks performed on the hosts.

## PI

- **Export Docker Volumes**

  - Time: Daily at 02:15AM
  - Managed by: [artyorsh.selfhosted.docker](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/docker). See `docker_autobackup_schedule`.

- **Backup Docker Volumes (Local)**

  - Time: Mo-Sat at 02:30AM
  - Managed by: [artyorsh.selfhosted.duplicati](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/duplicati)

- **Backup Documents (Local)**

  - Time: Mo-Sat at 02:30AM
  - Managed by: [artyorsh.selfhosted.duplicati](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/duplicati)

- **Prune Docker System**

  - Time: Daily at 02:45AM.
  - Managed by: [artyorsh.selfhosted.docker](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/docker). See `docker_autoprune_schedule` and `docker_autoprune_until_hours`.

- **Backup Docker Volumes (Cloud)**

  - Time: Sundays at 02:30AM
  - Managed by: [artyorsh.selfhosted.duplicati](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/duplicati)

- **Backup Photos (Cloud)**

  - Time: Sundays at 02:30AM
  - Managed by: [artyorsh.selfhosted.duplicati](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/duplicati)

- **Backup Documents (Cloud)**

  - Time: Sundays at 02:30AM
  - Managed by: [artyorsh.selfhosted.duplicati](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/duplicati)

- **Update Docker Images**

  - Time: Sundays at 03:00AM
  - Managed by: [artyorsh.selfhosted.watchtower](https://github.com/artyorsh/ansible-collection-selfhosted/tree/master/roles/watchtower). See `watchtower_env.WATCHTOWER_SCHEDULE`.
