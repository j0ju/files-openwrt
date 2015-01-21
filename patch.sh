#!/bin/sh
# vim: foldmethod=marker:foldmarker=#{,#}
BASEDIR="${0%/*}"
set -e

#{ WLAN - patch regulatory domain
# to be compliant with the local freq limits use the config
gcc -o "$BASEDIR/reghack" "$BASEDIR/reghack.c"
find "$BASEDIR" -name "cfg80211.ko" -exec "$BASEDIR/reghack" {} \;
find "$BASEDIR" -name "ath.ko" -exec "$BASEDIR/reghack" {} \;
rm -f "$0" "$BASEDIR/reghack" "$BASEDIR/reghack.c"
#}
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
__PREFIX__="$BASEDIR" "$BASEDIR/usr/local/sbin/update-rc"
#}
#{ ignore block sizes try to squeeze more out of some file larger than
MAX_SIZE=150K
PACKER="disabled:disabled" # default, disabled
#PACKER="bzip2:bz2.exe"
#PACKER="xz:xz.exe"
#PACKER="gzip:gz.exe"
PREAMBLE='SFX.H.${suffix}.sh'

find \
  ${BASEDIR}/sbin \
  ${BASEDIR}/usr/bin \
  ${BASEDIR}/usr/sbin \
    -size +100k | \
      while read f; do
        suffix="${PACKER#*:}"
        compress="${PACKER%:*}"
        eval "preamble=\"$PREAMBLE\""
        [ -f "$BASEDIR/$preamble" ] || continue

        sfx="$f.$suffix"
        echo "PACK: $compress: $f -> $sfx"
        cat "$BASEDIR/$preamble" > "$sfx"
        $compress < "$f" >> "$sfx"
        cat "$sfx" > "$f"
        rm -f "$sfx"
      done

suffix="*"
eval "preamble=\"$PREAMBLE\""
rm -f "$BASEDIR"/$preamble
#}
