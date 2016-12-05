#!/bin/sh

case "$BUTTON:$ACTION" in
  wps:released ) 
    BUTTON=wps
    ACTION=pressed
    ;;
  BTN_0:released )
    BUTTON=wisp
    ACTION=pressed
    ;;
  BTN_0:pressed )
    BUTTON=ap
    ACTION=pressed
    ;;
  BTN_1:released )
    BUTTON=3g
    ACTION=pressed
    ;;
  * ) 
    BUTTON=
    ACTION=
    ;;
esac

if [ -n "$BUTTON" ]; then
  scriptdir="${script%/*}"
  for script in "$scriptdir/$BUTTON/"*; do
    [ -f "$script" ] && (
#      . "$script"
      logger -t "${script}[$$]" "BUTTON=$BUTTON ACTION=$ACTION"
    )
  done  
fi
