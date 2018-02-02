#!/bin/sh
# vim:ft=sh:foldmethod=marker:foldmarker=#{,#}:sw=2:ts=2:expandtab

DNSMASQ_CONFIG=/etc/dnsmasq.conf
ETHERS=/etc/ethers

ZM_DIR=/etc/firewall.user.d/zoneman

die() { #{
  echo "$*" >&2
  exit 1
} #}
warn() { #{
  echo "$*" >&2
} #}



resolve_mac() { #{ name <-> mac
  case "$1" in
    *:*:*:*:*:* ) # mac -> name
      local name="$(awk '$1 == "'"$1"'" {print $2; exit}' /etc/ethers)"

      if [ -n "$name" ]; then
        echo "$name"
      return 0
      fi
      name="$(awk -F '[=,]' '$1 = "dhcp-host" && $2 == "'$1'" {print $NF}' /etc/dnsmasq.conf)"
      if [ -n "$name" ]; then
        echo "$name"
      return 0
      fi

    ;;
  * ) : # name -> mac
      local mac="$(awk '$2 ~ /^'"$1"'/ {print $1; exit}' /etc/ethers)"
    
      if [ -n "$mac" ]; then
        echo "$mac"
      return 0
      fi
    
      mac="$(awk -F '[=,]' '$1 = "dhcp-host" && $NF ~ "^'$1'" {print $2}' /etc/dnsmasq.conf)"
      if [ -n "$mac" ]; then
        echo "$mac"
      return 0
      fi
    ;;
  esac
  return 1
} #}
resolve_ip() { #{ name <-> ip
  case "$1" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]* ) # ip -> name
      local name
      name="$(nslookup "$1" 2> /dev/null | awk '/^Name:/ {found=1} /^Address [0-9]:/ {if (found==1) {print $4; exit }}')"
      if [ -n "$name" ]; then
        echo "$name"
        return 0
      fi
  ;;
  * ) # name -> ip
      local ip
      ip="$(nslookup "$1" 2> /dev/null | awk '/^Name:/ {found=1} /^Address [0-9]:[^:]+$/ {if (found==1) {print $3; exit }}')"
      if [ -n "$ip" ]; then
        echo "$ip"
        return 0
      fi
  ;;
  esac
  return 1
} #}
resolve_ipv6() { #{ name <-> ip
  case "$1" in
    *:* ) # ip -> name
      local name
      name="$(nslookup "$1" 2> /dev/null | awk '/^Name:/ {found=1} /^Address [0-9]:/ {if (found==1) {print $4; exit }}')"
      if [ -n "$name" ]; then
        echo "$name"
        return 0
      fi
  ;;
  * ) # name -> ip
      local ip
      ip="$(nslookup "$1" 2> /dev/null | awk '/^Name:/ {found=1} /^Address [0-9]:[^.]+$/ {if (found==1) {print $3; exit }}')"
      if [ -n "$ip" ]; then
        echo "$ip"
        return 0
      fi
  ;;
  esac
  return 1
} #}

usage() { #{ usage
  echo "USAGE:"
  echo " * list | ls              - show all avail configs"
  echo " * status                 - show enable configs"
  echo " * hosts                  - show known hosts"
  echo
  echo " * add <CONFIG> <SPEC>       - add config to host/mac/net"
  echo " * rem | rm <CONFIG> <SPEC>  - add config to host/mac/net"
  echo "   <CONFIG> = config, see list command"
  echo "   <SPEC>   = hostname, ip, CIDR or MAC" 
  echo 
} #}
list_configs() { #{
  local dir config
  
  echo "Avail network mangling options:"
  for dir in "$ZM_DIR/config/"*; do
    [ -d "$dir" ] || continue
    [ -L "$dir" ] && continue
    config="${dir#$ZM_DIR/config/}"
    echo "  $config"
  done
  echo
} #}
show_known_hosts() { #{
  echo --- known hosts
  printf '%-25s %18s %s\n' IP MAC NAME
  (
    < /var/cache/list-clients awk '$4 != "-" && $2 == "-"' | while read up wlan ip if mac name; do
      printf '%-25s %18s %s\n' "$ip" "$mac" "$name"
    done
    < /var/dhcp.leases awk '$4 == "*"' | while read epoch mac ip name; do
      name="-- UNKNOWN DHCP --"
      printf '%-25s %18s %s\n' "$ip" "$mac" "$name"
    done
  ) | sort -n 
} #}

