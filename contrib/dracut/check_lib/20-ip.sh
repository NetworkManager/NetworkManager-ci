ip_ifname() {
  local ifname="$1"
  local ip="$2"
  ip addr show dev "$ifname" | grep -q -F "$ip" || die "$ifname does not have IP $IP:$(echo; ip addr show dev "$ifname")"
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
  [[ "$r_num" == 1 ]] || die "route '$1' visible $r_num times"
  echo "[OK] route '$1' is unique"
}

link_no_ip4() {
  ip -o addr show dev $1 | grep -q -w -F "inet" && die "link '$1' has address: $(echo; ip addr show dev $1)"
  echo "[OK] link '$1' has no address"
}

wait_for_ip_renew() {
  local ifname lease_time last_lease count
  ifname=$1
  lease_time="$(ip -4 a show $ifname | grep valid_lft | awk '{print $2}' | grep -o '[0-9]*')"
  [[ -n "$lease_time" ]] || die "unable to get lease time: $(echo; ip -4 addr show $ifname)"
  (( $lease_time <= 120 )) || die "lease time too big: $(echo; ip -4 addr show $ifname)"
  last_lease=$lease_time
  count=0
  while (( lease_time <= last_lease )); do
      sleep 1
      if (( cout++ > 120 )); then
          die "$ifname lease not renewed in 120s: $(echo; ip -4 a show $ifname)"
      fi
      last_lease=$lease_time
      lease_time="$(ip -4 a show $ifname | grep valid_lft | awk '{print $2}' | grep -o '[0-9]*')"
  done
  echo "lease time change: $last_lease -> $lease_time"
  echo "[OK] '$ifname' succesfully renewed"
}
