enable() {
  local client="$1"

  case "$client" in
    ??:??:??:??:??:?? ) # mac -> v4 and v6
      rule "" filter      input_rule -m mac --mac-source "$client" -j ACCEPT
      rule "" filter forwarding_rule -m mac --mac-source "$client" -j ACCEPT
      rule  6 filter      input_rule -m mac --mac-source "$client" -j ACCEPT
      rule  6 filter forwarding_rule -m mac --mac-source "$client" -j ACCEPT
      ;;
    *.* )
      rule ""  filter           input_rule -s "$client" -j ACCEPT
      rule ""  filter      forwarding_rule -s "$client" -j ACCEPT
      ;;
    *:* )
      rule  6  filter           input_rule -s "$client" -j ACCEPT
      rule  6  filter      forwarding_rule -s "$client" -j ACCEPT
      ;;
  esac
}



