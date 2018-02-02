enable() {
  #set -x
  local port="9040"
  local client="$1"
  local rs=0

  dig +time=1 +tries=1 localhost.onion > /dev/null 2>&1 || rs=1

  if [ "$rs" = 0 ]; then
    case "$client" in
      ??:??:??:??:??:?? ) # mac -> v4 and v6
        rule "" filter      input_rule -m mac --mac-source "$client" -j zm_+TOR
        rule "" filter      input_rule -m mac --mac-source "$client" -j zm_+TOR
        #rule 6  nat    prerouting_rule -m mac --mac-source "$client" -j zm_+TOR
        #rule 6  nat    prerouting_rule -m mac --mac-source "$client" -j zm_+TOR
        ;;
      *.* )
        rule "" filter       input_rule -s "$client" -j zm_+TOR
        rule "" nat     prerouting_rule -s "$client" -j zm_+TOR
        ;;
      *:* )
        #rule 6  filter       input_rule -s "$client" -j zm_+TOR
        #rule 6  nat     prerouting_rule -s "$client" -j zm_+TOR
        ;;
    esac
  fi
  return $rs
}

# vim: ts=2 sw=2 et
