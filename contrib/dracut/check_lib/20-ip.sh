# checks using ip command

# define ip commands, that fail the test if returncode != 0
ipX() { /sbin/ip $@ || die "ip command failed" ; }

ip4() { ipX -4 $@ ; }
ip6() { ipX -6 $@ ; }
ip() { ipX $@ ; }


ip_list() {
  echo "== ip addr =="
  ip addr
  echo "== ip -4 route =="
  ip -4 route
  echo "== ip -6 route =="
  ip -6 route
}


ip_route_unique() {
  local r_num
  r_num=$(ip route | grep -F "$1" | wc -l)
  [[ "$r_num" == 1 ]] || die "route '$1' visible $r_num times: $(echo; ip route)"
  echo "[OK] route '$1' is unique"
}


ip4_route_unique() {
  ip() { ip4 $@ ; }
  ip_route_unique "$1"
  ip() { ipX $@ ; }
}


ip6_route_unique() {
  ip() { ip6 $@ ; }
  ip_route_unique "$1"
  ip() { ipX $@ ; }
}


link_no_ip() {
  ip -o addr show dev $ifname | grep -q -w -F "$inet" && \
    die "link '$ifname' has IPv$ip_ver address: $(echo; ip addr show dev $ifname)"
  echo "[OK] link '$ifname' has no IPv$ip_ver address"
}


link_no_ip4() {
  local ifname ip_ver inet
  ifname=$1
  ip_ver=4
  inet=inet
  ip() { ip4 $@; }
  link_no_ip
  ip() { ipX $@ ; }
}


link_no_ip6() {
  local ifname ip_ver inet
  ifname=$1
  ip_ver=6
  inet=inet6
  ip() { ip6 $@; }
  link_no_ip
  ip() { ipX $@ ; }
}


get_lease_time() {
  local IP_esc
  IP_esc=$(echo $IP | sed 's@/@\\/@g')
  ip a show $ifname | sed "s/.*valid_lft\s\+//;s/\s\+preferred_lft.*//;s/sec//" | sed -n "/$IP_esc/{n;p;}"
}


ip_forever() {
  local IP IP_esc ifname
  IP="$1"
  ifname="$2"
  [[ $(get_lease_time) == "forever" ]] ||
    die "link '$1' no forever IPv4 lease: $(echo; ip -a addr show dev $ifname)"
  echo "[OK] IP '$IP' on link '$ifname' address with forever lease"
}


ip4_forever() {
  ip() { ip4 $@ ; }
  ip_forever "$1" "$2"
  ip() { ipX $@ ; }
}


ip6_forever() {
  ip() { ip6 $@ ; }
  ip_forever "$1" "$2"
  ip() { ipX $@ ; }
}


wait_for_ip_renew() {
  local ifname IP lease_time last_lease count MAX_LEASE
  MAX_LEASE=120
  IP=$1
  ifname=$2
  lease_time="$(get_lease_time)"
  [[ $lease_time ]] || die "'$ifname' does not have '$IP': $(echo; ip a show $ifname)"
  count=0
  # lease time is forever in early phase
  while [[ "$lease_time" == "forever" ]]; do
    (( count >= 10 )) && die "'$ifname' lease time is forever: $(echo; ip addr show $ifname)"
    sleep 1
    lease_time="$(get_lease_time)"
    [[ $lease_time ]] || die "'$ifname' lost IP '$IP': $(echo; ip a show $ifname)"
  done
  (( $lease_time <= $MAX_LEASE )) || die "'$ifname' lease time '$lease_time' is too big: $(echo; ip addr show $ifname)"
  last_lease=$lease_time
  count=0
  while (( lease_time <= last_lease )); do
      (( count++ > $MAX_LEASE )) && \
          die "'$ifname' lease not renewed in ${MAX_LEASE}s: $(echo; ip a show $ifname)"
      (( lease_time < 5 )) && \
          die "'$ifname' lease is <5s: $(echo; ip a show $ifname)"
      sleep 1
      last_lease=$lease_time
      lease_time="$(get_lease_time)"
      [[ $lease_time ]] || die "'$ifname' lost IP '$IP': $(echo; ip a show $ifname)"
  done
  echo "[OK] '$ifname' '$IP' lease renewed: ${last_lease}s -> ${lease_time}s"
}


wait_for_ip4_renew() {
  ip() { ip4 $@ ; }
  wait_for_ip_renew "$1" "$2" &
  ip() { ipX $@ ; }
}


wait_for_ip6_renew() {
  ip() { ip6 $@ ; }
  wait_for_ip_renew "$1" "$2" &
  ip() { ipX $@ ; }
}
