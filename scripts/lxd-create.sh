#!/bin/bash
name=$1
profile=$2

# Initialize container
sudo lxc init --profile $profile ubuntu:16.04 $name

# Start container
sudo lxc start $name
