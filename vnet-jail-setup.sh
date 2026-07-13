#!/bin/sh

bridge="$1"
epair_part="$2"
mac_part="$3"
jail_name="$4"

epair_descr="jail:${jail_name}"

host_interface="${epair_part}a"
host_mac="${mac_part}a"

jail_interface="${epair_part}b"
jail_mac="${mac_part}b"

/sbin/ifconfig ${epair_part} create ether ${host_mac}
/sbin/ifconfig ${jail_interface} ether ${jail_mac} descr "$epair_descr"
/sbin/ifconfig ${host_interface} up descr "$epair_descr"
/sbin/ifconfig ${bridge} addm ${host_interface} up
