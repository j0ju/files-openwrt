enable() {
  local port="2003"
  local client="$1"
  local rs=0

  # TODO: test
  # wget -s -q 127.0.0.1:$port/squid-internal-static/icons/anthony-f.gif > /dev/null 2>&1 || rs=1
  rs=0

  if [ "$rs" = 0 ]; then
    case "$client" in
      ??:??:??:??:??:?? ) # mac -> v4 and v6
        rule "" filter      input_rule -m mac --mac-source "$client" -j zm_+carbuffd
        rule "" filter      input_rule -m mac --mac-source "$client" -j zm_+carbuffd
        #rule 6  nat    prerouting_rule -m mac --mac-source "$client" -j zm_+carbuffd
        #rule 6  nat    prerouting_rule -m mac --mac-source "$client" -j zm_+carbuffd
        ;;
      *.* )
        rule "" filter       input_rule -s "$client" -j zm_+carbuffd
        rule "" nat     prerouting_rule -s "$client" -j zm_+carbuffd
        ;;
      *:* )
        #rule 6  filter       input_rule -s "$client" -j zm_+carbuffd
        #rule 6  nat     prerouting_rule -s "$client" -j zm_+carbuffd
        ;;
	  esac
  fi
  return $rs
}

# vim: ts=2 sw=2 et
