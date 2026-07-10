#!/bin/sh

bridge="$1"
host_interface="$2"

/sbin/ifconfig ${bridge} deletem ${host_interface}
/sbin/ifconfig ${host_interface} destroy
