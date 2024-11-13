# Container concepts

`chroot` command changes root or parent root directory of process and its sub-processes. It allows to create limited view of the environment.

```shell
# Login as root
sudo su -
# Create directory for chrooted user
mkdir /home/arkham
mkdir /home/arkham/{bin,lib64}
ls /home/arkham/
# Create group for this new user
groupadd inmates
# create user named 'quinn' and add to above group
useradd -g inmates quinn
# ensure group is assigned to quinn
groups quinn
# Get 'ls' and 'bash' command inside chrooted environment for user to be able to use.
cd /home/arkham/bin/
cp /usr/bin/ls .
cp /usr/bin/bash .
# Find required libraries for these commands and bing them
ldd /bin/bash # lists required libraries
# Copy required libraries for bash command
cp -v /lib64/libselinux.so.1 /lib64/libcap.so.2 /lib64/libacl.so.1 /lib64/libc.so.6 /lib64/libpcre.so.1 /lib64/libdl.so.2 /lib64/libpthread.so.0 /home/arkham/lib64/
ldd /bin/ls
# Bring only the remaining libararies for ls command
cp -v /lib64/libattr.so.1 /lib64/ld-linux-x86-64.so.2 /lib64/libtinfo.so.5 /home/arkham/lib64/
cd ../
# create escape.txt to check if cat can run
echo "hello" > escape.txt
chroot /home/arkham/ /bin/bash
# Now we're in chrooted environment
ls # works
pwd # works
cat escape.txt # doesn't work
exit
# Enable ssh configuration for this user to chrooted directory
vim /etc/ssh/sshd_config
```

Enter following configurations at the end.

```
match group inmates
      ChrootDirectory /home/arkham/
      X11Forwarding no
      AllowTcpForwarding no
```

```shell
# Restart SSHD service
systemctl restart sshd
# set password for quinn
passwd quinn
exit
ssh quinn@hostname # should work now.
exit
```

There are currently six Linux namespaces; although cgroups could be considered seventh. They are User, IPC, UTS, Mount, PID, Network. A Linux namespace limits the ability to see the system resource whereas cgroup limits the ability of a process to access the resource. User namespace can be nested. A process running inside container can appear as another PID inside host. IPC namespace isolates system resources from a process, while giving processes created in an IPC namespace visibility to each other allowing interprocess communication. The UTS (unix timesharing) namespace allows a single system to appear to have a different host and domain names to different process. The Mount namespace controls the mountpoints that are visible to each container. The PID namespace provides processes with an independent set of process IDs. The network namespace allows all containers to have their own network stack. Network namespaces have their own networking rules. Following snippet will show how we can add network rules to accept traffic in container and it won't affect host environment

```shell
cat /etc/issue # Using Ubuntu 16.04.6 LTS
# Add network namespace named sample1
sudo ip netns add sample1
# ensure network namespace was created
sudo ip netns list
# List IP table rules
sudo iptables -L
# check network namespace sample1 IP table rules, they will be same at this time
sudo ip netns exec sample1 iptables -L
# Open bash for network namespace 'sample1'
sudo ip netns exec sample1 bash
iptables -L # without sudo works
# Add a new rule to accept TCP traffic on port 80
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -L # new rule was added
exit
# Check rules for host namespace
sudo iptables -L # was not added to host namespace
```

Control groups are abbreviated as cgroups. They isolate process's ability to access resources. cgroups allow each process to have its own hierarchy means one process can live in several trees.

Type 1 Hypervisor runs on Bare-metal servers whereas Type2 Hypervisor runs on host operating system and gues OS runs on Type2 software based hypervisor.

**LXC/LXD containers** can be created using `lxc` command.

```shell
# Check version of Ubuntu
cat /etc/issue # Ubuntu 16.04
sudo apt install lxd lxd-client # install LXD daemon
# Initialize LXD process
sudo lxd init
# Launch ubuntu container
sudo lxd launch ubuntu:16.04 # gives image a random name
# List containers
sudo lxc list
# Rename a image to something else
sudo lxc launch ubuntu:16.04 my-ubuntu
sudo lxc launch images:alpine/3.9 my-alpine
# Open interactive session
sudo lxc exec my-ubuntu -- /bin/bash
# See the list of remote repositories
sudo lxc remote list
# see other options to list images
lxc images
```

