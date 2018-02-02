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
  RC_TO_DISABLE="$RC_TO_DISABLE qos wshaper sqm"
  RC_TO_DISABLE="$RC_TO_DISABLE firewall"
  RC_TO_DISABLE="$RC_TO_DISABLE siproxd"
  RC_TO_DISABLE="$RC_TO_DISABLE fastd openvpn"
  RC_TO_DISABLE="$RC_TO_DISABLE telnet"
  RC_TO_DISABLE="$RC_TO_DISABLE httpd uhttpd"
  RC_TO_DISABLE="$RC_TO_DISABLE nfsd portmap"
  RC_TO_DISABLE="$RC_TO_DISABLE fstab btrfs-scan"
  RC_TO_DISABLE="$RC_TO_DISABLE usbmode"
  RC_TO_DISABLE="$RC_TO_DISABLE dsl dsl_control"
  RC_TO_DISABLE="$RC_TO_DISABLE cron crond"
  RC_TO_DISABLE="$RC_TO_DISABLE ipset-dns keepalived igmpproxy etherwake relayd"
  RC_TO_DISABLE="$RC_TO_DISABLE bird4 bird6"
  RC_TO_DISABLE="$RC_TO_DISABLE ram-pkg binary-cache"

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

grep -E -o '(proto_run_command +[^ ]+ )([^ ]+)' "$BASEDIR"/lib/netifd/proto/* 2> /dev/null | while read file; do
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

  sed -i -re 's@(proto_run_command +[^ ]+ )([^ ]+)@\1'"$real_proc"'@' "$BASEDIR/$file"
done
#}
#{ add users and groups + sort
  DEFAULT_ROOTHOME=/tmp
  sed -i -r -e '/^root/ s@(root:[^:]+:[0-9]+:[0-9]+:[^:]+):[^:]+:(.*$)@\1:'"$DEFAULT_ROOTHOME"':\2@' etc/passwd
  rm -f /init

cat >> etc/passwd << EOF
bird:x:479:479:bird:/var:/bin/false
collectd:x:499:499:collectd:/tmp:/bin/false
nobody:*:65534:65534:nobody:/var:/bin/false
EOF
  sort -n -t ':' -k3 etc/passwd > etc/passwd.$$ && \
    mv -f etc/passwd.$$ etc/passwd

cat >> etc/group << EOF
bird:x:479:bird
collectd:x:499:collectd
EOF
  sort -n -t ':' -k3 etc/group > etc/group.$$ && \
    mv -f etc/group.$$ etc/group

#}
#{ patch openwrt files
  ( cd "$BASEDIR"
    find . -xdev -name "*.diff" | while read diff; do
      file="${diff#./}"
      file="${file%.diff}"
      case "$file" in
        etc/rc.d/* )
          rm -f  $diff
          continue
          ;;
      esac
      echo "* /$file"
      awk '($1 == "---" || $1 == "+++") { $2 = "'"$file"'" } {print $0}' "$diff" | patch -p0 && \
        rm -f "$diff" || \
        exit $?
    done

    find -xdev -name "*.rej"      -exec rm -f {} + || :
    find -xdev -name "*.orig"     -exec rm -f {} + || :
    find -xdev -name "*.diff"     -exec rm -f {} + || :
    find -xdev -name ".*.sw[a-z]" -exec rm -f {} + || :
  )
#}
#{ configure opkg
  ( cd "$BASEDIR"
  #- set opkg.conf ram destionation directory
    sed -i -r -e 's@^(dest ram) .*$@\1 /var/lib/opkg-ram@' etc/opkg.conf
    sed -i -r -e 's@^(lists_dir [^ ]+) .*$@\1 /var/cache/opkg-lists@' etc/opkg.conf
  #- opkg - no local feeds
    sed -i -e '/_local/ d' etc/opkg/distfeeds.conf
  )
#}
#{ try to remove some files
  ( cd "$BASEDIR"
    rmdir 2> /dev/null \
      www \
      opt \
      srv \
      || : #
    rm -rf 2> /dev/null \
      etc/config/igmpproxy \
      etc/config/keepalived \
      etc/config/etherwake \
      etc/config/openvpn \
      etc/collectd* \
      etc/keepalived* \
      etc/bird?.conf \
      etc/keepalived/keepalived.conf \
      || : #
  )
#}
#{ ensure correct permissions
  ( cd "$BASEDIR"
    find . -xdev -type d             -exec chmod u+rwx,go+rx,u-s,go-ws,-t {} +
    find . -xdev -type f             -exec chmod u+rw,go+r                {} +
    find . -xdev -type f -perm /0111 -exec chmod u+rwx,go+rx              {} +
    chmod 1777 tmp
  )
#}
