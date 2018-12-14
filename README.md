# calico-for-lxd

This repository showcases how Calico can be used with LXC/LXD. At present, the only caveat is that is only possible to attach one Calico managed network interface per container.

#### Usage

```BASH
# Ensure to start from scratch
$ git clone git@github.com:quater/calico-for-lxd.git
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

# Attach Calico NI to lxd1 and lxd2
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd1 frontend callxd0
vagrant@ubuntu-xenial:~$ ./lxd-attach-calico.sh lxd2 frontend callxd0

# Observe that the containers can be pinged from the LXD host
vagrant@ubuntu-xenial:~$ ping -c 3 $(lxc ls lxd1 | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")
vagrant@ubuntu-xenial:~$ ping -c 3 $(lxc ls lxd2 | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")

# Verify that LXC containers can ping each other
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd1 -- ping -c 3 $(sudo lxc exec lxd2 -- ip addr | grep -A 3 callxd0 | grep -Po 'inet \K[\d.]+')
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd2 -- ping -c 3 $(sudo lxc exec lxd1 -- ip addr | grep -A 3 callxd0 | grep -Po 'inet \K[\d.]+')

# Create Calico network policy to deny ICMP on ingress
vagrant@ubuntu-xenial:~$ calicoctl create -f -<<EOF
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: deny-icmp
spec:
  types:
  - Ingress
  ingress:
  - action: Deny
    protocol: ICMP
    source:
      selector: role == 'frontend'
EOF

# Verify that LXC containers cannot ping each other any more
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd1 -- ping -W 1 -c 3 $(sudo lxc exec lxd2 -- ip addr | grep -A 3 callxd0 | grep -Po 'inet \K[\d.]+')
vagrant@ubuntu-xenial:~$ sudo lxc exec lxd2 -- ping -W 1 -c 3 $(sudo lxc exec lxd1 -- ip addr | grep -A 3 callxd0 | grep -Po 'inet \K[\d.]+')

# Detach Calico NIs
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd1 frontend callxd0
vagrant@ubuntu-xenial:~$ ./lxd-detach-calico.sh lxd2 frontend callxd0

# Destroy LXC containers
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd1
vagrant@ubuntu-xenial:~$ ./lxd-delete.sh lxd2
```