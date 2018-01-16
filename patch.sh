#!/bin/sh
# vim: foldmethod=marker:foldmarker=#{,#}
BASEDIR="${0%/*}"
set -e
#set -x
umask 022

#{ modify preinit to load from /etc/modules-boot.d/ before
sbin=init
mv "$BASEDIR/sbin/$sbin" "$BASEDIR/lib/$sbin"
cat > "$BASEDIR/sbin/$sbin" << EOF
#!/bin/sh
mount -t proc proc /proc
echo "- kmodloader /etc/modules-boot.d/ -"
kmodloader /etc/modules-boot.d/
umount /proc
exec /lib/$sbin
EOF
chmod 755 "$BASEDIR/sbin/$sbin"
#}
#{ create SuSe like rc$SCRIPT links to init scripts
__PREFIX__="$BASEDIR" "$BASEDIR/usr/local/bin/update-rc"
#}
#{ disable services
  RC_TO_DISABLE=
  RC_TO_DISABLE="$RC_TO_DISABLE qos"
  RC_TO_DISABLE="$RC_TO_DISABLE firewall"
  RC_TO_DISABLE="$RC_TO_DISABLE siproxd"
  RC_TO_DISABLE="$RC_TO_DISABLE fastd openvpn"
  RC_TO_DISABLE="$RC_TO_DISABLE telnet"
  RC_TO_DISABLE="$RC_TO_DISABLE httpd uhttpd"
  RC_TO_DISABLE="$RC_TO_DISABLE nfsd portmap"
  RC_TO_DISABLE="$RC_TO_DISABLE fstab btrfs-scan"
  RC_TO_DISABLE="$RC_TO_DISABLE usbmode"
  RC_TO_DISABLE="$RC_TO_DISABLE cron crond"
  RC_TO_DISABLE="$RC_TO_DISABLE ipset-dns keepalived igmpproxy etherwake relayd"
  RC_TO_DISABLE="$RC_TO_DISABLE bird4 bird6"

  for _rc in $RC_TO_DISABLE; do
    rm -f "$BASEDIR/etc/rc.d/"S[0-9][0-9]$_rc
  done

#}
#{ ensure full pathname for netifd protos
find_bin() {
  [ -z "$1" ] && return
  local BIN_DIRS="/bin /sbin /usr/sbin /usr/bin"
  local dir bin
  for dir in $BIN_DIRS; do
     bin="$BASEDIR/$dir/$1"
     [ -x "$bin" ] && break || :
  done
  [ -x "$bin" ] && echo "$dir/$1" || :
}

grep -E -o '(proto_run_command [^ ]+ )([^\ ]+)' "$BASEDIR"/lib/netifd/proto/* 2> /dev/null | while read file; do
  cd "$BASEDIR"
  file="${file#$BASEDIR}"
  line="${file#*:}"
  file="${file%%:*}"
  prog="${line##* }"
  case "${prog}" in
    /* ) continue ;;
  esac

  real_proc="$(find_bin "$prog")"
  [ -n "$real_proc" ] || continue
  [ -x "$BASEDIR/$real_proc" ] || continue

  sed -i -re 's@(proto_run_command [^ ]+ )([^ ]+)@\1'"$real_proc"'@' "$BASEDIR/$file"
done
#}
#{ patch openwrt files
  ( cd "$BASEDIR"
  set -x
    find . -name "*.diff" | while read diff; do
      file="${diff#./}"
      file="${file%.diff}"
      echo "* /$file"
      awk '($1 == "---" || $1 == "+++") && $2 = "'"$file"'" {  } {print $0}' "$diff" | patch -p0 && \
        rm -f "$diff"
    done
  )
#}
#{ ensure correct permissions
  ( cd "$BASEDIR"
    find . -type d             -exec chmod u+rwx,go+rx,u-s,go-ws,-t {} +
    find . -type f             -exec chmod u+rw,go+r                {} +
    find . -type f -perm /0111 -exec chmod u+rwx,go+rx              {} +
    chmod 1777 tmp
  )
#}
