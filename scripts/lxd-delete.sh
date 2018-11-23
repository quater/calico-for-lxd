#!/bin/bash
name=$1
pid=$(sudo lxc info $name | grep 'Pid' | cut -d ':' -f 2 |  tr -d '[[:space:]]')

sudo lxc stop $name
sudo lxc delete $name

sudo rm -rf /var/run/netns/$pid
