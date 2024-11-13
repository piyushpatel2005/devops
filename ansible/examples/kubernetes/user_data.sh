#!/bin/bash
yum install git -y
cd /root/
git clone https://github.com/piyushpatel2005/devops.git
./devops/ansible/examples/kubernetes/packages.sh
mkdir -p /etc/ansible
curl https://raw.githubusercontent.com/ansible/ansible/stable-2.9/contrib/inventory/ec2.ini -o /etc/ansible/ec2.ini