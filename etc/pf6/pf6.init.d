#!/bin/sh
### BEGIN INIT INFO
# Provides:          pf6
# Required-Start:    mountkernfs udev kmod
# Required-Stop:     
# Default-Start:     S
# Default-Stop:
# Short-Description: local iptables rules
# Description:       local iptables rules
### END INIT INFO

cd /etc/pf6
#cd /opt/etc/pf6

exec ./pf6 "$@"

