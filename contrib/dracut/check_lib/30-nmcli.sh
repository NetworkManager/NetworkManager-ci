nmcli_list() {
  echo "== nmcli device =="
  nmcli device | cat
  echo "== nmcli connection =="
  nmcli con | cat
}

nmcli_con_active() {
  # recursively calls itself until connection is active or counter $i gets over $num
  local num i
  num="$3"
  [[ -z "$1" ]] && die "nmcli_con_active: unspecified connection name"
  [[ -z "$2" ]] && die "nmcli_con_active: unspecified interface name"
  [[ -z "$num" ]] && num=10
  i=0
  while (( i <= num )); do
    nmcli -g NAME,DEVICE,STATE con show --active | \
      grep -q -F "$1:$2:activated"  && \
      echo "[OK] connection '$1' is active on '$2' in $i seconds" && \
      return 0
    sleep 1
    (( i++ ))
  done
  die "connection '$1' is not active on '$2' in $num seconds:$(echo; nmcli -g NAME,DEVICE,STATE con show)"
}

nmcli_con_num() {
  local num
  num=$(nmcli -g UUID con show | wc -l)
  [[ "$num" == "$1" ]] || die "number of NM connections: $num, expected $1"
  echo "[OK] number of NM connections: $1"
}

nmcli_con_prop() {
  local con prop val res
  con="$1"
  prop="$2"
  val="$3"
  res=$(nmcli -g "$prop" con show "$con")
  [[ "$res" == "$val" ]] || die "'$prop' of '$con' is not '$val', but '$res'"
  echo "[OK] '$prop' of '$con' is '$val'"
}
