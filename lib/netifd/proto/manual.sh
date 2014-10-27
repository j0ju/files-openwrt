#!/bin/sh

. /lib/functions.sh
. ../netifd-proto.sh
init_proto "$@"

proto_manual_init_config() {
        proto_config_add_string up
}

proto_manual_setup() {
        local config="$1"
        local iface="$2"

        local up down
        json_get_vars up down

        proto_export "INTERFACE=$config"
        date
        if [ -n "$up" ] && [ -x "$up" ]; then
                "$up" "$config" "$iface"
        fi
}

proto_manual_teardown() {
        local interface="$1"
        # do nothing, for now
}

add_protocol manual

