#!/bin/sh

#_SCRIPT="$(readlink -f "$0")"
_SCRIPT="$0"
_BASENAME="${_SCRIPT##*/}"
_BASEDIR="${_SCRIPT%/*}"; case "$_BASEDIR" in . | "" | "$_SCRIPT" ) _BASEDIR="$PWD" ;; esac

_LOG="/tmp/$_BASENAME.log"

#MOUNT=/bin/mount
MOUNT="/bin/busybox mount"

OPTS=
FS=
ARGS=

#set -x
while [ $# -gt 0 ]; do
	case "$1" in
		--rbind )
			OPTS="$OPTS,rbind" 
			;;
		--move )
			OPTS="$OPTS,move" 
			;;
		--bind ) 
			OPTS="$OPTS,bind" 
			;;
		-o )
			OPTS="$OPTS,$2"
			shift
			;;
		-t )
			FS="$2"
			shift
			;;
		-n ) : # ignore this because we do not use /etc/mtab
			;;
		*)
			ARGS="$ARGS '$1'"		
			;;
	esac
	shift

	OPTS="${OPTS#,}"
	OPTS="${OPTS%,}"
done

for p in /usr/local/sbin /usr/local/bin /sbin /bin; do
	[ -x "$p/mount.$FS" ] || continue
	MOUNT="'$p/mount.$FS'"
	FS=
	break
done

eval "exec $MOUNT $ARGS ${FS:+-t '$FS'} ${OPTS:+-o $OPTS}"
