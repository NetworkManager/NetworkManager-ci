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
