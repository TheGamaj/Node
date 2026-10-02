<p align="center">
  <a href="./CONTRIBUTING.md">English</a> /
  <a href="./CONTRIBUTING-ru.md">Русский</a> /
  <a href="./CONTRIBUTING-zh-cn.md">简体中文</a>
</p>

# Contributing to Gamaj Node

Thanks for helping. This project has a small set of non-negotiable rules; read
them before you write any code, because a pull request that breaks them will not
be merged.

## Red lines

1. **Only the Gamaj name.** No reference to any other panel, node, or script
   project, in code, comments, UI text, docs, or assets. The automated env
   naming guard and the trace sweep fail the build if such a name appears.
2. **No agent traces.** Do not mention AI assistants, agents, or automation
   tools in code, commit messages, or documentation. Commits must look like
   normal developer work.
3. **One install path: native binary + systemd.** No Docker, no compose files,
   no install-mode switch, and no feature may be disabled based on an install
   mode. Every VPN backend (OpenVPN, WireGuard, AmneziaWG, L2TP, PPTP, SSTP and
   the MTProto proxy) ships enabled.
4. **Every environment variable starts with `GAMAJ_NODE_`** (or `GAMAJ_` for
   values shared with the panel). OS-owned and tool-owned names such as `PATH`
   are the only exceptions, and they are listed in the guard.
5. **Port 62050** stays the node control-plane default (the Xray API follows on
   62051).
6. **Docs are self-contained.** Documentation must not send readers to GitHub or
   another site "to read more"; the content belongs in this repository (and in
   the `Web/` docs site).

## Workflow

1. Fork or branch from `Asli`.
2. Keep changes focused; one topic per pull request.
3. Run the checks that apply to what you touched:

```bash
cd Node
gofmt -l .                       # no output
go build ./... && go vet ./internal/... ./cmd/...
go test ./internal/config/ ./internal/platform/envguard/

# installer or test changes:
bash -n scripts/gamaj/gamaj-node.sh scripts/tests/e2e-node-install.sh

# full end-to-end install (Linux + systemd + root, CI runs this on every push):
sudo bash scripts/tests/e2e-node-install.sh
```

4. If you touch anything under `internal/xray/`, run the whole test suite:
   `go test ./...`.

## Commit messages

Short, imperative, and about the change, for example:

```
Fail fast when the Xray binary cannot be executed
Report WireGuard handshake age in the node status
```

Do not add tool footers, generated-by lines, or co-author trailers. The commit
author and committer must be your own Git identity.

## Code style

- Go: `gofmt`, `go vet`, error wrapping with `%w`, table-driven tests next to
  the package they cover.
- Shell: `set -euo pipefail`, `GAMAJ_NODE_`-prefixed options, no external
  dependency beyond the usual POSIX tools plus `curl`, `jq`, and `tar`.
- CI assets: AmneziaWG and the accel-ppp bundle build on native runners with a
  musl toolchain — never reintroduce a container runtime.

## Vendored code

The `vendor/` tree is a normal Go vendor directory; keep it consistent with
`go.mod`. Never hand-edit vendored packages, and never let `.gitignore` rules
leak into `vendor/` (ignore rules for runtime downloads must be anchored, for
example `/xray-core`).

## Reporting problems

Include: the node version (`gamaj-node version` or the release tag), the OS and
architecture, journal output (`journalctl -u gamaj-node -n 100`), and the
minimal steps to reproduce. Security issues go to the maintainers privately —
do not open a public issue for anything you suspect is exploitable.
