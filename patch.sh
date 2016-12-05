#!/bin/sh
# vim: foldmethod=marker:foldmarker=#{,#}
BASEDIR="${0%/*}"
set -e

#{ create SuSe like rc$SCRIPT links to init scripts
__PREFIX__="$BASEDIR" "$BASEDIR/usr/local/bin/update-rc"
#}

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

