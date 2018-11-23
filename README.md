# calico-for-lxd

With this current/ initial commit, the Calico's `cni-plugin` does currently not work entirely. This repository was created to facilitate the development of a Calico CNI Plugin that works with LXD by the use of the current (i.e. November 2018) CNI and Calico versions.

#### Usage

```BASH
# Ensure to start from scratch
$ git clone https://github.com/quater/calico-for-lxd-latest-versions.git
$ vagrant destroy -f && vagrant up && vagrant ssh

# Setup test scenario
vagrant@ubuntu-xenial:~$ cd ~/shared_folder/scripts
vagrant@ubuntu-xenial:~$ ./setup_with_vanilla_code.sh

# Create new LXD profile without any NI
vagrant@ubuntu-xenial:~$ lxc profile create calico
vagrant@ubuntu-xenial:~$ cat <<EOF | lxc profile edit calico
config: {}
description: "No network defined"
devices:   
  root:
    path: /
    pool: default
    type: disk
name: calico
used_by: []
EOF

# Create two LXD containers
vagrant@ubuntu-xenial:~$ ./lxd-create.sh lxd1 calico
vagrant@ubuntu-xenial:~$ ./lxd-create.sh lxd2 calico

# Attach Calico NI to lxd1
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd1 frontend

# Observe that the lxd1 container can be reached from the vagrant machine
vagrant@ubuntu-xenial:~$ ping $(lxc ls lxd1 | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")

# Try to attach the Calico NI to lxd2
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd2 frontend

# Observe that Calico is not assigning an IP address to the second container lxd2
vagrant@ubuntu-xenial:~$ lxc ls

# Detach Calico NIs
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd1 frontend
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd2 frontend

# Destroy LXC containers
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd1
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd2
```