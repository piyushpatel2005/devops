# Docker Compose

Compose is a tool for defining, launching and managing services, where a service is defined as one or more replicas of a Docker container. Services and systems of services are defined in YAML files and managed with `docker-compose`. With Docker compose, we can
- build docker images
- launch containerized applications as services
- launch full systems of services
- manage the state of individual services in a system
- scale services up or down
- view logs for cllection of containers making a service

Compose file might describe many serivces that are interrelated but should maintain isolation and may scale independently.

```shell
apt install docker-compose
docker --version
```

To on-board a new team member we can use docker-comopse to create development environment. Now go to that directory and run following.

```shell
cd example-dockerfiles/wp-example;
docker-compose up
docker ps
docker-compose ps
```

Once both docker images are pulled and started, you should be able to launch `http://localhost:8080/`. With Compose, it's very simple to get up and running with complete development stack with web server, database, cache, etc. `docker-compose ps` shows list of containers that are defined by the yaml file. Compose has `rm` that's similar to docker remove command. To clean up the environment, use one the two commands.

```shell
docker-compose stop # OR
docker-compose kill
docker-compose rm -v # This will list the cotnainers that are going to be removed.
```

```shell
git clone http://github.com/dockerinaction/ch11_notifications.git
cd ch11_notifications;
docker-compose up -d # -d for detached mode
```

Above commands would spin up Elastic search which looks for events. If you need to access the data, we can use the `docker logs` command for specific container. Instead, we can also use `docker-compose logs` command to get the aggregated log stream for all the container. If you want to see only one or more services, then we can use `docker-compose logs pump elasticsearch`.

If you want to bind another service on port 3000, it would conflict with `calaca` service. That could be easily done by changing `3000:3000` to `3001:3000` and save the file and run `docker-compose` again. If the sources for services change, we can rebuild one or all of services using `docker-compose build`. To rebuild only one or some of subset of services, use `docker-compose build calaca pump`. To stop and remove the containers, use 

```shell
docker-compose stop
docker-compose rm -vf
```

```shell
git clone https://github.com/dockerinaction/ch11_coffee_api.git
cd ch11_coffee_api;
docker-compose build
```

When Docker compose starts any particular service, it will start all the services in the dependency change for that service. Compose will make sure that it comes up with all dependencies attached. If Compose detects any services that haven't been built or services that use missing images, it will trigger a build or fetch the appropriate image. We can start or restart a service without its dependencies using `--no-dep` flag.

We can scale services up or down. When we do so, compose creates more replicas of the containers providing the service. These replicas are automatically cleaned up when we scale down. We can check parallelism in Docker using `docker-compose ps` command. Let's say if we want to increase the parallelism of `coffee` service, we run `docker-compose ps coffee`.

To scale up this service, use `docker-compose scale coffee=5`. This will create 5 parallel running services. Similarly to scale down this service, use `docker-compose scale coffee=1`.

Compose makes working with managed volumes trivial in iterative environments. When a service is rebuilt, the attached managed volumes are not removed. Instead they are reattached to the replacing containers for that service.

Docker builds container links by creating firewall rules and injecting service discovery information into the dependent container's environment variables and `/etc/hosts` file.

### Compose YAML

Coffee service uses a Compose managed build, environment variable injection, linked dependencies and a special networking configuration. This shows example from `example-dockerfiles/ch11_coffee_api` directory.

```yaml
coffee:
  build: ./coffee # builds from Dockerfile located under ./coffee
  user: 777:777
  restart: always
  expose: # expose and map ports for containers
    - 3000
  ports:
    - "0:3000"
  links:
    - db:db
  environment: # set environment to use a database in list format
    - COFFEEFINDER_DB_URI=postgresql://postgres:development@db:5432/postgres
    - COFFEEFINDER_CONFIG=development
    - SERVICE_NAME=coffee
  labels: # label the services in dictionary format
    com.dockerinaction.chapter: "11"
    com.dockerinaction.example: "Coffee API"
    com.dockerinaction.role: "Application Logic"
```

The value of `build` key is directory location of the Dockerfile to use for a build. We can also provide an alternative Dockerfile name using `dockerfile` key. Environment variables can be set for a service with the `environment` key and a nested list or dictionary of key-value pairs. Alternatively you can provide one or many files containing environment variable definitions with the `env_file` key. Container metadata can be set with a nested list or dictionary for the `labels` key. The `expose` key takes a list of container ports that should be exposed by firewall rules. The `ports` key accepts a list of strings that describe port mappings in the same format accepted by `-p` option on `docker run` command. The `links` command accepts a list of link definitions.

The `image` key helps get specific image.

```yaml
db:
  image: postgres
  volumes_from:
    - dbstate
  environment:
    - PGDATA=/var/lib/postgresql/data/pgdata
    - POSTGRES_PASSWORD=development
  labels:
    com.dockerinaction.chapter: "11"
    com.dockerinaction.example: "Coffee API"
    com.dockerinaction.role: "Database"

proxy:
  image: nginx
  restart: always
  volumes:
    - ./proxy/app.conf:/etc/nginx/conf.d/app.conf
  ports:
    - "8080:8080"
  links:
    - coffee
  labels:
    com.dockerinaction.chapter: "11"
    com.dockerinaction.example: "Coffee API"
    com.dockerinaction.role: "Load Balancer"
```

