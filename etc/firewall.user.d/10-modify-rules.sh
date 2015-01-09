#!/bin/sh

for iptables in iptables ip6tables; do

	for file in "$FIREWALL_USER_DIR"/*."$iptables"; do
		[ -f "$file" ] || continue
		echo "     * Apply $file"
		$iptables-restore --noflush < "$file"
	done

done

