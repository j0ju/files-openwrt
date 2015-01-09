#!/bin/sh
BASEDIR="${0%/*}"

set -e

# WLAN - patch regulatory domain
# to be compliant with the local freq limits use the config
gcc -o "$BASEDIR/reghack" "$BASEDIR/reghack.c"
find "$BASEDIR" -name "cfg80211.ko" -exec "$BASEDIR/reghack" {} \;
find "$BASEDIR" -name "ath.ko" -exec "$BASEDIR/reghack" {} \;
rm -f "$0" "$BASEDIR/reghack" "$BASEDIR/reghack.c"

# modify preinit to load from /etc/modules-boot.d/ before
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

# create SuSe like rc$SCRIPT links to init scripts
__PREFIX__="$BASEDIR" "$BASEDIR/usr/local/sbin/update-rc"
