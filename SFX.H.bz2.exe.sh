#!/bin/sh
SKIP=12; CACHE=/tmp/cache/bin; mkdir -p $CACHE; DELAY=60; U=bzcat; exe="$CACHE/${0##*/}"
if [ ! -x "$exe" ]; then
 if tail -n +$SKIP "$0" | $U > "$exe"; then
  chmod 755 "$exe"
  ( trap : HUP; sleep $DELAY; rm -f "$exe"; ) &
 else
  echo Cannot decompress $0; exit 1
 fi
fi
exec "$exe" "$@"
