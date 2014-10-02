#!/bin/sh

UID="$(awk '/^Uid:/ { print $2}' /proc/$$/status)"
export HOME="$(awk -F: '/^[-a-zA-Z0-9]+:[^:]*:'"$UID"':/ {print $6}' /etc/passwd)"
cd "$HOME"

exec /bin/ash --login
