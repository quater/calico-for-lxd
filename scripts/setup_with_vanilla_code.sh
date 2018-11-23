#!/bin/bash

BUILDDIR=/home/vagrant/calico-for-lxd-builds

rm -rf $BUILDDIR
mkdir -p $BUILDDIR

cd $BUILDDIR
git clone https://github.com/containernetworking/cni.git
cd $BUILDDIR/cni
git checkout v0.6.0
./build.sh

cd $BUILDDIR
git clone https://github.com/projectcalico/cni-plugin.git
cd $BUILDDIR/cni-plugin
git checkout v3.3.1
make build

sudo cp $BUILDDIR/cni/bin/cnitool /usr/local/bin
sudo cp $BUILDDIR/cni-plugin/bin/amd64/* /usr/local/bin

sudo mkdir -p /etc/cni/net.d

sudo bash -c 'cat > /etc/calico/lxd-ipv4-pool.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv4-pool
spec:
  cidr: 10.1.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: true
EOF'

sudo bash -c 'cat > /etc/calico/lxd-ipv6-pool.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv6-pool
spec:
  cidr: 2001:db8:1234:1::/64
  ipipMode: Never
EOF'

sudo calicoctl create -f /etc/calico/lxd-ipv4-pool.cfg
sudo calicoctl create -f /etc/calico/lxd-ipv6-pool.cfg

sudo -E bash -c 'cat > /etc/cni/net.d/10-frontend-calico.conf <<EOF
{
    "name": "frontend",
    "cniVersion": "0.3.1",
    "type": "calico",
    "log_level": "DEBUG",
    "etcd_endpoints": "http://127.0.0.1:2379",
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "true",
        "ipv4_pools": ["lxd-ipv4-pool"],
        "ipv6_pools": ["lxd-ipv6-pool"]
    }
}
EOF'
