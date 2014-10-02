#!/bin/sh
for i in /sys/class/net/*/brport /sys/class/net/*/master all default; do
  i="${i%/*}"
  [ -d "$i" ] || continue
  i="${i##*/}"
  sysctl -w net.ipv6.conf.$i.disable_ipv6=1
done

