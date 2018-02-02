#!/bin/sh
# vim:ft=sh:foldmethod=marker:foldmarker=#{,#}:sw=2:ts=2:expandtab

#- setup
ZM_DIR=/etc/firewall.user.d/zoneman

#- init
PREPARED_SPECIALS=

# first ma
loadClients() {
  local f
  local seen
  local client

  for f in "$ZM_DIR/clients"/??:??:??:??:??:?? "$ZM_DIR/clients"/*; do
    [ -f "$f" ] || continue
    client="${f#$ZM_DIR/clients/}"
    # skip CIDR at first
    case "$client" in *_* ) continue ;; esac
    # skip seen
    case "$seen" in *" $client "* ) continue ;; esac
    seen="$seen $client "

    enClient "$f"
  done

  # do CIDR
  for f in "$ZM_DIR/clients"/??:??:??:??:??:?? "$ZM_DIR/clients"/*_*; do
    [ -f "$f" ] || continue
    client="${f#$ZM_DIR/clients/}"
    # skip seen
    case "$seen" in *" $client "* ) continue ;; esac
    seen="$seen $client "

    enClient "$f"
  done
}

enClient() {
  local f="$1"
  local client="${f#$ZM_DIR/clients/}"
  local cfgdir

  while read cfg param; do
    if ! prepareSpecial "$cfg" "$param"; then
      echo "W: could not load '$cfg'" >&2
      continue
    fi
    cfgdir="$ZM_DIR/config/$cfg"
    if ! [ -f "$cfgdir/en.sh" ]; then
      echo "W: could not enable '$cfg' for '$client'" >&2
      continue
    fi

    client="$(echo -n "$client" | tr '_' '/')"

    # enable client
    . "$cfgdir/en.sh"
    if enable "$client"; then
      echo "     * enabled $cfg for $client"
    else
      echo " NOT enabled $cfg for $client" >&2
    fi
  done < "$f"
}

# [""|6] [nat|filter|...] [CHAIN] rule
rule() {
  local v="$1"; shift
  local t="$1"; shift
  local c="$1"; shift
  while ip${v}tables -t "$t" -D "$c" "$@"; do :; done 2> /dev/null
        ip${v}tables -t "$t" -A "$c" "$@"
}

prepareSpecial() {
  local cfg="$1"
  local dir="$ZM_DIR/config/$cfg"
  [ -d "$dir" ] || return 1

  case "$PREPARED_SPECIALS" in
    *" $cfg "* ) return 0 ;;
  esac

  for ext in iptables ip6tables; do
    for f in "$dir"/*.$ext; do
      [ -f "$f" ] || continue
      $ext-restore --noflush < "$f" && \
        echo "     * loaded ${f#$ZM_DIR/config/}"
    done
  done
  [ -f "$dir/prepare.sh" ] && . "$dir/prepare.sh"

  PREPARED_SPECIALS="$PREPARED_SPECIALS $cfg "
  echo "     * prepared $cfg"
}

# add jumps for NETs, IPs, MACs
loadClients
