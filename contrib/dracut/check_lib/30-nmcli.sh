# nmcli related checks

nmcli_list() {
  echo "== nmcli device =="
  nmcli device | cat
  echo "== nmcli connection =="
  nmcli con | cat
}


nmcli_con_active() {
  # recursively calls itself until connection is active or counter $i gets over $num
  local rep i con
  rep="$3"
  con=$(echo "$1" | sed 's/:/\\:/g')
  [[ "$1" ]] || die "nmcli_con_active: unspecified connection name"
  [[ "$2" ]] || die "nmcli_con_active: unspecified interface name"
  [[ "$rep" ]] || rep=10
  i=0
  while (( i++ <= rep )); do
    nmcli -g NAME,DEVICE,STATE con show --active | \
      grep -q -F "$con:$2:activated"  && \
      echo "[OK] connection '$1' is active on '$2' ($((i-1))s)" && \
      return 0
    sleep 1
  done
  die "connection '$con' is not active on '$2' in $rep seconds:$(echo; nmcli -g NAME,DEVICE,STATE con show)"
}


nmcli_con_inactive() {
  local con
  [[ "$1" ]] || die "nmcli_con_active: unspecified connection name"
  con=$(echo "$1" | sed 's/:/\\:/g')
  nmcli -g NAME,STATE con show | \
      grep -q "^$con:\$"  || \
      die "connection '$con' is not inactive:$(echo; nmcli -g NAME,STATE con show)"
  echo "[OK] connection '$1' is inactive "
}


nmcli_con_num() {
  local num
  num=$(nmcli -g UUID con show | wc -l)
  [[ "$num" == "$1" ]] || die "number of NM connections: $num, expected $1"
  echo "[OK] number of NM connections: $1"
}


nmcli_con_prop() {
  local con prop val res rep i
  con="$1"
  prop="$2"
  val="$3"
  rep="$4"
  if ! [[ "$rep" ]]; then rep=1; fi
  i=0
  while (( i++ < rep )); do
    res="$(nmcli -g "$prop" con show "$con")"
    # unescape "\:" in case of single property (no ',')
    [[ "$prop" != *,* ]] && res="$(echo "$res" | sed 's/\\:/:/g')"
    [[ "$res" == $val ]] || { sleep 1; continue; }
    echo "[OK] '$prop' of '$con' is '$val' ($((i-1))s)"
    return 0
  done
  die "'$prop' of '$con' is not '$val', but '$res'"
}
