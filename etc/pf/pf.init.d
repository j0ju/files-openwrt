#!/bin/sh
### BEGIN INIT INFO
# Provides:          pf
# Required-Start:    mountkernfs udev kmod
# Required-Stop:
# Default-Start:     S
# Default-Stop:
# Short-Description: local iptables rules
# Description:       local iptables rules
### END INIT INFO

# START=20 # immer vor 40

cd /etc/pf
exec ./pf "$@"