rem_line_file() { #{
  local file="$1"
  local line="$2"
  if [ -s "$file" ]; then
    #line="$(echo -n "$line" | sed 's/[+]/\\\0/g')"
    grep -v "^$line\$" < "$file" > "$file.$$" 
    mv "$file.$$" "$file"
    rm -f "$file.$$"
  fi
  [ -s "$file" ] || rm -f "$file"
} #}
add_line_file() { #{
  grep "^$2$" "$1" 1>/dev/null 2>&1 || echo "$2" >> "$1"
} #}
manage_client_config() { #{
  local op="$1"; shift
  local config="$1"; shift
  local spec cl_cfg

  if [ "$op" = add ] && ! [ -d "$ZM_DIR/config/$config" ]; then
    die "E: '$config' config not found"
  fi

  for spec; do
    ipv4=
    ipv6=
    mac=
    case "$spec" in
      ??:??:??:??:??:?? ) # mac
        mac="$spec"
        ;;
      *.*.*.* )           # ipv4
        ipv4="$spec"
        ;;
      *::* | *:????* )    # ipv6
        ipv6="$spec"
        ;;
      *.*.*.*/* )         # ipv4 CIDR
        ipv4="$spec"
        ;;
      *:*/* )             # ipv6 CIDR
        ipv6="$spec"
        ;;
      * )                 # hostname
        host="$spec"
        mac="$(resolve_mac "$host")"
        ipv4="$(resolve_ip "$host")"
        ipv6="$(resolve_ipv6 "$host")"
        ;;
    esac
    if [ -z "$mac$ipv4$ipv6" ]; then
      warn "W: no MAC, IPv4 nor IPv6 found for '$spec', skipping"
      continue
    fi

    if [ -n "$mac" ]; then
      echo "I: $op $mac to $config"
      cl_cfg="$mac"
      ${op}_line_file "$ZM_DIR/clients/$cl_cfg" "$config"
    else
      if [ -n "$ipv4" ]; then
        echo "I: $op $ipv4 to $config"
        cl_cfg="$(echo -n "$ipv4" | tr '/' '_')"
        ${op}_line_file "$ZM_DIR/clients/$cl_cfg" "$config"
      fi
      if [ -n "$ipv6" ]; then
        echo "I: $op $ipv6 to $config"
        cl_cfg="$(echo -n "$ipv6" | tr '/' '_')"
        ${op}_line_file "$ZM_DIR/clients/$cl_cfg" "$config"
      fi
    fi
  done

  fw reload > /dev/null 2>&1 && echo "Reload OK!" || echo "ERROR reloading."
} #}

show_status() { #{
  local cl
  local seen=" "
  for f in "$ZM_DIR/clients"/*; do
    [ -f "$f" ] || continue

    mac=
    ipv4=
    ipv6=
    host=

    cl="${f#$ZM_DIR/clients/}"

    case "$cl" in
      *_* ) host="$(echo "$cl" | tr '_' '/')" ;;
      ??:??:??:??:??:?? ) host="$(resolve_mac $cl)" ;;
      * ) host="$(resolve_ip "$cl")" ;;
    esac
    host="${host%.}"

    echo "$host ($cl)"
    sed 's/^/  /' < "$f"
  done
} #}

if [ -n "$REMOTE_ADDR" ]; then
  exit 1
fi

case "$1" in
  l | ls | l[is] | lis | list )             list_configs ;;
  s | st | sta | stat | statu | status )    show_status ;;
  h | ho | hos | host )                     show_known_hosts ;;
#
  a | ad | add )                            shift; manage_client_config add "$@" ;;
  r | r[em] | rem | remo | remov | remove ) shift; manage_client_config rem "$@" ;;
#
  ac | act | activate )                     fw restart;;
#
  --help | -h ) usage ;;
  * ) usage ;;
esac

