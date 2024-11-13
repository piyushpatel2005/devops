# Ansible Quick Notes

Ansible is open-source automation platform. It's simple, efficient and powerful. It can be used for configuration management, task automation, application deployment as well as IT orchestration. Ansible is agentless and uses SSH. So, it has minimal system requirements. It is lightweight and fast to deploy. It's developed in Python and uses YAML syntax for playbooks.

To try out, launch Bastion host and connect to it.

```shell
ssh -i aws-key.pem ec2-user@<BASTION_IP>
sudo su -
yum install -y git
# clone and go to current folder where this file is located
# Run ../scripts/package.sh
# This will install python3 and ansible and configure your AWS account
. ../scripts/package.sh
python3 -m venv ansible
source ./ansible/bin/activate
pip install pip --upgrade
pip install boto
aws configure
ansible-playbook -i inventory ../examples/ec2.yml
```

In order to copy your private key, we can use S3 bucket to copy to a bucket and then we can transfer it to multiple server instances.

```shell
aws s3 mb s3://key-bucket
aws s3 cp aws-key.pem s3://key-bucket
aws s3 ls s3://key-bucket
# Coyp the private key from S3 bucket to bastion and delete it from S3
# On remote Bastion host, perform following using root user
aws s3 cp s3://key-bucket/aws-key.pem .
chmod 400 aws-key.pem
aws s3 rb --force s3://key-bucket
# Copy public key to all the hosts in your cluster
cat ~/.ssh/id_rsa.pub | ssh -i aws-key.pem centos@<PRIVATE_IP> "cat >> ~/.ssh/authorized_keys"
# Verify password-less connection from Bastion host to other servers
# Create 'hosts-new' files using private IP addresses of the hosts and verify ansible connection from bastion
ansible -m ping -i hosts-new internal -u centos
# Alternatively, in the inventory file, we can specify `ansible_user` to specify which user we should use.
# The same command can be run on all groups using 'all'
ansible -m ping -i hosts-new all -u centos
```

Ansible works against multiple managed nodes in your infrastructure at the same time, using a list or group of lists known as inventory. The default location for inventory file is `/etc/ansible/hosts`. If we want to specify custom inventory files, we can use `-i` option as `-i <inventory_file_path>`. For these inventory files, we can use YAML or `ini` format. We can also specify group of host names using a pattern. Here I have specified `webservers` group to accommodate 4 servers.

```ini
[webservers]
ww[01:04].example.com
```

We can assign different variable to hosts and use them later in playbooks. We can also group hosts and share the same variable value for all hosts in that group.

```ini
[atlanta]
host1 http_port=80
host2 http_port=3001 ansible_user=centos

[texas]
host5
host6

[texas:vars]
proxy=proxy1
var2=value2
```

**Ad-hoc commands** are task which are not executed rarely, but on all servers. These are one line commands which are executed on specified hosts. The basic structure of the command looks like `ansible [pattern] -m [module] -a "[module_options]"`. The ansible commands are idempotent so we can execute the same commands multiple times and next time, it may not execute those tasks as it was successful last time.

```shell
# Install Git on all servers under inventory file 'host' with group 'servers'
ansible -m shell -a "yum install git -y" -i host servers --become
# Verify that git is installed.
ansible all -m shell -a "rpm -qa | grep git " -i host --become
# Copy file into all remote servers under group 'servers' under inventory file 'host'
ansible servers -m copy -a "src=/etc/hosts dest=/tmp/hosts" -i host
# Ensure the files are copied using shell module
ansible all -m shell -a "cat /tmp/hosts" -i host
# Ensure a package is installed without updating it. `--become` option will make sure that command runs as root user.
ansible servers -m yum -a "name=httpd state=present" -i host --become
# Ensure a specific version of package is installed
ansible servers -m yum -a "name=httpd-2.4.42-1.amzn2.0.1.x86_64 state=present" -i host --become
# Ensure a package is at latest version
ansible servers -m yum -a "name=httpd state=latest" -i host --become
# Ensure a package is not installed
ansible servers -m yum -a "name=httpd state=present" -i host --become
# Create, manage, remove user accounts on your managed nodes with ad-hoc tasks
# If not exists, create this user with given password
ansible servers -m user -a "name=foo password=<crypted password>" -i host --become
# If exists, remove this user from all hosts under group 'servers'
ansible servers -m user -a "name=foo state=absent" -i host --become
# Find out facts. Facts are variables on remote hosts which can be used for conditional execution of tasks
ansible server -m setup -i host
# Ensure a service is started on all servers
ansible servers -m service -a "name=httpd state=started" -i host --become
# Restart a service on all servers
ansible servers -m service -a "name=httpd state=restarted" -i host --become
# Ensure a service is stopped
ansible servers -m service -a "name=httpd state=stopped" -i host --become
```

