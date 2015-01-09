#!/bin/sh

for iptables in iptables ip6tables; do
	${iptables}-save | while read minusA chain more; do
		[ "$minusA" = "-A" ] || continue
		case "$chain" in
			*_REJECT ) ;;
			* ) continue ;;
		esac
		case "$more" in	
			*"-j LOG"* ) ;;
			* ) continue ;;
		esac

		"$iptables" -I "$chain" -j log_reject_filter
	done
done
