# LAN access resilience (control-plane / provider outage)

Keep infra reachable on the local network when the mesh control plane (headscale) or its hosting provider goes down.

## TL;DR

When the mesh/provider is down and apps are unreachable:

1. [Do NOT disconnect your mesh clients](#1--do-not-disconnect-mesh-clients)
2. [Bind the reverse proxy to the LAN](#2--bind-the-reverse-proxy-to-the-lan)
3. [Add /etc/hosts entries](#step-3--reach-the-apps-from-the-laptop-macos)

When the outage is over: follow Rollback to undo steps 2 and 3.

## Problem

Topology: headscale runs on an external VPS with a public IP and hands mesh
addresses to clients. The Raspberry Pi is a mesh client, hosts the Docker apps,
and runs a reverse proxy (nginx-proxy-manager) that routes `app.example.com` to
each app.

Concrete example (June 2026): the VPS provider had a multi-day outage with no
ETA (background: https://decovar.dev/blog/2026/06/04/alexhost-downtime-mirhosting-incident-june-2026/),
so headscale was unreachable. Local access broke too, because the reverse proxy
was published only on the mesh address (`<pi-tailnet-ip>:80/443`): reaching it
required being on the mesh, the mesh required the down control plane, and the
clients had already been disconnected so they could not get a mesh address.
The Pi and its containers were healthy on the LAN the whole time — nothing could
route to them.

## During an outage

### 1 — Do NOT disconnect mesh clients

A connected mesh node keeps working peer-to-peer even while the control plane is
down. Logging a client out is what locks you out: re-authentication needs the
control plane, which is unreachable. If a client is still connected, leave it
connected. The steps below are for clients that are already off the mesh (or for
LAN access in general).

### 2 — Bind the reverse proxy to the LAN

Publish the proxy on `0.0.0.0` instead of only the mesh address, so the apps are
reachable on the LAN regardless of mesh state.

Edit `host_vars/pi/vault.yml`:

```yaml
nginx_docker_settings:
  # ...
  published_ports:
    - "0.0.0.0:80:80/tcp"
    - "0.0.0.0:81:81/tcp"
    - "0.0.0.0:443:443/tcp"
    # mesh-only bind (default; restored on rollback):
    # - "<pi-tailnet-ip>:80:80/tcp"
    # - "<pi-tailnet-ip>:443:443/tcp"
```

Apply it (from `infra/`):

```bash
ansible-playbook playbook-pi.yml --tags nginx
```

Note: `0.0.0.0` publishes on every host interface, so the host firewall should
restrict `80/443` to the local subnet (plus `100.64.0.0/10`). The Pi has no
public IP, so this is about intent, not internet exposure.

### Step 3 — Reach the apps from the laptop

Map each app name to the Pi's LAN address in `/etc/hosts` — one hostname per
line, and never lead a line with the bare apex (that aliases the subdomains to
the apex's public records and sends the browser to the CDN):

```text
<pi-lan-ip> app1.example.com
<pi-lan-ip> app2.example.com
```

Flush and verify:

```bash
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
dscacheutil -q host -a name app1.example.com   # expect only <pi-lan-ip>, no IPv6
curl -vk https://app1.example.com              # expect: Trying <pi-lan-ip>
```

## Rollback (after the outage is fixed)

1. Reverse proxy bind — restore the mesh-only publish in `host_vars/pi/vault.yml`
   (uncomment the `<pi-tailnet-ip>` lines, remove the `0.0.0.0` lines) and
   re-apply:

   ```bash
   ansible-playbook playbook-pi.yml --tags nginx
   ```

2. Laptop `/etc/hosts` — remove the `app*.example.com` lines added in step 3,
   then flush:

   ```bash
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   ```