The proxy uses a volume to bind-mount a local configuration file into the NGINX configuration location using `volumes` key. The db service uses `volumes_from` key to list services that define required volumes.

```yaml
data:
  image: gliderlabs/alpine
  command: echo Data Container
  user: 999:999
  labels:
    com.dockerinaction.chapter: "11"
    com.dockerinaction.example: "Coffee API"
    com.dockerinaction.role: "Volume Container"

dbstate:
  extends:
    file: docker-compose.yml
    service: data
  volumes:
    - /var/lib/postgresql/data/pgdata
```

The data service only defines sensible defaults for a volume container. The dbstate service uses `extends` key to specify that it extends data service. It needs to specify both the file and service name being extended. The child is a new container built from the freshly generated layer. the `volumes` key accepts a list of volume specifications allows by the `docker run -v` flag. Docker compose can be used for forensic and automated testing.

## Docker Machine and Swarm

Docket Machine and Docker Swarm help system administrators and infrastructure engineers extend those abstractions into clustered environments.

### Docker Machine

Docker Machine can create and tear down whole fleets of Docker enabled hosts in a matter of seconds. It ships with a number of drivers and each driver integrates Docker Machine with a different virtual machine technology or cloud-based virtual computing provider. If you use a cloud provider for these services, you'll need to configure environment with provider-specific information as well as  driver-specific flags in any commands. We can get driver-specific flags by `docker machine help create` command.

```shell
docker-machine help
# Create three virtual machines
docker-machine create --driver virtualbox host1
docker-machine create --driver virtualbox host2
docker-machine create --driver virtualbox host3
```

Docker Machine tracks these machines with a set of files in `~/.docker/machine/`. They describe hosts you've created. Docker Machine can be used to list, inspect and upgrade.

```shell
docker-machine ls
docker-machine inspect host1 # JSON document describing the machine
docker-machine inspect --format "{{.Driver.IPAddress}}" host1 # only IP address
docker-machine upgrade host3 # upgrade managed machine host3
```

When you create or register a machine with Docker Machine, it creates or imports an SSH private key file. That private key can be used to authenticate as a privileged user on the machine over SSH. The `docker-machine ssh` will authenticate with target machine and bind terminal to a shell on the machine.

```shell
docker-machine ssh host1 # ssh to host1 machine
touch sample
exit # exit from host1
```

The same can be done using `docker-machine ssh host1 "echo spot > sample"`

```shell
docker-machine scp host1:sample host2:sample
docker-machine ssh host2 "cat sample"
```

```shell
docker-machine stop host2
docker-machine kill host3
docker-machine start host2
docker-machine rm host1 host2 host3
```

Docker Machine accounts for and tracks the state of the machines it manages. Docker Machine is used to produce environment configuration for an active Docker host.

```shell
docker-machine create --driver virtualbox machine1
docker-machine create --driver virtualbox machine2
docker machine env machine1 # Let env autodetect your shell environment
docker-machine env --shell powershell machine1 # get PowerShell configuration (specified using shell flag)
docker-machine env --shell cmd machine1 # get CMD configuration
docker-machine env --shell bash machine1 # get dfeault configuration (POSIX)
```

To set machine1 as active machine, execute `eval "$(docker-machine env machine1)"`. If you use Windows and run PowerShell, you can run as `docker-machine env --shell=powershell machine1 | Invoke-Expresssion`. We can see whether a machine is active or not using `docker-machine active`.

### Docker Swarm

It used to be the case where we used to deploy different pieces of software to different machines. A Swarm cluster is made up of two types of machines. A machine running Swarm in management mode is called a manager. A machine that runs a Swarm agent is called a node. These programs need no special installation or privileged access to the machines. They run in Docker containers. Docker Machine can provision Swarm clusters as easily as standalone Docker machines. The `--swarm` flag indicates that the machine being reated should run the Swarm agent software and join a cluster. The `--swarm-master` will instruct Docker Machine to configure new machine as a Swarm manager. The `--swarm-discovery` takes an additional argument that specifies the unique ID of the cluster which is used to identify the cluster a machine is joining.

Docker Swarm agent on each node communicates with a Swarm discovery subsystem to advertise its membership in a cluster identified by `token://12341234`. Single machine running the Swarm manager polls the Swarm discovery subsystem for an updated list of nodes in the cluster.

To create your own Swarm cluster, first create a cluster identifier. By default, Swarm uses a free and hosted solution provided on Docker Hub.

```shell
# Create a new cluster identifier
docker-machine create --driver virtualbox local
eval "$(docker-machine env local)" 
docker run --rm swarm create
# Copy the resulting value and substitute for <TOKEN> in the next three commands.
# Create a three-node Swarm cluster using virtual machines
# --swarm-master parameter to indicate that the machine being create should manage the new Swarm cluster
docker-machin create --driver virtualbox \
    --swarm --swarm-discovery token://<TOKEN> \
    --swarm-master machine0-manager
docker-machine create --driver virtualbox \
    --swarm --swarm-discovery token://<TOKEN> \
    machine1
docker-machine create --driver virtualbox \
    --swarm --swarm-discovery token://<TOKEN> \
    machine2
docker-machine ls
```