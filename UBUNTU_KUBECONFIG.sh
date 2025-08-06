#!/bin/bash
#INSTALACION DE PAQUETERIA
sudo apt update && sudo apt -y full-upgrade && sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common git vim golang golang-go sudo rsync  -y
#QUITAMOS MEMORIA SWAP
sudo swapoff -a
#ACTIVAMOS MODULOS DE RED
sudo modprobe overlay
sudo modprobe br_netfilter
#CONFIGURAMOS KUBERNETES
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
#INSTALACION DE CRI-O

export OS=xUbuntu_22.04
export CRIO_VERSION=1.24

sudo echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
sudo echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

sudo curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -

sudo apt update
#INSTALACION DE PAQUETE CRI-O
sudo apt install cri-o cri-o-runc -y
sudo systemctl start crio
sudo systemctl enable crio
#PREPARACION DE PLUGINS
sudo apt install containernetworking-plugins -y

#EDITAMOS CONFIGURACION DE CRIO

sudo sed -i "s/# conmon_cgroup = \"\"/ conmon_cgroup = \"pod\"/" /etc/crio/crio.conf
sudo sed -i "s/# cgroup_manager = \"systemd\"/ cgroup_manager = \"systemd\"/" /etc/crio/crio.conf
sudo sed -i "s/# pause_image = \"registry.k8s.io\/pause:3.6\"/ pause_image = \"registry.k8s.io\/pause:3.6\"/" /etc/crio/crio.conf
sudo sed -i "s/# plugin_dirs = / plugin_dirs = [\"\/opt\/cni\/bin\/\", \"\/usr\/lib\/cni\/ \",] #/" /etc/crio/crio.conf

#PLUGINS DE CRI-O
git clone https://github.com/containernetworking/plugins
cd plugins
git checkout v1.1.1
./build_linux.sh
sudo mkdir -p /opt/cni/bin
sudo cp bin/* /opt/cni/bin/

#UTILIDADES DE CRI-O
sudo apt install -y cri-tools
sudo crictl --runtime-endpoint unix:///var/run/crio/crio.sock version
sudo crictl completion > /etc/bash_completion.d/crictl

#INSTALACION KUBERNETES
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull

