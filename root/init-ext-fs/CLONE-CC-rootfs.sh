#!/bin/sh

if [ -z "$1" ]; then
  echo "$0: creates a copy of current rootfs to the first parameter given"
  exit 1
fi

( set -e; set -x
  whereami="$PWD"

  #rm -rf "$1"
  mkdir -p "$1"
  cd "$1"

  mkdir -p sys proc tmp srv opt mnt
  ln -s tmp var
  chmod 1777 tmp

  cp -a /dev /etc /bin /sbin /lib /usr /root /www .

  rm -f sbin/init sbin/procd init
  cp -a /rom/sbin/procd lib/procd
  cp -a "$whereami"/sbin-init sbin/procd
  ln -s procd sbin/init

  rm -f etc/preinit
  if [ -x "$whereami"/rootfs-etc-preinit ]; then
    cp -a "$whereami"/rootfs-etc-preinit etc/preinit
  fi

  # flush jffs2
  #for i in 1 2 3; do
  #  sync
  #  dd if=/dev/urandom of=.dummy.$$ bs=1k count=1k
  #  sync
  #  rm -f .dummy.$$ 
  #done
  sync
)

echo
echo "$0: have a look at $1/etc/preinit"
echo "$0: ensure that your init is working"
echo

