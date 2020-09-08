ip_list() {
  echo "== ip addr =="
  ip addr
  echo "== ip -4 route =="
  ip -4 route
  echo "== ip -6 route =="
  ip -6 route
}

ip_ifname() {
  local ifname="$1"
  local ip="$2"
  ip addr show dev "$ifname" | grep -q -F "$ip" || \
    die "$ifname does not have IP $ip:$(echo; ip addr show dev "$ifname")"
  echo "[OK] '$ifname' has IP '$ip'"
}

mac2ifname() {
  IFNAME=$(ip -o link | grep -F "$1")
  IFNAME="$(arg 2 $IFNAME)"
  IFNAME="${IFNAME%:}"
  export IFNAME
}

ip_mac() {
  mac2ifname "$1"
  echo "MAC '$1' is interface '$IFNAME'"
  ip_ifname "$IFNAME" "$2"
}

ip_route_unique() {
  local r_num
  r_num=$(ip route | grep -F "$1" | wc -l)
  [[ "$r_num" == 1 ]] || die "route '$1' visible $r_num times: $(echo; ip route)"
  echo "[OK] route '$1' is unique"
}

ip4_route_unique() {
  ip() { /sbin/ip -4 $@ ; }
  ip_route_unique "$1"
  unset ip
}

ip6_route_unique() {
  ip() { /sbin/ip -6 $@ ; }
  ip_route_unique "$1"
  unset ip
}

link_no_ip4() {
  ip -o addr show dev $1 | grep -q -w -F "inet" && \
    die "link '$1' has address: $(echo; ip addr show dev $1)"
  echo "[OK] link '$1' has no address"
}

get_lease_time() {
  ip a show $ifname | sed "s/.*valid_lft\s\+//;s/\s\+preferred_lft.*//;s/sec//" | sed -n "/$IP/{n;p;}"
}

ip_forever() {
  local IP ifname
  IP="$1"
  ifname="$2"
  [[ $(get_lease_time) == "forever" ]] ||
    die "link '$1' no forever IPv4 lease: $(echo; ip -a addr show dev $ifname)"
  echo "[OK] IP '$IP' on link '$ifname' address with forever lease"
}

ip4_forever() {
  ip() { /sbin/ip -4 $@ ; }
  ip_forever "$1" "$2"
  unset ip
}

ip6_forever() {
  ip() { /sbin/ip -6 $@ ; }
  ip_forever "$1" "$2"
  unset ip
}

wait_for_ip_renew() {
  local ifname IP lease_time last_lease count
  IP=$1
  ifname=$2
  lease_time="$(get_lease_time)"
  [[ -n "$lease_time" ]] || die "unable to get lease time: $(echo; ip addr show $ifname)"
  count=0
  # lease time is forever in early phase
  while [[ "$lease_time" == "forever" ]]; do
    (( count >= 10 )) && die "lease time is forever: $(echo; ip addr show $ifname)"
    sleep 1
    lease_time="$(get_lease_time)"
  done
  (( $lease_time <= 120 )) || die "lease time too big: $(echo; ip addr show $ifname)"
  last_lease=$lease_time
  count=0
  while (( lease_time <= last_lease )); do
      (( count++ > 120 )) && \
          die "$ifname lease not renewed in 120s: $(echo; ip a show $ifname)"
      (( lease_time < 15 )) && \
          die "$ifname lease is <15s: $(echo; ip a show $ifname)"
      sleep 1
      last_lease=$lease_time
      lease_time="$(get_lease_time)"
  done
  echo "lease time change: $last_lease -> $lease_time"
  echo "[OK] '$ifname' succesfully renewed"
}

wait_for_ip4_renew() {
  ip() { /sbin/ip -4 $@ ; }
  wait_for_ip_renew "$1" "$2"
  unset ip
}

wait_for_ip6_renew() {
  ip() { /sbin/ip -6 $@ ; }
  wait_for_ip_renew "$1" "$2"
  unset ip
}
