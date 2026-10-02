<h1>GAMAJ</h1>

### Node

<p align="center">
  <a href="./README.md">English</a> /
  <a href="./docs/README-fa.md">فارسی</a> /
  <a href="./docs/README-ru.md">Русский</a> /
  <a href="./docs/README-zh-cn.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/TheGamaj/Node/releases"><img alt="Release" src="https://img.shields.io/badge/release-is.0.0.1-2ea043?style=flat-square" /></a>
  <img alt="Go" src="https://img.shields.io/badge/Go-1.25+-00ADD8?style=flat-square&logo=go&logoColor=white" />
  <img alt="Port" src="https://img.shields.io/badge/control%20port-62050-blue?style=flat-square" />
  <img alt="License" src="https://img.shields.io/badge/license-AGPL--3.0-lightgrey?style=flat-square" />
  <a href="https://github.com/TheGamaj/Node/actions/workflows/binary-build.yml"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/TheGamaj/Node/binary-build.yml?style=flat-square&label=build" /></a>
  <a href="https://github.com/TheGamaj/Node/actions/workflows/e2e-install.yml"><img alt="E2E" src="https://img.shields.io/github/actions/workflow/status/TheGamaj/Node/e2e-install.yml?style=flat-square&label=e2e%20install" /></a>
</p>

## Quick install

Install Gamaj-node as a native binary service:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install
```

Install with a custom node name (a second node on the same host):

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --name gamaj-node2
```

Install the dev channel:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install --dev
```

Install only the `gamaj-node` command script:

```bash
curl -fsSL https://raw.githubusercontent.com/TheGamaj/Node/Asli/scripts/gamaj/gamaj-node.sh | sudo bash -s -- install-script
```

Every node runs on the same native binary install. There is no container install
and no install-mode switch: OpenVPN, WireGuard, L2TP, PPTP, Remote Access, and
Extra VPN are all available on a standard node.

WireGuard runtime details: on first use the node installs `wireguard-tools` and
`nftables`, loads the kernel module, and reconciles one kernel interface per
inbound. By default each WireGuard inbound sends TCP/UDP traffic through nftables
TPROXY to its Xray tunnel port, so Gamaj routing rules still apply. Direct
MASQUERADE/NAT is available only when the runtime explicitly sets
`nat_enabled=true`. The master pushes WireGuard state inside the shared runtime
envelope (`ov_runtime_json`) under `wg_inbounds`, each with a server
`private_key`, `address_pool`, `listen_port`, `tunnel_port` and a `peers` list
(`public_key`, optional `preshared_key`, `address`). Per-peer rx+tx is read from
the kernel and reported to the master as `wg:<user_id>` usage deltas.

Use `help` to view all commands:

```bash
gamaj-node help
```

The control port defaults to `62050` (Xray API on `62051`). Use `--name` and the
panel's node form to run more than one node per host.

## Manual install

Read the setup guide here: [docs/INSTALL.md](docs/INSTALL.md)

## Build from source (no Go preinstalled)

The installer builds the node itself when a binary is not available — including
installing the Go toolchain automatically. For a manual build:

```bash
cd /opt && git clone https://github.com/TheGamaj/Node.git Gamaj-Node && cd Gamaj-Node
sudo apt-get install -y golang-go     # Go 1.25+ (or any current Go toolchain)
go build -o dist/gamaj-node ./cmd/gamaj-node
sudo GAMAJ_NODE_BINARY_OVERRIDE="$PWD/dist/gamaj-node" \
    bash scripts/gamaj/gamaj-node.sh install
```

## Runtime

Gamaj-node is implemented in Go and ships one host-level binary:

- `gamaj-node`: the mutually authenticated gRPC service used by the Gamaj master to control Xray and schedule safe on-host restart/update commands

## Binary builds

Linux `amd64` and Windows `amd64` binaries are built for:

- every pull request
- every published or prereleased GitHub release

Release assets are uploaded as raw executables for all supported release targets:

- `gamaj-node-<version>-linux-386`
- `gamaj-node-<version>-linux-amd64`
- `gamaj-node-<version>-linux-arm64`
- `gamaj-node-<version>-linux-armv5`
- `gamaj-node-<version>-linux-armv6`
- `gamaj-node-<version>-linux-armv7`
- `gamaj-node-<version>-linux-s390x`
- `gamaj-node-<version>-windows-amd64.exe`

You can also reproduce the CI packaging flow locally:

```bash
go run ./tools/build
go run ./tools/smoke
```

The Go packages can be checked directly with:

```bash
go test ./...
```

## Tests

```bash
bash scripts/tests/e2e-node-install.sh   # Install and start the node, then check its control port
```

The end-to-end script needs Linux, systemd, root, and Go. On other platforms it
reports `SKIP` and exits successfully.
