#ACTUALIZAMOS PAQUETES
sudo yum update && sudo yum upgrade -y
#INSTALACION DE TODA LA PAQUETERIA NECESARIA:
sudo yum install ca-certificates curl gnupg2 git vim golang sudo rsync conntrack container-selinux ebtables ethtool iptables socat runc -y

echo "127.0.0.1   $HOSTNAME" >> /etc/hosts
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=6443/udp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10250/udp

#----------------------------------QUITAMOS MEMORIA SWAP
#vim /etc/fstab
sudo swapoff -a 
#free -m
#--------------------------------------ACTIVAMOS MODULOS
# Enable kernel modules
sudo modprobe br_netfilter
# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sudo sysctl --system
#----------------------------------------- INSTALACION DE CRI-O Y KUBERNETES
KUBERNETES_VERSION=v1.32
CRIO_VERSION=v1.32
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF
cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF

sudo yum update
sudo yum install cri-o cri-tools container-selinux kubelet kubeadm kubectl -y
sudo yum install containernetworking-plugins -y

sudo systemctl start crio
sudo systemctl start kubelet
sudo systemctl enable crio
sudo systemctl enable kubelet

#sudo vim /etc/crio/crio.conf

#EN EL ARCHIVO /etc/crio/crio.conf
#MODIFICAMOS O AÑADIMOS:

#[crio.runtime]
#conmon_cgroup = "pod"
#cgroup_manager = "systemd"

#[crio.image]
#pause_image="registry.k8s.io/pause:3.10"

sudo systemctl restart crio
sudo systemctl restart kubelet
sudo systemctl status crio
#COMPROBACIONES DE CRI-O
#crictl --runtime-endpoint unix:///var/run/crio/crio.sock version
#crictl info
#crictl completion > /etc/bash_completion.d/crictl
#------------------------------------------PREPARAMOS EL CLUSTER DEL SERVIDO DE KUBERNETES
sudo kubeadm config images pull

