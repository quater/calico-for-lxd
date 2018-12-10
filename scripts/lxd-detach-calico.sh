#!/bin/bash
name=$1
network=$2
interface=$3
pid=$(sudo lxc info $name | grep 'Pid' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo CNI_PATH=/usr/local/bin CNI_IFNAME=$interface cnitool del $network /var/run/netns/${pid}-${interface}
sudo rm -rf /var/run/netns/${pid}-${interface}