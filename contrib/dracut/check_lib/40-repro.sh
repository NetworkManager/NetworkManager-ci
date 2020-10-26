reproduce_1840989() {
  nmcli c add type vlan \
    ifname eth0.195 \
    con-name eth0.195 \
    id 195 \
    dev eth0 \
    ipv4.method manual \
    ipv6.method ignore \
    ipv4.address 192.168.122.195/24 \
    || die die "unable to add 'eth0.195'"
  nmcli c up eth0.195 || die "unable to activate 'eth0.195'"
  NM_logs | grep -F 'device (eth0.195): mtu: failure to set IPv6 MTU' && \
    die "message visible in NM logs"
  echo "[OK] message not visible in NM logs"
}
