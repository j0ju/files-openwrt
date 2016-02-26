#set -x

for i in /proc/sys/net/ipv6/conf/*/disable_ipv6; do 
  echo 1 > "$i"
done 2> /dev/null

swapoff /dev/ramzswap0 2> /dev/null

2> /dev/null killall syslogd
2> /dev/null killall klogd
# 2> /dev/null killall dropbear
2> /dev/null killall telnet
2> /dev/null killall -9 dnsmasq
2> /dev/null killall hotplug2
2> /dev/null killall ubusd
2> /dev/null killall netifd
2> /dev/null killall ntpd
2> /dev/null killall udhcpc

umount /proc/bus/usb
umount /dev/pts
umount /sys/kernel/debug
umount /sys
umount /tmp
mount -o bind /dev /tmp
umount /overlay

exit=0
while [ "$exit" = 0 ]; do
  exit=1
   #for usb storage# for m in $(lsmod | awk '/^[euo]hci_hcd/ { $3=1 } $3 == "0" { print $1 }'); do
  for m in $(lsmod | awk '$3 == "0" { print $1 }'); do
    rmmod $m 2> /dev/null || continue
    echo rmmod $m
    exit=0
  done
done

