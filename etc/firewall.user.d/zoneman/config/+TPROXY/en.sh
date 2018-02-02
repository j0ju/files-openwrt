enable() {
  local port="3128"
  local client="$1"
  local rs=0

  #wget -s -q 127.0.0.1:$port/squid-internal-static/icons/anthony-f.gif > /dev/null 2>&1 || rs=1
  is_squid_listening > /dev/null 2>&1 || rs=1

  if [ "$rs" = 0 ]; then
    case "$client" in
      ??:??:??:??:??:?? ) # mac -> v4 and v6
        rule "" filter      input_rule -m mac --mac-source "$client" -j zm_+TPROXY
        rule "" nat    prerouting_rule -m mac --mac-source "$client" -j zm_+TPROXY
        rule 6  filter      input_rule -m mac --mac-source "$client" -j zm_+TPROXY
        rule 6  nat    prerouting_rule -m mac --mac-source "$client" -j zm_+TPROXY
        ;;
      *.* )
        #rule "" filter       input_rule -s "$client" -j zm_+TPROXY
        rule "" nat     prerouting_rule -s "$client" -j zm_+TPROXY
        ;;
      *:* )
        #rule 6  filter       input_rule -s "$client" -j zm_+TPROXY
        rule 6  nat     prerouting_rule -s "$client" -j zm_+TPROXY
        ;;
	  esac
  fi
  return $rs
}

is_squid_listening() {
  local CONF="/etc/squid/squid.conf"
  local http_ports="$( sed -rne 's/^.*http_port (.*:)?([0-9]+)( .*)?$/\2/p' "$CONF" )"
  local regex=
  local p
  for p in $http_ports; do
    [ -z "$regex" ] && regex="${p}" || regex="$regex|$p"
  done
  regex="($regex)"
  echo "^tcp.* .*:$regex .* LISTEN .*/squid$"
  netstat -lntp | egrep "^tcp.* .*:$regex .* LISTEN .*/squid$"
  return $?
}


# vim: ts=2 sw=2 et
