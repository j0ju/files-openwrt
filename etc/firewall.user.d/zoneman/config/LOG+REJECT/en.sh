enable() {
  local client="$1"

  case "$client" in
    ??:??:??:??:??:?? ) # mac -> v4 and v6
	  rule ""   filter            input_rule -m mac --mac-source "$client" -j only_LOG+REJECT
	  rule ""   filter       forwarding_rule -m mac --mac-source "$client" -j only_LOG+REJECT
	  rule  6  filter            input_rule -m mac --mac-source "$client" -j only_LOG+REJECT
	  rule  6  filter       forwarding_rule -m mac --mac-source "$client" -j only_LOG+REJECT
	  ;;
	*.* )
	  rule ""   filter            input_rule -s "$client" -j only_LOG+REJECT
	  rule ""   filter       forwarding_rule -s "$client" -j only_LOG+REJECT
	  ;;
	*:* )
	  rule  6  filter            input_rule -s "$client" -j only_LOG+REJECT
	  rule  6  filter       forwarding_rule -s "$client" -j only_LOG+REJECT
	  ;;
  esac
}



