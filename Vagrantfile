# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.synced_folder ".", "/home/vagrant/shared_folder"
  config.vm.provision "shell", inline: <<-SHELL
set -e -x -u

# Install tools required for building the binaries
apt-get update -y || (sleep 40 && apt-get update -y)
apt-get install -y build-essential
snap install go --classic

# Install ECTD
apt-get install -y etcd

# Configure ECTD to start on boot
sudo systemctl enable etcd.service

# Configure Calicoctl
mkdir -p /etc/calico
cat > /etc/calico/calicoctl.cfg <<EOF
apiVersion: projectcalico.org/v3
kind: CalicoAPIConfig
metadata:
spec:
  datastoreType: "etcdv3"
  etcdEndpoints: "http://127.0.0.1:2379"
EOF

# Install Calicoctl
curl -L -o /usr/local/bin/calicoctl https://github.com/projectcalico/calicoctl/releases/download/v3.3.1/calicoctl-linux-amd64
chmod +x /usr/local/bin/calicoctl

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
usermod -aG docker vagrant

# Start and initialize Calico Node
calicoctl node run --node-image=quay.io/calico/node:v3.3.1

# Install LXD
snap install lxd
usermod -aG lxd vagrant

# Configure LXD
cat <<EOF | lxd init --preseed
config: {}
cluster: null
networks:
- config:
    ipv4.address: auto
    ipv6.address: auto
  description: " Default network"
  managed: false
  name: lxdbr0
  type: ""
storage_pools:
- config:
    size: 15GB
  description: "Default storage"
  name: default
  driver: btrfs
profiles:
- config: {}
  description: "Default profile"
  devices:
    eth0:
      name: eth0
      nictype: bridged
      parent: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
EOF

  SHELL
end