**Playbook**s are Ansible configuration, deployment and orchestration language. Playbooks offer a repeatable, reusable, simple configuration management and multi-machine deployment system. It is composed of one or more plays in an ordered list. Each play executes part of the overall goal of the playbook, running one or more tasks. Tasks are executed in the same order as they are written in playbook. If it fails on specific task, it will give error and exit. Ideally, playbooks should be idempotent so it should run without errors. If needed, we can also execute tasks in parallel.

Playbooks can be run using `ansible-playbook playbook.yml -f 10`. We can specify how many parallel executions to run using `-f` option. Each playbook file should start with `---` as first line.

In above commands, we have used `shell`, `ec2`, `service` as few of the ansible modules. In order to list all available modules, we can use `ansible-doc -l`.
To get more information on specific module, use `ansible-doc <module_name>`.

```shell
ansible-doc -l
ansible-doc ec2
```

```shell
ansible-playbook flaskapp.yml --syntax-check -i hosts-new
ansible-playbook -v flaskapp.yml -i hosts-new
# List hosts for a playbook
ansible-playbook flaskapp.yml -i host --list-hosts
# List all the tasks in playbook
ansible-playbook flaskapp.yml -i host --list-tasks
# Verify the actions which will be performed by the playbook
ansible-playbook -v flaskapp.yml -i hosts-new --check
```

**Handlers** are tasks that only run when modified. Each hanlder should have a globally unique name. They run after all the tasks in a particular play have been completed. For example, if we change any of configuration of SSH service and we want to restart after that config is copied, then we can notify handler to restart the service and it will restart only when those file copy tasks have been executed. Handlers are dependent on execution of the associated task.

```yml
- name: copy configuration file
  template:
    src: template.j2
    dest: /etc/somewhere
  notify:
    - restart memcached
    - restart apache
  handlers:
    - name: restart memcached
      service:
        name: memcached
        state: restarted
    - name: restart apache
      service:
        name: apache
        state: restarted
```

## Configuration Management

When we install Ansible, it comes with its default configuration file. The default location is `/etc/ansible/ansible.cfg`. It will read configuration file first in current working directory, then in home directory and finally in it's default location `/etc/ansible`.

```shell
# check which configuration file is used by ansible
ansible -v -m shell -a "ls" all
# Check which host file is used by ansible
grep inventory /etc/ansible/ansible.cfg | grep =
# We can edit and change configuration file or edit the location of inventory file
```

