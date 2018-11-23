#!/bin/bash
name=$1
profile=$2

# Initialize container
sudo lxc init --profile $profile ubuntu:16.04 $name

# Start container
sudo lxc start $name

pid=$(sudo lxc info $name | grep 'Pid' | cut -d ':' -f 2 |  tr -d '[[:space:]]')
sudo mkdir -p /var/run/netns
sudo ln -s /proc/$pid/ns/net /var/run/netns/$pid
