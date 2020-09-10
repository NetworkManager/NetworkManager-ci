nmcli_list() {
  echo "== nmcli device =="
  nmcli device | cat
  echo "== nmcli connection =="
  nmcli con | cat
}

nmcli_con_active() {
  nmcli -g NAME,DEVICE con show --active | grep -q -F "$1:$2" \
    || die "'$1' connection is not active on '$2'"
  echo "[OK] '$1' connection is active on '$2'"
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
