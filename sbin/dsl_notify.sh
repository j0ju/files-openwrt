#!/bin/sh
#
# This script is called by dsl_cpe_control whenever there is a DSL event,
# we only actually care about the DSL_INTERFACE_STATUS events as these
# tell us the line has either come up or gone down.

[ "$DSL_NOTIFICATION_TYPE" = "DSL_INTERFACE_STATUS" ] || exit 0

. /usr/share/libubox/jshn.sh
. /lib/functions.sh
. /lib/functions/leds.sh
. /lib/functions/network.sh

local default
config_load system
config_get default led_dsl default
if [ "$default" != 1 ]; then
  case "$DSL_INTERFACE_STATUS" in
    "HANDSHAKE") led_timer dsl 500 500;;
    "TRAINING")  led_timer dsl 200 200;;
    "UP")        led_on    dsl ;;
    *)           led_off   dsl ;;
  esac
fi


# ifup/ifdown wan - if we have link
network_is_up wan && IF_WAN_STATUS=UP || IF_WAN_STATUS=DOWN

case "$DSL_INTERFACE_STATUS:$IF_WAN_STATUS" in
  UP:DOWN )
    ifup wan
    /etc/init.d/openvpn start
    ;;
  *:* )
    ifdown wan
    /etc/init.d/openvpn stop
    ;;
esac

