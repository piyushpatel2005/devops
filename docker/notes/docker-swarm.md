# Docker Swarm

Docker swarm is container orchestration platform from Docker team. It mainly uses three ports for communication.

| Port | Protocol | Use |
|:-----|:---------:|:---|
| 2377 | TCP | Cluster control plane communications |
| 7946 | TCP and UDP | Communication between nodes |
| 4789 | UDP | Overlay network traffic |

Manager node is the one which maintains the cluster control plane. It also schedules services and detect failing services and tries to maintain a state. It serves as HTTP API response server for swarm node. For high availability and fault tolerance, at least 3 master are recommended. Manager nodes implement the Raft Consensus Algorithm to manage the global cluster state. If we have `n` manager cluster, it can tolerate the loss of at most `(n - 1) / 2` managers.

### Node Setup

0. Install Docker machine

```shell
base=https://github.com/docker/machine/releases/download/v0.16.0 &&
curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
sudo mv /tmp/docker-machine /usr/local/bin/docker-machine &&
chmod +x /usr/local/bin/docker-machine
```

1. Install Docker
2. Set hostname

```shell
sudo hostnamectl set-hostname --static <HOSTNAME>
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
sudo reboot
```

3. Connect to manager node (At the moment any node) and initialize the swarm.

```shell
ssh -i <aws-key.pem> centos@<public_ip>
sudo su -
docker swarm init --advertise-addr <MANAGER_PRIVATE_IP>
# Above command will create a token and post it, so make sure to copy it.
# This is required to be run on worker nodes.
```

4. Connect to worker nodes  and join it to swarm using above command.

```shell
ssh -i awk-key.pem centos@<public_ip>
sudo su -
docker swarm join --token <generated_token> <master_ip>:2377
```

5. Connect o master node and check node added.

```shell
docker node ls
```

To get the command to join docker swarm, you can get that from master node by running below command.

```shell
docker swarm join-token worker
```

6. Join other nodes as needed.

To leave a worker node, run `docker swarm leave` from that worker node. This node will appear as `Down` from Swarm master node. If we want to remove that node from `docker node ls` output, we can execute `docker node rm <node_id>` from manager node.

To automate, Swarm cluster creating, we can use Bash scripting using AWS CLI. Usually, production environment uses Bastion host to connect to the environment.

1. Launch Bastion Host with default configuration. This is default AWS AMI. It comes with AWS cli preinstalled. So check `aws --version`.
2. Install Git on Bastion Host. This will allow us to clone this repo and run bash scripts.
3. After clonning, go  inside this `swarm` directory and execute `./package.sh`.
4. Configure AWS CLI using `aws configure` command.
5. Execute `./create-swarm.sh` script.
6. Once all three nodes are setup, run `docker-machine ls`
7. You can connect to leader node using `docker-machine ssh leader1`.
8. Become super user using `sudo su -` followed by `docker node ls`.

**Docker machine** is apart from Docker daemon. It can be used to provision and manage multiple remote Docker hosts, provision Swarm clusters.

```shell
# Create docker host
docker-machine create --driver amazonec2 \
    -- amazonec2-access-key <ACCESS_KEY> \
    --amazonec2-secret-key <SECRET_KEY> \
    --amazonec2-region eu-west-2 <NAME_OF_MACHINE>
# With aws configure already setup, the command can be simplied to
docker-machine create --driver amazonec2 <NAME_OF_MACHINE>
# See all machines
docker-machine ls
# Connect to specific machine
docker-machine ssh <NAME_OF_MACHINE>
# Get local environment variable which allow to run docker command on remote host
docker-machine env leader1
# Set shell env for leader1 machine and run command to get worker token
# This command also helps to run docker swarm commands from Bastion host. Ideally you should be connected to master node, but with this command, it is possible to run commands from Bastion host.
eval $(docker-machine env leader1)
docker swarm join-token worker
# Inspect list details of machine
docker inspect leader1
# Exact machine IP from output of docker inspect
docker inspect --format='{{.ManagerStatus.Addr}}' leader1
```

To **deploy docker services**, we can use following steps from master-node.

```shell
sudo su -
# Check docker machines configured
docker-machine ls
# connect to manager node
docker machine ssh leader1
# Check docker nodes
docker node ls
# Create docker service
docker service create --replicas 1 --name devops-webappp -p 80:4080 <username>/flaskapp:v1.0
# check running service
docker service ls
# We can access our service from any of the workers of the docker service.
# Check where this service is running. Which node is running a container for this service.
docker service ps devops-webapp
# Connect to that specific docker node
docker machine ssh <node>
# Kill the service
docker ps
docker kill <container_id>
# It will relaunch the container and after few seconds, it will again be available
docker node ls
# Scenario 2: Kill Node. First, Launch service on specific node
docker service create --replicas=1 --constraint node.labels.type=worker --name devops-webapp -p 80:4080 <username>/flaskapp:v1.0
# Verify the service is running on the worker node
docker service ps devops-webapp
# Verify service is running and then terminate the node from EC2 console.
# After few seconds, it would have spawn the same service container on another worker node.
docker service ps devops-webapp
# Inspect running docker service
docker service inspect --pretty devops-webapp
# Scale service to 4 instances; Containers running as part of service are called tasks
docker servie scale devops-webapp=4
# Check scaled services
docker service ls
# Check which nodes
docker service ps devops-webapp
# Reduce the replicas
docker service scale devops-webapp=2
# Delete service
docker service rm devops-webapp
```

If we want to perform **rolling update**, that's possible with Docker swarm. In this case, on every node which is running service task, docker container with old image will be stopped and new container is started with updated image. By default, update is performed in sequential order. If task fails to update, it is paused.

```shell
# Perform the rolling update of our service
docker service update --image=<username>/flaskapp:v2.0
# rollback the service update
docker service update --image=<username>/flaskapp:v1.0
```

For managing Docker swarm cluster, following commands may be useful.

```shell
# Taking node offline for maintenance. This moves services from worker1 to other nodes in swarm cluster
docker node update --availability drain worker1
# check availability
docker node inspect --pretty worker1
# Perform maintenance, increases resources and bring worker1 back in swarm cluster
# This will not move the services unless it has failed once.
# It will keep running on other nodes but new services will be scheduled on worker1.
docker node update --availability active worker1
# Add Label to manage node and create service policies
docker node update --label-add <key>=<value> <node-id>
docker node update --label-add type=worker worker2
# check label
docker inspect worker2 | grep "type"
# Remove serviec
docker service ls
docker service rm devops-webapp
# Verify shutdown
docker service ls
docker service ps devops-webapp
# Launch only on worker nodes
docker service create --replicas=4 --constraint node.labels.type=worker --name devops-webapp -p 80:4080 <username>/flaskapp:v1.0
# Promote worker node to manager node
docker node promote worker1
# Demote manager node to worker node
docker node demote worker1
# Check manager node Reachability
docker node inspect leader1 --format "{{.ManagerStatus.Reachability }}"
# Check worker1 node Status
docker node inspect worker1 --format "{{ .Status.State  }}"
# From Bastion host stop worker1 node and check status
docker-machine stop worker1
```

Deploy multiple services

```shell
git clone https://github.com/singh-ashok/example-voting-app.git
cd example-voting-app
docker stack deploy --compose-file docker-stack.yml vote
docker service ls
```