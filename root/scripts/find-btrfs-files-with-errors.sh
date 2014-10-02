#!/bin/sh

dmesg | sed -n 's/^.*btrfs.*ino\(de\)\? \([0-9]\+\).*$/\2/ p' | sort -u | xargs -n 1 find / -xdev -inum
