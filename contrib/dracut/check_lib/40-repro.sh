reproduce_1840989() {
  nmcli c add type vlan \
    ifname ens3.195 \
    con-name ens3.195 \
    id 195 \
    dev ens3 \
    ipv4.method manual \
    ipv6.method ignore \
    ipv4.address 192.168.122.195/24 \
    || die die "unable to add 'ens3.195'"
  nmcli c up ens3.195 || die "unable to activate 'ens3.195'"
  NM_logs | grep -F 'device (ens3.195): mtu: failure to set IPv6 MTU' && \
    die "message visible in NM logs"
  echo "[OK] message not visible in NM logs"
}
