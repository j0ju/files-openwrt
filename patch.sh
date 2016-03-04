#!/bin/sh
# vim: foldmethod=marker:foldmarker=#{,#}
BASEDIR="${0%/*}"
set -e

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
#{ remove some files in /etc/init.d and /etc/rc.d
rm -f \
  "$BASEDIR"/etc/init.d/esi \
  "$BASEDIR"/etc/rc.d/[SK]??esi \
  "$BASEDIR"/etc/rc.d/[SK]??telnet \
  "$BASEDIR"/etc/rc.d/[SK]??pf \
  "$BASEDIR"/etc/rc.d/[SK]??pf6 \
#}
#{ create SuSe like rc$SCRIPT links to init scripts
__PREFIX__="$BASEDIR" "$BASEDIR/usr/local/bin/update-rc"
#}
