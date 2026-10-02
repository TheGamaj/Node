#!/usr/bin/env bash
#
# End-to-end check for the Gamaj Node binary install path.
#
# It builds the node binary from this checkout, runs the real installer
# functions against a sandbox prefix, starts the node as a systemd service, and
# fails when the service is not active or the node does not listen on its
# control port. The panel connects to exactly that port, so a broken install is
# caught before a release.
#
# The sandbox keeps the host clean: install prefix, data root and the temporary
# systemd unit all live under a temporary directory and are removed on exit.
#
# Requirements: Linux, systemd, root (run through sudo), Go.
# On any other platform the test reports SKIP and succeeds.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

E2E_PREFIX="${GAMAJ_E2E_PREFIX:-$(mktemp -d /tmp/gamaj-node-e2e-XXXXXX)}"
E2E_NODE_NAME="${GAMAJ_E2E_NODE_NAME:-gamaj-node-e2e}"
E2E_NODE_PORT="${GAMAJ_E2E_NODE_PORT:-62050}"
E2E_WAIT_SECONDS="${GAMAJ_E2E_WAIT_SECONDS:-60}"

NODE_UNIT="/etc/systemd/system/$E2E_NODE_NAME.service"

skip() {
    echo "SKIP: $*"
    exit 0
}

step() {
    echo
    echo "== $*"
}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

cleanup() {
    local exit_code=$?
    if [ "${E2E_SOURCED:-0}" = "1" ]; then
        systemctl disable --now "$E2E_NODE_NAME.service" >/dev/null 2>&1 || true
    fi
    if [ -f "$NODE_UNIT" ]; then
        rm -f "$NODE_UNIT"
        systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    if [ "${GAMAJ_E2E_KEEP_PREFIX:-0}" = "1" ]; then
        echo "Kept sandbox at $E2E_PREFIX"
    else
        rm -rf "$E2E_PREFIX"
    fi
    exit "$exit_code"
}
trap cleanup EXIT

step "Check prerequisites"
[[ "$(uname -s)" == Linux* ]] || skip "the binary install path is Linux-only"
[ -d /run/systemd/system ] || skip "systemd is not running"
command -v systemctl >/dev/null 2>&1 || skip "systemctl is not available"
[ "$(id -u)" -eq 0 ] || skip "the installer needs root (run this script with sudo)"
command -v go >/dev/null 2>&1 || skip "the Go toolchain is required to build the binary"

export GAMAJ_INSTALL_DIR="$E2E_PREFIX/opt"
export GAMAJ_DATA_ROOT="$E2E_PREFIX/var/lib"
APP_DIR="$GAMAJ_INSTALL_DIR/$E2E_NODE_NAME"
DATA_DIR="$GAMAJ_DATA_ROOT/$E2E_NODE_NAME"

step "Build the node binary"
( cd "$REPO_ROOT" && CGO_ENABLED=0 go build -trimpath -buildvcs=false -o dist/gamaj-node ./cmd/gamaj-node )
[ -x "$REPO_ROOT/dist/gamaj-node" ] || fail "dist/gamaj-node was not built"

step "Prepare sandbox configuration"
mkdir -p "$APP_DIR" "$DATA_DIR/xray-core"
# The installer only downloads Xray when the data dir has no core yet. A stub
# that answers both `version` and `-version` keeps this test focused on the
# node service itself (the Go core refuses to start without a detectable
# "Xray <major>.<minor>.<patch>" version line).
cat > "$DATA_DIR/xray-core/xray" <<'STUB'
#!/bin/sh
case "${1:-}" in
    version|-version)
        echo "Xray 25.8.29 (Xray, Penetrates Everything.) Custom (go1.24.0 linux/amd64)"
        ;;
    *)
        exit 0
        ;;
esac
STUB
chmod +x "$DATA_DIR/xray-core/xray"

# The node service enforces mTLS on its gRPC API. Issue a throwaway client CA
# (the service generates its own server certificate when it is missing) so the
# sandbox matches the security posture of a real deployment.
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$DATA_DIR/client-ca.key" -out "$DATA_DIR/client-ca.pem" \
    -days 2 -subj "/CN=gamaj-e2e-client-ca" >/dev/null 2>&1
[ -s "$DATA_DIR/client-ca.pem" ] || fail "the throwaway client CA was not created"

{
    echo "[TEMPLATE]"
    echo "GAMAJ_NODE_SERVICE_HOST=127.0.0.1"
    echo "GAMAJ_NODE_SERVICE_PORT=$E2E_NODE_PORT"
    echo "GAMAJ_NODE_XRAY_API_HOST=127.0.0.1"
    echo "GAMAJ_NODE_XRAY_API_PORT=$((E2E_NODE_PORT + 1))"
    echo "GAMAJ_DATA_DIR=$DATA_DIR"
    echo "GAMAJ_NODE_INSTALL_MODE=binary"
    echo "GAMAJ_NODE_SSL_CERT_FILE=$DATA_DIR/ssl_cert.pem"
    echo "GAMAJ_NODE_SSL_KEY_FILE=$DATA_DIR/ssl_key.pem"
    echo "GAMAJ_NODE_SSL_CLIENT_CERT_FILE=$DATA_DIR/client-ca.pem"
    echo "GAMAJ_XRAY_EXECUTABLE_PATH=$DATA_DIR/xray-core/xray"
} > "$APP_DIR/.env"

step "Install the node through the installer functions"
export GAMAJ_NODE_APP_NAME="$E2E_NODE_NAME"
export GAMAJ_NODE_BINARY_OVERRIDE="$REPO_ROOT/dist/gamaj-node"
export GAMAJ_NODE_BINARY_OVERRIDE_VERSION="is.0.0.1"
export GAMAJ_NODE_SOURCE_ONLY=1
E2E_SOURCED=1

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/gamaj/gamaj-node.sh"

if normalize_install_mode docker >/dev/null 2>&1; then
    fail "the node installer still accepts the removed docker install mode"
fi
[ "$(normalize_install_mode "")" = "binary" ] || fail "the node installer did not default to binary mode"

install_binary_gamaj_node latest 0
up_gamaj_node

grep -qi docker "$NODE_UNIT" && fail "$E2E_NODE_NAME.service still references docker"
[ -f "$APP_DIR/.binary-release.json" ] || fail "the node did not write its binary release metadata"

step "Wait for the node control port $E2E_NODE_PORT"
listening=0
for _ in $(seq 1 "$E2E_WAIT_SECONDS"); do
    if ss -ltn | awk '{print $4}' | grep -qE "[:.]$E2E_NODE_PORT\$"; then
        listening=1
        break
    fi
    if ! systemctl is-active --quiet "$E2E_NODE_NAME.service"; then
        journalctl -u "$E2E_NODE_NAME.service" --no-pager -n 50 || true
        fail "$E2E_NODE_NAME.service stopped before it accepted connections"
    fi
    sleep 1
done
[ "$listening" -eq 1 ] || {
    journalctl -u "$E2E_NODE_NAME.service" --no-pager -n 50 || true
    fail "the node is not listening on port $E2E_NODE_PORT within ${E2E_WAIT_SECONDS}s"
}

step "Assert the node stays healthy"
sleep 5
systemctl is-active --quiet "$E2E_NODE_NAME.service" || fail "the node service did not stay active"
[ -s "$DATA_DIR/ssl_cert.pem" ] || fail "the node did not create its TLS certificate"
[ -s "$DATA_DIR/ssl_key.pem" ] || fail "the node did not create its TLS key"

echo
echo "PASS: Gamaj Node binary install is healthy on port $E2E_NODE_PORT"
