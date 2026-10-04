#!/usr/bin/env bash
# Gamaj Node — Xray core auto-install check.
#
# The node installer is supposed to fetch and install the Xray core on its own
# when none is present. The end-to-end install test deliberately stubs the core
# so the rest of the node can be exercised without a 15 MB download, which
# means the auto-install path itself is never executed.
#
# This test runs the real installer and proves it works: the core is downloaded
# for the host architecture, unpacked, made executable and reports a version.
#
# Requirements: Linux, curl, unzip.
# On any other platform the test reports SKIP and succeeds.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
installer="$repo_root/scripts/gamaj/install_latest_xray.sh"
[ -f "$installer" ] || installer="$repo_root/scripts/install_latest_xray.sh"

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
# The installer places the core and its compatibility symlinks under
# /usr/local, so it refuses to run without root.
[ "$(id -u)" -eq 0 ] || skip "the Xray core installer must run as root"
[ -f "$installer" ] || fail "missing installer: $installer"

install_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$install_dir"
}
trap cleanup EXIT

# ------------------------------------------------------------------- install
step "running the Xray core installer into a temporary directory"
GAMAJ_DATA_DIR="$install_dir" \
GAMAJ_XRAY_INSTALL_DIR="$install_dir/xray-core" \
GAMAJ_XRAY_ASSETS_DIR="$install_dir/xray-core" \
    bash "$installer"

# ------------------------------------------------------------------- verify
step "checking the installed core"
xray_bin="$install_dir/xray-core/xray"
[ -f "$xray_bin" ] || fail "installer did not produce $xray_bin"
ok "core binary downloaded"
[ -x "$xray_bin" ] || fail "$xray_bin is not executable"
ok "core binary is executable"

# The geo files ship alongside the core and the node needs them for routing.
for asset in geoip.dat geosite.dat; do
    [ -f "$install_dir/xray-core/$asset" ] || fail "installer did not provide $asset"
done
ok "geo assets present"

step "running the installed core"
if ! version_line="$("$xray_bin" -version 2>&1 | head -1)"; then
    fail "installed core did not run: $version_line"
fi
case "$version_line" in
    *Xray*) ok "core reports: $version_line" ;;
    *) fail "unexpected version output: $version_line" ;;
esac

echo
ok "Xray core auto-install check passed"