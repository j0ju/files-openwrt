#!/bin/sh

set -x

dev="$1"
[ -z "$dev" ] && dev=br-lan

mac="$(ip link show dev $dev | \
        awk '/[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]:[0-9a-f][0-9a-f]/ {print $2}')"

oktet4="$(( 0x${mac##*:} ))"
oktet3="${mac%:*}"
oktet3="$(( 0x${oktet3##*:} ))"
oktet2=254
oktet1=169

ip=$oktet1.$oktet2.$oktet3.$oktet4

while ip -4 addr del $ip/16 dev $dev 2> /dev/null; do :; done
ip -4 addr add $ip/16 dev $dev

