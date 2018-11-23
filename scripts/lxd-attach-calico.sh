#!/bin/bash
name=$1
network=$2
pid=$(sudo lxc info $name | grep 'Pid' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo CNI_PATH=/usr/local/bin cnitool add $network /var/run/netns/$pid