Basically different hosts need different types of configuration parameters. In order to manage those, organize configuration file and inventory file in different directory structure (let's say for webservers, dbservers each directory contains `ansible.cfg` along with its `inventory` file.).

## Roles

Ansible role is independent component which allows reuse of common configuration steps and has to be used within playbook. It is a set of tasks to configure a host to serve a cetrain purpose like configuring a service. They are defined using YAML files with a predefined directory structure. Ansible Roles are similar to modules in Puppet and cookbooks in Chef. The directory structure for Roles look like below.

```
deploy-flaskapp
|--default        : variables in default have the lowest priority so they are easy to override
  |--main.yml
|--files          : contains files which we want to be copied to the remote host.
|--handlers       : task with handlers can be invoked by 'notify' directives and are associated with service.
  |--main.yml
|--meta           : contains information about the author, supported platforms, dependencies, etc.
  |--main.yml
|--README.md
|--tasks          : contains the main list of steps to be executed by the role.
  |--main.yml
|--templates      : contains Jinja2 template which supports modifications from the role.
|--tests
  |--inventory
  |--test.yml
|--vars           : variables in vars have higher priority than those in default directory
  |--main.yml
```

If any of the directory is used, it must contain `main.yml` file which would contain relevant ansible code. The default role location is specified in configuration file `ansible.cfg` using `roles_path` value.

```
roles_path = ~/.ansible/roles:/etc/ansible/roles
```

Here, we have specified two locations for roles. Roles will be looked up from last location to first. So, it will first look for given role in `/etc/ansible/roles` and then into `~/.ansible/roles` location. Ansible allows all ansible users to share ansible code using Roles to general users. All the code is hosted on individual repository on Github. Ansible Galaxy provides this organized Roles from open-source community. Ansible also provides `ansible-galaxy` tool to download publicly available Ansible Roles.

```shell
ansible-galaxy install nginxinc.nginx
```

This will install the `nginxinc.nginx` role in default Ansible roles location. In order to use this role, we can create a playbook.

```yml
---
- hosts: nginx-servers
  become: true
  roles:
    - nginxinc.nginx
```

Once this file is created as `install-nginx.yml` file, we can use this playbook to install nginx server on all hosts.

```shell
ansible-playbook -i nginx-hosts install-nginx.yml -u centos
```

### Create Role

```shell
# Initialize Role directory
ansible-galaxy init deploy-flaskapp
cd deploy-flaskapp/task
```

Create new file `main.yml` with following content

```yml
- import_tasks: install.yml
- import_tasks: service.yml
- import_tasks: dep-flaskapp.yml
```

```yml
---
# install.yml
  - name: Install docker
    yum: name=docker state=latest
```

```yml
---
# service.yml
  - name: Start Docker service
    service: name=docker state=started
```

```yml
---
# dep-flaskapp.yml
  - name: Start Flask app on port 80
    shell:
      cmd: docker run -dit -p 80:4080 <username>/flaskapp:v1.0
```

Finally, we create a playbook `deploy-flaskapp.yml` to launch app.

```yml
---
- hosts: all
  become: true
  roles:
    - deploy-flaskapp
```

Finally, run this playbook using `ansible-playbook deploy-flaskapp.yml -i hosts -u centos`.

Ansible playbook hold sensitive data which needs protection. It includes security information like passwords, keys, users, configuration, etc. **Ansible Vault** is utility to encrypt playbook. Once encrypted, that playbook can only be read after providing valid vault password. Here are some of the actions we can perform using vault.

- `create`: Create new vault encrypted file
- `decrypt`: Decrypt vault encrypted file
- `edit`: Edit vault encrypted file
- `view`: View vault encrypted file
- `encrypt`: Encrypt YAML file
- `encrypt_string`: Encrypt a string
- `rekey`: Re-key a vault encrypted file

Playbook encryption uses AES256 big encryption.

```shell
# Encrypt a playbook. This will ask for a password to encrypt the file
ansible-vault encrypt flaskapp.yaml
# Now reading this file will give random characters.
head -n 5 flaskapp.yaml
# Decrypt the file. This will also ask for the password which was provided while encrypting. After decrypting, the file is readable.
ansible-vault decrypt flaskapp.yaml
# Run encrypted playbook. This will prompt for password
ansible-playbook flaskapp.yaml --ask-vault-pass
# To run encrypted playbook using automation, a vault-password file is created and its path is passed when running playbook
ansible-playbook flaskapp.yaml --vault-password-file vault-pass
```

# Kubernetes Deployment using Ansible

```shell
# Start Bastion host
cd ../examples/kubernetes
./start-bastion.sh

# Connect to Bastion Host, get all these files from ../examples/kubernetes folder.
# Install ansible on Bastion host and configure AWS. This command will ask you to run few commands at the end of execution.
./packages.sh

# Create infrastructure with 1 master and 1 worker nodes. Make sure to modify variables (image, region, subnet) in the file.
ansible-playbook -i inventory create-infra.yml

# Prepare hosts file to copy to all nodes.
ansible -i ec2-k8.py worker --list | grep -v hosts | awk '{print $1 " worker"}' > files/hosts
ansible -i ec2-k8.py master --list | grep -v hosts | awk '{print $1 " master"}' >> files/hosts

# Add hosts into distribute-key.yml file
ansible -i ec2-k8.py  master --list | grep -v hosts | head -1 | awk '{print "       - "$1}' >> distribute-key.yml
ansible -i ec2-k8.py  worker --list | grep -v hosts | head -1 | awk '{print "       - "$1}' >> distribute-key.yml

# Distribute keys on remote hosts
ansible-playbook -i inventory  distribute-key.yml

# Get the IP address of the master
export KUBE_API_SERVER_IP=`ansible -i ec2-k8.py  master --list | grep -v hosts | head -1 | awk '{print $1}'`

# Update add-node-ubuntu.yml file with KUBE_API_SERVER IP address
sed -ir "s/kube_api_server: ChangeMe/kube_api_server: ${KUBE_API_SERVER_IP}/g" deploy-k8-ubuntu.yml
sed -ir "s/kube_api_server: ChangeMe/kube_api_server: ${KUBE_API_SERVER_IP}/g" add-node-ubuntu.yml

# Verify the network connection using ping
ansible -m ping -i ec2-k8.py master
ansible -m ping -i ec2-k8.py worker

# Prepare host for K8 deployment
ansible-playbook -i ec2-k8.py configue-ubuntu-infra.yml

# Deploy K8 cluster on master node
ansible-playbook -v -i ec2-k8.py deploy-k8-ubuntu.yml
# As a result of first task, you will get the command to run on other nodes in order to join Kubernetes cluster. Copy that command as token and discovery token will be used in add-node-ubuntu.yml file.

# Verify if Control plane is running fine
ansible -m shell -a "kubectl get no" -i ec2-k8.py master --become

# Copy token and discovery token into add-node-ubuntu.yml file manually.

# Run add node playbook to add other nodes
ansible-playboook -i ec2-k8.py add-node-ubuntu.yml
ansible -m shell -a "kubectl get no" -i ec2-k8.py master --become

# Run an app on pod. This cannot be accessed directly from outside kubernetes network
kubectl apply -f flask-app.yml

# Expose NodePort for service access
kubectl expose deployment flask-app --port=4080 --protocol=TCP --type=NodePort --name=my-service

# Get service port exposed
kubectl get svc

# Try to access http://<PUBLIC_IP>:<SVC_PORT>
```

```shell
kubectl get pods
kubectl get nodes --all-namespaces
kubectl get pods -o wide --all-namespaces
```


