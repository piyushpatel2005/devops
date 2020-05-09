# Kubernetes Installation on CentOS

```shell
# Run on all nodes of cluster
# Login as root
sudo su -
# Disable SE Linux on all machines (DO NOT DO IN PRODUCTION)
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
# Enable 'br_netfilter' module for cluster communication
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
# Disable swap to prevent memory allocation issues
swapoff -a
# vim /etc/fstab.orig -> Comment out the swap line
# Install Docker prerequisites
yum install -y yum-utils device-mapper-persistent-data lvm2
# Add Docker repo and install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
# Configure Docker Cgroup Driver to systemd, enable and start Docker
sed -i '/^ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/' /usr/lib/systemd/system/docker.service 
systemctl daemon-reload
systemctl enable docker --now 
systemctl status docker
docker info | grep -i cgroup
# Add the Kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
      https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# Install Kubernetes
yum install -y kubelet kubeadm kubectl
# Enable Kubernetes. Kubernetes service will not start until you run kubeadm init
systemctl enable kubelet

## Run only on MASTER node
# Initialize the cluster using IP range from Flannel
kubeadm init --pod-network-cidr=10.244.0.0/16
# Copy `kubeadmin join` command at the end
# kubeadm join 172.31.34.4:6443 --token aq0949.ju95bs73v3cs4mas \
# --discovery-token-ca-cert-hash sha256:4c8e6093779d0f3dd4b1fe8c00f9d51344ab4a6d54ab16934a63aae3f01c8890
kubeadm join 172.31.34.4:6443 --token aq0949.ju95bs73v3cs4mas \
    --discovery-token-ca-cert-hash sha256:4c8e6093779d0f3dd4b1fe8c00f9d51344ab4a6d54ab16934a63aae3f01c8890
# Exit `sudo` and run the following
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Deploy Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# Check cluster state
kubectl get pods --all-namespaces

## Run following on nodes only
# Run the `join` command that we copied earlier as sudo, then check nodes from master
kubectl get nodes
```

## Installation on Ubuntu

```shell
## Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu
sudo apt-mark hold docker-ce
sudo docker version
## Install Kubernetes components Kubeadm, kubelet and Kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=1.12.7-00 kubeadm=1.12.7-00 kubectl=1.12.7-00
sudo apt-mark hold kubelet kubeadm kubectl
kubeadm version
# On kuberenetes master node, initialize cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
# copy kubectl join command at the end, which will be used on worker nodes
kubeadm join 172.31.38.6:6443 --token bysdlu.55std6jmr6u5690m --discovery-token-ca-cert-hash sha256:3e37686f93bff9975dddf79e6e2edd6fb57a1ebbe92cf10ab93f86cc4597dd7a
# setup local kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Verify the cluster is responsive
kubectl version # You should get Server version as well as Client Version
# Run kubectl join command from earlier commands output as sudo
# Verify on master node that all nodes have joined. They should appear as NotReady state.
kubectl get nodes
## Setup cluster networking using Flannel
# On all nodes, run following
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
# Install Flannel in the cluster by running this on Master node
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
# Verify that all nodes now have a STATUS of Ready
kubectl get nodes
# Verify that the Flannel pods are up and running.
kubectl get pods -n kube-system
```


## Install on AWS

```shell
# Install awscli 
sudo apt-get update && sudo apt-get awscli
# Configure AWS CLI to access ID and secret key
aws configure
# Download and install Amazon EKS cli
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$9uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin/
# Verify its version and make sure it is installed
eksctl version
# Download and install Kubernets operations tools `kops`
curl -L0 https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/release/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x kops-linux-amd64 && sudo mv kops-linux-amd64 /usr/local/bin/kops
# Verify the version of kops
kops version
# Download and install Kubernetes CLI kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl
# Verify kubectl installation
kubectl version --short
# Create a domain for your cluster, for example k8s.containerized.me
aws route53 create-hosted-zone --name k8s.containerized.me \
  --caller-reference k8s-devops-cookbook \
  --hosted-zone-config Comment="Hosted Zone for my K8s cluster"
# Create an S3 bucket to store Kuberenetes configuration and state of the cluster, for example s3.k8s.containerized.me as s3 bucket name
aws s3api create-bucket --bucket s3.k8s.containerized.me \
  --region us-east-1
# Confirms S3 bucket created
aws s3 ls 
# enable bucket versioning
aws s3api put-bucket-versioning --bucket s3.k8s.containerized.me \
  --versioning-configuration Status=Enabled
# Set environmental parameters for kops 
export KOPS_CLUSTER_NAME=useast1.k8s.containerized.me
export KOPS_STATE_STORE=s3://s3.k8s.containerized.me
# Create SSH key 
ssh-keygen -t rsa
# Create the cluster configuration with the list of ones where you want master nodes to run
kops create cluster --node-count=6 --node-size=t3.large \
  --zones=us-east-1a,us-east-1b,us-east-1c \
  --master-size=t3.large \
  --master-zones=us-east-1a,us-east-1b,us-east-1c
# Create cluster
kops update cluster --name ${KOPS_CLUSTER_NAME} --yes
# After couple of minutes verify
kops validate cluster
# Run cluster-info command to manage cluster
kubectl cluster-info
```

By default, `kops` creates and exports the Kubernetes configuration `~/.kube/config`.

```shell
# Create a cluster using default settings
eksctl create cluster # by default m5.large instances
# Confirm cluster information and workers
kubectl cluster-info && kubectl get nodes
```

`aws-shell` works with AWS CLI and improves productivity with autocomplete feature.

```shell
# Install aws-shell
sudo apt-get install aws-shell && aws-shell
# Delete cluster
kops delete cluster --name ${KOPS_CLUSTER_NAME} --yes
```

# Configuring Kubernetes cluster on MS Azure

```shell
# Install required dependencies
sudo apt-get update && sudo apt-get install -y libssl-dev \
  libffi-dev python-dev build-essential
# Download az CLI tool
curl -L https://aka.ms/InstallAzureCli | bash
# verify 'az' version
az --version
# Install `kubectl` 
az aks install-cli
# Managed Kubernetes cluster on AKS
# Login to your account
az login
# Create resource group name k8sdevops
az group create --name k8sdevops --location eastus
# Create service principal and take note of appId and password
az ad sp create-for-rbac --skip-assignment
# Create a cluster. Replace appId and password with output from preceding command.
az aks create --resource-group k8sdevops \
  --name AKSCluster \
  --kubernetes-version 1.15.4 \
  --node-vm-size Standard_DS2_v2 \
  --node-count 3 \
  --service-principal <appId> \
  --client-secret <password> \
  --generate-ssh-keys
# Gather credentials and configure kubectl 
az aks get-credentials --resource-group k8sdevops --name AKSCluster
# verify Kubernetes cluster
kubectl get nodes # 3 node cluster should be running
# Delete your cluster
az aks delete --resource-group k8sdevops --name AKSCluster
# To start kubernetes dashboard
az aks browse --resource-group k8sdevops --name AKSCluster
# If cluster ir RBAC-enabled, create ClusterRoleBinding
kubectl create clusterrolebinding kubernetes-dashboard \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:kubernetes-dashboard
# Open browser and go to address where proxy is running https://127.0.0.1:8001/
```