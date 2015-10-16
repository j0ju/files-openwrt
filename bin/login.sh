#!/bin/sh

# default umask and PATH
umask 0022
export PATH=/sbin:/bin:/usr/sbin:/usr/bin

# unexport all other variables
for env in $(env | cut -f1 -d= | grep ^[A-Za-z_]) ""; do
  [ -z "$env" ] && continue
  case "$env" in
    TERM | PATH ) continue ;;
  esac
  export "$env"=
  unset $env
done

# export HOME
UID="$(awk '/^Uid:/ { print $2}' /proc/$$/status)"
export HOME="$(awk -F: '/^[-a-zA-Z0-9]+:[^:]*:'"$UID"':/ {print $6}' /etc/passwd)"
cd "$HOME"

exec /bin/ash --login

