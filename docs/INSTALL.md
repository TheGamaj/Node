# Gamaj Node — install guide

Version covered: **`is.0.0.1`** · Control port: **62050** · Xray API port: **62051**

Gamaj Node is the distributed worker of the platform. It runs Xray, terminates
the VPN protocols, collects per-user traffic, and executes host actions on
request from the panel. It installs as a native binary with a systemd service —
there is no container install and no install-mode switch, so OpenVPN,
WireGuard, L2TP, PPTP, SSTP, Remote Access, and Extra VPN are all available on a
standard node.

<p align="center">
  <a href="https://t.me/TheGamaj">Channel</a> ·
  <a href="https://t.me/GamajGP">Support group</a> ·
  <a href="https://t.me/AsliCode">Code channel</a>
</p>

## 1. Requirements

| Item | Value |
|---|---|
| Operating system | Linux with systemd (Debian/Ubuntu, CentOS/Rocky/Alma, Fedora, Arch, Alpine) |
| Access | root |
| Ports | control port (default `62050`) reachable from the panel; Xray API stays local (`62051`) |
| Architecture | same list as the panel: `386`, `amd64`, `arm64`, `armv5`, `armv6`, `armv7`, `s390x` |
| Host packages | installed automatically when a feature needs them (openvpn, nftables, wireguard-tools, haproxy, accel-ppp bundle) |

## 2. Install

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install
```

Options:

```bash
# second node on the same host (separate service, ports, and data dir)
... | sudo bash -s -- install --name gamaj-node2

# a pinned release
... | sudo bash -s -- install --version is.0.0.1
```

Notes:

- Never run the installer as `sudo bash -c "$(curl ...)"`; the script body can
  exceed Linux's single-argument limit. Always pipe the download into bash.
- With a non-interactive stdin the installer takes every default: binary
  install, control port `62050`, Xray API `62051`.
- If the release has no asset for your architecture, the installer stops with a
  clear message instead of leaving a broken service.

## 3. Offline or custom build

```bash
git clone https://github.com/TheGamaj/Node.git Gamaj-Node
cd Gamaj-Node
sudo apt-get install -y golang-go    # Go 1.25+
go build -o dist/gamaj-node ./cmd/gamaj-node

sudo GAMAJ_NODE_BINARY_OVERRIDE="$PWD/dist/gamaj-node" \
     GAMAJ_NODE_BINARY_OVERRIDE_VERSION=is.0.0.1 \
     bash scripts/gamaj/gamaj-node.sh install
```

## 4. Paths and service

| Item | Path |
|---|---|
| Node files | `/opt/gamaj-node` |
| Node binary | `/opt/gamaj-node/bin/gamaj-node` |
| Environment file | `/opt/gamaj-node/.env` |
| Data (Xray core, certs, logs) | `/var/lib/gamaj-node` |
| Service | `gamaj-node.service` |

A second node installed with `--name gamaj-node2` uses `/opt/gamaj-node2`,
`/var/lib/gamaj-node2`, and `gamaj-node2.service`.

## 5. Configuration

`/opt/gamaj-node/.env` — every key is `GAMAJ_`-prefixed:

| Key | Meaning | Default |
|---|---|---|
| `GAMAJ_NODE_SERVICE_HOST` | Address the panel connects to | `0.0.0.0` |
| `GAMAJ_NODE_SERVICE_PORT` | Control port (gRPC, mutual TLS) | `62050` |
| `GAMAJ_NODE_XRAY_API_HOST` | Xray API bind address | `127.0.0.1` |
| `GAMAJ_NODE_XRAY_API_PORT` | Xray API port | `62051` |
| `GAMAJ_DATA_DIR` | Data directory | `/var/lib/gamaj-node` |
| `GAMAJ_NODE_SSL_CERT_FILE` / `_KEY_FILE` | Node certificate bundle | `/var/lib/gamaj-node/cert.pem`, `cert.key` |
| `GAMAJ_NODE_SSL_CLIENT_CERT_FILE` | Client certificate used for gRPC | same as the node certificate |
| `GAMAJ_XRAY_EXECUTABLE_PATH` | Xray binary | `/var/lib/gamaj-node/xray-core/xray` |
| `GAMAJ_XRAY_ASSETS_PATH` | geoip/geosite assets | `/var/lib/gamaj-node/xray-core` |
| `GAMAJ_NODE_INSTALL_MODE` | Always `binary` | `binary` |
| `GAMAJ_NODE_XRAY_LOG_DIR` | Xray log directory | Xray default |

Edit it with `sudo gamaj-node edit`, then restart the service.

## 6. Connect the node to the panel

1. In the panel open **Nodes** and add a node: name, public address, control port
   (`62050` by default).
2. The panel shows a certificate bundle. Paste it into the installer prompt (or
   into `/var/lib/gamaj-node/cert.pem`), then restart the node.
3. Verify:

```bash
sudo gamaj-node status
sudo gamaj-node logs
ss -ltn | grep 62050
```

The node then reports traffic, online sessions, protocol status, and host
metrics to the panel. Open the control port between the two servers only; never
expose `62051`.

## 7. Manage

```bash
sudo gamaj-node up             # start
sudo gamaj-node down           # stop
sudo gamaj-node restart        # restart
sudo gamaj-node status         # status
sudo gamaj-node logs           # follow logs
sudo gamaj-node core-update    # update or change the Xray core
sudo gamaj-node update         # update the node (latest or --version)
sudo gamaj-node edit           # edit the environment file
sudo gamaj-node uninstall      # remove the node
```

## 8. Runtime features

| Feature | Notes |
|---|---|
| Xray inbounds | VLESS, VMess, Trojan, Shadowsocks, with fallbacks |
| OpenVPN | installs `openvpn`, needs `/dev/net/tun` |
| WireGuard | installs `wireguard-tools` and `nftables`, one kernel interface per inbound, TPROXY to the Xray tunnel by default |
| L2TP / PPTP / SSTP | driven through accel-ppp; the bundle is downloaded from the release assets |
| Remote Access | IKEv2 and AnyConnect style sessions with per-session accounting |
| Extra VPN | telemt/MTProto and related helpers from the release assets |
| HAProxy | generated configs validated with `haproxy -c` before activation |
| Source IP blocking | nftables rules for the addresses the panel marks as blocked |

## 9. Troubleshooting

| Symptom | Check |
|---|---|
| Panel shows the node offline | Control port open, correct address/port in the panel, certificate matches the node record |
| Service restarts in a loop | `journalctl -u gamaj-node -n 100` — usually a port conflict or a certificate mismatch |
| Xray does not start | `sudo gamaj-node core-update`, then `gamaj-node logs` |
| WireGuard inbound fails | Kernel module and `nft` present; the installer adds both |
| SSTP/PPTP inbound fails | accel-ppp bundle present under `/usr/libexec/gamaj-accel` |

## 10. End-to-end check

```bash
sudo bash scripts/tests/e2e-node-install.sh
```

It builds the node binary, installs it into a sandbox prefix, starts the service,
and fails unless the node listens on its control port, stays active, and creates
its TLS material. Requires Linux, systemd, root, and Go; elsewhere it prints
`SKIP` and exits successfully.
