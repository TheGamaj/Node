#!/usr/bin/env bash
# Gamaj Node — Xray core auto-install check.
#
# The node installer is supposed to fetch and install the Xray core on its own
# when none is present. The end-to-end install test deliberately stubs the core
# so the rest of the node can be exercised without a download, which means the
# auto-install path itself is never executed.
#
# This test runs the real install function and proves it works end to end:
#   - the core installer resolves from the copy vendored in this repository, not
#     from another repository over the network (the remote is pointed at an
#     unreachable address, so a network fallback would fail the test),
#   - the core is downloaded for the host architecture and unpacked,
#   - the binary and the geo assets land where the node expects them,
#   - the installed binary actually runs and reports a version.
#
# Requirements: Linux, curl, unzip, root (the installer writes under /usr/local).
# On any other platform the test reports SKIP and succeeds.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
installer="$repo_root/scripts/gamaj/install_latest_xray.sh"

skip() {
    echo "SKIP: $*"
    exit 0
}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

step() { printf '\n==> %s\n' "$*"; }
ok()   { printf '  ok  %s\n' "$*"; }

# ------------------------------------------------------------- requirements
[ "$(uname -s)" = "Linux" ] || skip "the Xray core assets are built for Linux"
command -v curl >/dev/null 2>&1 || skip "curl is not available"
command -v unzip >/dev/null 2>&1 || skip "unzip is not available"
[ "$(id -u)" -eq 0 ] || skip "the Xray core installer must run as root"
[ -f "$installer" ] || fail "missing vendored core installer: $installer"
[ -f "$repo_root/scripts/gamaj/gamaj-node.sh" ] || fail "missing node installer"

work_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

step "loading the node installer"
# Same prelude the end-to-end test uses: naming the app lets the sourced script
# take its first branch instead of reading an unset COMMAND under `set -u`.
export GAMAJ_NODE_APP_NAME="gamaj-xray-check"
export GAMAJ_NODE_SOURCE_ONLY=1
E2E_SOURCED=1
# shellcheck disable=SC1091
source "$repo_root/scripts/gamaj/gamaj-node.sh"
ok "node installer loaded"

# Point the remote at an address that cannot answer. If the function falls back
# to fetching the core installer, curl fails and the test fails — which is the
# point: the vendored copy must be preferred.
GAMAJ_SCRIPT_BASE_URL="http://127.0.0.1:1/gamaj/does-not-exist"
APP_DIR="$work_dir/app"
DATA_DIR="$work_dir/data"
mkdir -p "$APP_DIR" "$DATA_DIR/xray-core"

step "running install_latest_xray_for_binary_node with the remote unreachable"
if ! install_latest_xray_for_binary_node; then
    fail "the core installer did not resolve from the copy in this repository"
fi
ok "core installer resolved without touching the network"

# ------------------------------------------------------------------- verify
step "checking the installed core"
xray_bin="$DATA_DIR/xray-core/xray"
[ -f "$xray_bin" ] || fail "installer did not produce $xray_bin"
ok "core binary downloaded"
[ -x "$xray_bin" ] || fail "$xray_bin is not executable"
ok "core binary is executable"

for asset in geoip.dat geosite.dat; do
    [ -f "$DATA_DIR/xray-core/$asset" ] || fail "installer did not provide $asset"
done
ok "geo assets present"

step "running the installed core"
version_line="$("$xray_bin" -version 2>&1 | head -1)"
case "$version_line" in
    *Xray*) ok "core reports: $version_line" ;;
    *) fail "unexpected version output: $version_line" ;;
esac

echo
ok "Xray core auto-install check passed"