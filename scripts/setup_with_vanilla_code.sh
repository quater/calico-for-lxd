#!/bin/bash

BUILDDIR=/home/vagrant/calico-for-lxd-builds

rm -rf $BUILDDIR
mkdir -p $BUILDDIR

cd $BUILDDIR
git clone https://github.com/projectcalico/cni-plugin.git
cd $BUILDDIR/cni-plugin
git checkout v3.4.0
make build

sudo cp $BUILDDIR/cni-plugin/bin/amd64/* /usr/local/bin

export GOPATH=/home/vagrant/go/
mkdir -p $GOPATH/src/github.com/containernetworking/
cd $GOPATH/src/github.com/containernetworking/
# git clone https://github.com/containernetworking/cni.git
git clone https://github.com/quater/cni.git
cd $GOPATH/src/github.com/containernetworking/cni
# git checkout cnitool-for-lxc
git checkout master

go get golang.org/x/tools/cmd/cover
go get github.com/modocache/gover
go get github.com/mattn/goveralls
go get -t ./...
cd $GOPATH/src/github.com/containernetworking/cni/cnitool
go list | xargs -n1 go build -v -o
sudo cp github.com/containernetworking/cni/cnitool /usr/local/bin

sudo mkdir -p /etc/cni/net.d

sudo bash -c 'cat > /etc/calico/lxd-ipv4-pool-frontend.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv4-pool-frontend
spec:
  cidr: 10.1.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: true
EOF'

sudo bash -c 'cat > /etc/calico/lxd-ipv6-pool-frontend.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv6-pool-frontend
spec:
  cidr: 2001:db8:1234:1::/64
  ipipMode: Never
EOF'

sudo bash -c 'cat > /etc/calico/lxd-ipv4-pool-backend.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv4-pool-backend
spec:
  cidr: 10.3.0.0/16
  ipipMode: CrossSubnet
  natOutgoing: true
EOF'

sudo bash -c 'cat > /etc/calico/lxd-ipv6-pool-backend.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: lxd-ipv6-pool-backend
spec:
  cidr: 2001:db8:1222:1::/64
  ipipMode: Never
EOF'

sudo calicoctl create -f /etc/calico/lxd-ipv4-pool-frontend.cfg
sudo calicoctl create -f /etc/calico/lxd-ipv6-pool-frontend.cfg
sudo calicoctl create -f /etc/calico/lxd-ipv4-pool-backend.cfg
sudo calicoctl create -f /etc/calico/lxd-ipv6-pool-backend.cfg

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
        "ipv4_pools": ["lxd-ipv4-pool-frontend"],
        "ipv6_pools": ["lxd-ipv6-pool-frontend"]
    }
}
EOF'

sudo -E bash -c 'cat > /etc/cni/net.d/10-backend-calico.conf <<EOF
{
    "name": "backend",
    "cniVersion": "0.3.1",
    "type": "calico",
    "log_level": "DEBUG",
    "etcd_endpoints": "http://127.0.0.1:2379",
    "ipam": {
        "type": "calico-ipam",
        "assign_ipv4": "true",
        "assign_ipv6": "true",
        "ipv4_pools": ["lxd-ipv4-pool-backend"],
        "ipv6_pools": ["lxd-ipv6-pool-backend"]
    }
}
EOF'
