#!/bin/sh
set -e

if ! [ "$1" = --force ]; then
  echo "$0: use the --force luke"
cat << EOF

  prepares the current flash root to start externalized root

EOF
  exit 1
fi >&2
set -x

rm -f /etc/preinit /sbin/init /sbin/procd /lib/procd /init
ln -s $PWD/sbin-init /sbin/init
ln -s /rom/sbin/procd /lib/procd
ln -s $PWD/sbin-procd /sbin/procd
ln -sf $PWD/sbin-init-genfs /sbin/init-genfs

