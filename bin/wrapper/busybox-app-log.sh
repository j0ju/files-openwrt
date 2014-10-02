#!/bin/sh

#_SCRIPT="$(readlink -f "$0")"
_SCRIPT="$0"
_BASENAME="${_SCRIPT##*/}"
_BASEDIR="${_SCRIPT%/*}"; case "$_BASEDIR" in . | "" | "$_SCRIPT" ) _BASEDIR="$PWD" ;; esac

_LOG="/tmp/$_BASENAME.log"

echo "$(date): $0 $@" >> "$_LOG"

exec /bin/busybox "$_BASENAME" "$@"

