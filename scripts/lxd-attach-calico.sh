#!/bin/bash
name=$1
network=$2
interface=$3
pid=$(sudo lxc info $name | grep 'Pid' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo mkdir -p /var/run/netns
sudo ln -s /proc/$pid/ns/net /var/run/netns/${pid}-${interface}

sudo CNI_PATH=/usr/local/bin CNI_IFNAME=$interface cnitool add $network /var/run/netns/${pid}-${interface}
