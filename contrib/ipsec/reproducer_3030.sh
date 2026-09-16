#!/bin/bash
# Reproducer for libreswan 5.4 routing state cleanup bug
# https://github.com/libreswan/libreswan/issues/3030
#
# Bug: Missing case X(TEARDOWN_CHILD, ROUTED_NEGOTIATION, INSTANCE) in
# programs/pluto/routing.c dispatch_1().
#
# When a modecfg VPN gateway (auto=start, right=<peer>) revives a connection
# after receiving Delete, the revival INSTANCE's Child SA enters
# ROUTED_NEGOTIATION state. If a new client connection arrives before the
# revival completes, the old INSTANCE can't be torn down (unhandled dispatch),
# leaving stale kernel policy that blocks the new connection.
#
# Topology:
#   Client (host, 192.0.2.2) <--veth/podman--> Server (container, 192.0.2.1)
#
# Requires: podman (rootful), libreswan on host, internet for image pull
# Usage:    sudo bash reproducer_3030.sh
#
# Logs are saved to /tmp/ipsec-repro-3030-logs/ (persists after cleanup).

set -euo pipefail

IMAGE="quay.io/centos/centos:stream10-development"
NET="ipsec-repro"
SRV="ipsec-repro-srv"
SRV_IP="192.0.2.1"
CLI_IP="192.0.2.2"
WORKDIR=$(mktemp -d /tmp/ipsec-repro.XXXXXX)
LOGDIR="/tmp/ipsec-repro-3030-logs"
NSSDIR="/var/lib/ipsec/nss"

pass() { echo -e "\033[32m  PASS: $*\033[0m"; }
fail() { echo -e "\033[31m  FAIL: $*\033[0m"; FAILURES=$((FAILURES+1)); }
log()  { echo -e "\n\033[1m=== $* ===\033[0m"; }
srv()  { podman exec "$SRV" "$@"; }

FAILURES=0

save_logs() {
    log "Saving logs to $LOGDIR"
    mkdir -p "$LOGDIR"
    podman cp "$SRV:/var/log/pluto.log" "$LOGDIR/server-pluto.log" 2>/dev/null || true
    cp /var/log/pluto-repro.log "$LOGDIR/client-pluto.log" 2>/dev/null || true
    echo "  Server log: $LOGDIR/server-pluto.log"
    echo "  Client log: $LOGDIR/client-pluto.log"
}

cleanup() {
    log "Cleanup"
    save_logs
    ipsec whack --shutdown 2>/dev/null || true
    certutil -D -d "sql:$NSSDIR" -n "TestCA" 2>/dev/null || true
    certutil -D -d "sql:$NSSDIR" -n "cli-a.example.org" 2>/dev/null || true
    BRIDGE=$(podman network inspect "$NET" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['network_interface'])" 2>/dev/null || true)
    [ -n "$BRIDGE" ] && ip addr del "$CLI_IP/24" dev "$BRIDGE" 2>/dev/null || true
    podman rm -f "$SRV" 2>/dev/null || true
    podman network rm "$NET" 2>/dev/null || true
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

log "Step 1: Create server container"
podman rm -f "$SRV" 2>/dev/null || true
podman network rm "$NET" 2>/dev/null || true
podman network create "$NET" --subnet 192.0.2.0/24 --gateway 192.0.2.254
podman run -d --name "$SRV" --network "$NET" --ip "$SRV_IP" \
    --hostname ipsec-srv.example.org --privileged "$IMAGE" sleep infinity

log "Step 2: Install libreswan in container"
podman exec "$SRV" bash -c "dnf install -y libreswan openssl procps-ng iproute iputils 2>&1 | tail -1"

log "Step 3: Generate certificates"
cd "$WORKDIR"

openssl genrsa -out ca.key 2048 2>/dev/null
openssl req -new -x509 -key ca.key -out ca.pem -days 30 \
    -subj "/CN=Test CA" -batch 2>/dev/null

cat > server_ext.cnf << 'EOF'
[v3_req]
subjectAltName = DNS:ipsec-srv.example.org,IP:192.0.2.1
keyUsage = digitalSignature
extendedKeyUsage = serverAuth,clientAuth
EOF
openssl genrsa -out server.key 2048 2>/dev/null
openssl req -new -key server.key -out server.csr -subj "/CN=ipsec-srv.example.org" -batch 2>/dev/null
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.pem -days 30 \
    -extfile server_ext.cnf -extensions v3_req 2>/dev/null
openssl pkcs12 -export -out server.p12 -inkey server.key -in server.pem -certfile ca.pem \
    -passout pass:foobar -name ipsec-srv.example.org 2>/dev/null

cat > client_ext.cnf << 'EOF'
[v3_req]
subjectAltName = DNS:cli-a.example.org,IP:192.0.2.2
keyUsage = digitalSignature
extendedKeyUsage = clientAuth,serverAuth
EOF
openssl genrsa -out client.key 2048 2>/dev/null
openssl req -new -key client.key -out client.csr -subj "/CN=cli-a.example.org" -batch 2>/dev/null
openssl x509 -req -in client.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out client.pem -days 30 \
    -extfile client_ext.cnf -extensions v3_req 2>/dev/null
openssl pkcs12 -export -out client.p12 -inkey client.key -in client.pem -certfile ca.pem \
    -passout pass:foobar -name cli-a.example.org 2>/dev/null

echo "Certificates generated."

log "Step 4: Import certificates into NSS databases"
podman cp ca.pem "$SRV:/tmp/"
podman cp server.p12 "$SRV:/tmp/"
srv ipsec initnss 2>/dev/null || true
srv certutil -A -d sql:/var/lib/ipsec/nss -n "TestCA" -t "CT,," -i /tmp/ca.pem
srv pk12util -i /tmp/server.p12 -d sql:/var/lib/ipsec/nss -W foobar -K "" 2>&1 | tail -1

[ -f "$NSSDIR/cert9.db" ] || ipsec initnss 2>/dev/null || true
certutil -D -d "sql:$NSSDIR" -n "TestCA" 2>/dev/null || true
certutil -D -d "sql:$NSSDIR" -n "cli-a.example.org" 2>/dev/null || true
certutil -A -d "sql:$NSSDIR" -n "TestCA" -t "CT,," -i "$WORKDIR/ca.pem"
pk12util -i "$WORKDIR/client.p12" -d "sql:$NSSDIR" -W foobar -K "" 2>&1 | tail -1

log "Step 5: Configure and start server"
podman exec "$SRV" bash -c "cat > /etc/ipsec.conf << EOF
config setup
    logfile=/var/log/pluto.log
    logappend=no
    dnssec-enable=no
conn cert_gw_ipv4
    keyexchange=ikev2
    authby=rsasig
    auto=start
    left=192.0.2.1
    leftid=@ipsec-srv.example.org
    leftcert=ipsec-srv.example.org
    leftsubnet=0.0.0.0/0
    leftsendcert=always
    leftmodecfgserver=yes
    rightaddresspool=10.0.1.50-10.0.1.250
    rightmodecfgclient=yes
    right=${CLI_IP}
    rightid=%fromcert
    rightca=%same
EOF"

podman exec "$SRV" bash -c "cat > /etc/ipsec.secrets << 'EOF'
: RSA ipsec-srv.example.org
EOF"

srv ipsec pluto --config /etc/ipsec.conf --logfile /var/log/pluto.log
sleep 2

log "Step 6: Set up client networking"
BRIDGE=$(podman network inspect "$NET" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['network_interface'])" 2>/dev/null || echo "podman1")
ip addr add "$CLI_IP/24" dev "$BRIDGE" 2>/dev/null || true
ping -c1 -W2 "$SRV_IP" >/dev/null 2>&1

log "Step 7: Configure and start client pluto"
cat > /etc/ipsec.conf << CONFEOF
config setup
    logfile=/var/log/pluto-repro.log
    logappend=no
    dnssec-enable=no
conn repro-correct
    keyexchange=ikev2
    authby=rsasig
    left=${CLI_IP}
    leftid=@cli-a.example.org
    leftcert=cli-a.example.org
    leftmodecfgclient=yes
    right=${SRV_IP}
    rightid=@ipsec-srv.example.org
    rightsubnet=0.0.0.0/0
    require-id-on-certificate=yes
    auto=add
conn repro-wrong
    keyexchange=ikev2
    authby=rsasig
    left=${CLI_IP}
    leftid=@cli-a.example.org
    leftcert=cli-a.example.org
    leftmodecfgclient=yes
    right=${SRV_IP}
    rightid=@hostc.example.com
    rightsubnet=0.0.0.0/0
    require-id-on-certificate=yes
    auto=add
CONFEOF

cat > /etc/ipsec.secrets << 'CONFEOF'
: RSA cli-a.example.org
CONFEOF

ipsec whack --shutdown 2>/dev/null || true
sleep 1
rm -f /run/pluto/pluto.pid /run/pluto/pluto.ctl
ipsec pluto --config /etc/ipsec.conf --logfile /var/log/pluto-repro.log
sleep 2
ipsec auto --add repro-correct 2>&1
ipsec auto --add repro-wrong 2>&1

# Phase 1: correct rightid → PASS
log "Phase 1: Connect with correct rightid (expect: SUCCESS)"
OUTPUT=$(ipsec auto --up repro-correct 2>&1) || true
echo "$OUTPUT"
if echo "$OUTPUT" | grep -q "established Child SA"; then
    pass "Phase 1: tunnel established"
else
    fail "Phase 1: tunnel failed (unexpected)"
    srv tail -20 /var/log/pluto.log || true
fi

ipsec auto --down repro-correct 2>&1 || true
sleep 2

# Phase 2: wrong rightid → client rejects cert → Delete → server revives
log "Phase 2: Connect with WRONG rightid (triggers server revival)"
OUTPUT=$(ipsec auto --up repro-wrong 2>&1) || true
echo "$OUTPUT"
if echo "$OUTPUT" | grep -qi "authentication\|AUTHENTICATION_FAILED\|id-on-cert"; then
    pass "Phase 2: correctly rejected (cert identity mismatch)"
elif echo "$OUTPUT" | grep -q "established Child SA"; then
    ipsec auto --down repro-wrong 2>&1 || true
fi
sleep 2

# Phase 3: correct rightid again → should PASS, FAILS with bug
log "Phase 3: Connect with correct rightid again (expect: SUCCESS)"
OUTPUT=$(ipsec auto --up repro-correct 2>&1) || true
echo "$OUTPUT"
if echo "$OUTPUT" | grep -q "established Child SA"; then
    pass "Phase 3: tunnel established (no stale state)"
else
    fail "Phase 3: tunnel FAILED — stale routing state from Phase 2 (BUG)"
fi

ipsec whack --shutdown 2>/dev/null || true

log "Server pluto log — key errors"
echo "EXPECTATION FAILED:"
srv grep "EXPECTATION FAILED.*routing" /var/log/pluto.log 2>/dev/null | head -5 || echo "(none)"
echo ""
echo "TS_UNACCEPTABLE:"
srv grep "TS_UNACCEPTABLE" /var/log/pluto.log 2>/dev/null | grep -v "^.*|" | head -5 || echo "(none)"
echo ""
echo "cannot install kernel policy:"
srv grep "cannot install kernel policy" /var/log/pluto.log 2>/dev/null | head -5 || echo "(none)"

log "Results"
echo
srv rpm -q libreswan || echo "libreswan (version unknown)"
echo
if [ "$FAILURES" -eq 0 ]; then
    pass "All phases passed — no bug"
else
    fail "$FAILURES phase(s) failed — bug is present"
    echo
    echo "Root cause: programs/pluto/routing.c dispatch_1() is missing:"
    echo "  case X(TEARDOWN_CHILD, ROUTED_NEGOTIATION, INSTANCE)"
fi
echo
echo "Logs saved to: $LOGDIR"
echo "  Server: $LOGDIR/server-pluto.log"
echo "  Client: $LOGDIR/client-pluto.log"
echo
exit "$FAILURES"
