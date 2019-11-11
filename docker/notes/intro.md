# Docker

Docker is command-line program, background daemon, and a set of services that take a logical approach to solving common software problems and simplifying installation, runnin, publishing and removing softwares. It is open source. Without Docker, businesses typically use hardware virtualization (virtual machines) to provide isolation. They take a long time to create and require significant resource overhead because they run a whole copy of an operating system in addition to the software you want to use. Docker containers don't use hardware virtualization. Programs inside Docker containers interface directly with the host kernel.

### Installation:

```shell
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
# Give current user permission to run docker without sudo
sudo groupadd docker
sudo usermod -a -G docker $USER
docker version
```

Docker uses Linux namespaces and cgroups. The operating system is the interface between all user programs and the hardware that computer is running on. Programs running inside a container can access only their own memory and resources as scoped by the container. A **docker image** is a bundled snapshot of all the files that should be available to a program running inside a container. 

`docker run dockerinaction/hello_world`

When `docker run` command is run, docker looks for the image on this computer. Is it installed? If no, docker searches image on Docker Hub, downloads image, Image layers are installed on this computer, Docker creates a new container and starts the program.

`docker help` gives help on basic docker commands. For detailed information, we need to use command like `docker help cp`.

Let's say we want to run nginx on port 80, mailer container on port 33333 and interactive watcher container.

`docker run --detach --name web nginx:latest` 

Above command will install `nginx:latest` from Docker Hub and run the software. Docker prints unique blob characters which are unique identifier of container that was created. The `--detach`  or `-d` option started the program in the background. This type of program is called *daemon*. Similarly, a mailer waits for connections from a caller and then sends an email.

`docker run -d --name mailer dockerinaction/ch2_mailer`

Running interactive programs in Docker requires that you bind parts of your terminal to the input or output of a running container.

```shell
docker run --interactive --tty \
  --link web:web \
  --name web_test \
  busybox:latest /bin/sh
```

The `--interactive` or `-i` option keeps the standard input stream open for the container even if no terminal is attached. `--tty` option allocates a virtual terminal for the container which will allow you to pass signals to container. You will run it like a shell in an interactive container. In this case we tried to run shell program inside container.

`wget -O http://web:80/` works from this terminal. We can exit this terminal by typing `exit` command. We want to start an agent that will monitor web server and send a message with the mailer if the web server stops.

```shell
docker run -it \
  --name agent
  --link web:insideweb \
  --link mailer:insidemailer \
  dockerinaction/ch2_agent
```

When this is running, the container will test the web server every second and print a message. We can detach the terminal using `Ctrl`, `P` and `Q` key sequences. Interactive containers are useful for running software on desktop or for manual work on a server.

To list which containers are running at the moment use, `docker ps`. This will display

container ID, image used, command executed in container,  time since the container was created, duration that the container has been running, network ports exposed by container, name of the container. If by mistake any of the container has stopped, we can restart that container using its name 

```shell
docker restart web
docker restart mailer
docker restart agent
```

We can display logs for each container using `docker logs web`. It will display messages because agent is testing the website every second.

Check logs of mailer and agent as well. The `docker logs` has flag, `--follow` or `-f` that will display logs and then continue watching and updating the display with changes to the logs as they occur. To close logs, use `Ctrl+C`.

Try stopping web server and see if mailer sends a message or check the logs.

```shell
docker stop web
docker logs mailer
```

Every running program on Linux machine has a unique number called PID. A PID namespace is the set of possible numbers that identify processes. Linux provides facilities to create multiple PID namespaces and each will contain its own PID 1, 2, 3, etc. Docker creates separate PID namespace for each container.

```shell
docker run -d --name namespaceA \
  busybox:latest /bin/sh -c "sleep 30000"
docker run -d --name namespaceB \
  busybox:latest /bin/sh -c "nc -l -p 0.0.0.0:80"
docker exec namespaceA ps
docker exec namespaceB ps
```

`docker exec` can be used to run additional processes in a running container. We see separate PID listings for each of those two containers. Docker would be much less useful without PID namespace. 

If we want to start two nginx instances on the same computer, it will fail because the first one has already used the port for the server.

```shell
docker run -d --name webConflict nginx:latest
docker logs webConflict
docker exec webConflict nginx -g 'daemon off;' # this fails because of first one. port conflict
# To solve this.
docker run -d --name webA nginx:latest # start first nginx
docker logs webA # verify it's working it is empty
docker run -d --name webB nginx:latest
docker logs webB # should be empty
docker ps
```

Let's say we want to host a variable number of websites for our customers. By default Docker assigns a unique name to each container it creates. If we want to rename the name of container, we can do so using `docker rename` command.

```shell
docker rename webid webid-old
docker run -d --name webid nginx
```

When containers are started in detached mode, their identifier will be printed to the terminal. We can use these identifiers in place of the container name with any command that needs to identify specific container.

`docker exec 734f934b23 ps` or `docker stop 734f934b23`

We can get this unique identifier using following command.

```shell
CID=$(sudo docker create nginx:latest)
echo $CID
```

Docker commands provide another flag to write the ID of a new container to a known file. Docker will not create a new container using the provided CID file if that file already exists. CID 

```shell
docker create --cidfile /tmp/web.cid nginx # crete new stopped container
CID=$(docker ps --latest --quiet) # get ID of last created container
docker ps -l -q --no-trunc
```

```shell
MAILER_CID=$(docker run -d dockerinaction/ch2_mailer)
WEB_CID=$(docker create nginx)
AGENT_CID=$(docker create --link $WEB_CID:insideweb --link $MAILER_CID:insidemailer dockerinaction/ch2_agent)
```

`docker ps` only shows running containers. To see all the containers including those in the eited state, use `docker ps -a`.

```shell
docker start $WEB_CID
docker start $AGENT_CID
```

Let's say we want to make a wordpress website. If we use read-only systems, 

```shell
docker run -d --name wp --read-only wordpress:4
docker inspect --format "{{.State.Running}}" wp # will print true if container named 'wp' is running else false
docker logs wp
# Wordpress requires MySQL datbase, so install it.
docker run -d --name wpdb -e MYSQL_ROOT_PASSWORD=ch2demo mysql:5
# Create another wordpress container that is linked to this new database container
docker run -d --name wp2 --link wpdb:mysql -p 80 --read-only wordpress:4
docker inspect --format "{{.State.Running}}" wp2
docker logs wp2 # This had failed to start

# Start the container with specific volumes for read only exceptions
docker run -d --name wp3 --link wpdb:mysql -p 80 \
  -v /run/lock/apache2/ \
  -v /run/apache2/
  --read-only wordpress:4
```

**Updated script for complete system**

```shell
#!/bin/bash

SQL_CID=$(docker create -e MYSQL_ROOT_PASSWORD=ch2demo mysql:5)

docker start $SQL_CID

MAILER_CID=$(docker create dockerinaction/ch2_mailer)
docker start $MAILER_CID

WP_CID=$(docker create --link $SQL_CID:mysql -p 80 \
    -v /run/lock/apache2/ -v /run/apache2/ \
    --read-only wordpress:4)

docker start $WP_CID

AGENT_CID=$(docker create --link $WP_CID:insideweb \
    --link $MAILER_CID:insidemailer \
    dockerinaction/ch2_agent)
docker start $AGENT_CID
```

For injecting environment variables, `--env` or `-e` flag can be used.

```shell
docker run --env MY_ENVIRONMENT="test env" \
    busybox:latest env # run `env` command on container to see environment variables

# Create wordpress container with some generic environment variables set
docker create \
  --env WORDPRESS_DB_HOST=<database hostname> \
  --env WORDPRESS_DB_USER=site_admin \
  --env WORDPRESS_DB_PASSWORD=password \
  wordpress:4
```

Updated script would look like below.

```shell
DB_CID=$(docker run -d -e MYSQL_ROOT_PASSWORD=ch2demo mysql:5)
MAILER_CID=$(docker run -d dockerinaction/ch2_mailer)

if [ ! -n "$CLIENT_ID" ]; then
    echo "Client ID is not set."
    exit 1
fi

# user earlier created container and add new environment variable and settings
WP_CID=$(docker create \
    --link $DB_CID:mysql \
    --name wp_$CLIENT_ID \
    -p 80 \
    -v /run/lock/apache2/ -v /run/apache2/ \
    -e WORDPRESS_DB_NAME=$CLIENT_ID \
    --read-only wordpress:4)

docker start $WP_CID

AGENT_CID=$(docker create \
    --name agent_$CLIENT_ID \
    --link $WP_CID:insideweb \
    --link $MAILER_CID:insidemailer \
    dockerinaction/ch2_agent)
docker start $AGENT_CID
```

### Durable containers

If software fails, we get notified. We can restore the container if that container has exited. When all processes in a container have exited, the container will enter the exited state. Docker container can be in one of four states: Running, Paused, Restarting and Exited. Docker provides few options for monitoring and restarting containers.

Docker provides restart policy using `--restart` flag at container-creation time. We can tell Docker to 
- Never restart (Default)
- Attempt to restart when failure is detected
- Attempt for some predetermined time to restart when a failure is detected.
- Always restart the container regardless of the condition

Docker uses an exponential backoff strategy for timing restart attempts. An exponential backoff strategy will do something like double the previous time spent waiting on each successive attempt. You can see that using:

```shell
docker run -d --name backoff-detector --restart always busybox date
docker logs -f backoff-detector
```

With such container states in restarting state, we cannot do anything that requires interactive commands. A complete strategy is to use containers that run init or supervisor processes. A supervisor process, or init process, is a program that's used to launch and maintain the state of other programs. We can use similar process inside container.  A sample LAMP stack created with `supervisord` to make sure that all the processes are kept running.

```shell
docker run -d -p 80:80 --name lamp-test tutum/lamp
docker top lamp-test # check the running processes
docker exec lamp-test ps # check running processes to find PID of apache2
docker exec lamp-test kill <apache2 PID> # kill apache2 PID
```

When `apache2` stops, the `supervisord` process will log the event and restart the process. An alternative to supervisor program is to use startup script that checks preconditions for successfully starting the contained software. We can override or set the entrypoint of a container on the command line.

`docker run --entrypoint="cat" wordpress:4 /entrypoint.sh`

Containers user hard drive space to store logs, container metadata and files that have been written to the container file system. To remove a container, we use `docker rm` command.

```shell
# clean up
docker ps -a
docker rm wp # remove stopped containers
# remove container as soon as it enters the exited state
docker run --rm --name auto-exit-test busybox:latest echo Hello World
docker ps -a
```

## Installing specific software using Docker

Docker creates containers from images. An image is a file which holds files that will be available to containers created from it and metadata about the image. This metadata contains information about relationships between images, the command history for an image, exposed ports, volume definitions and more. Images have identifiers so they could be used as a name and version for the software. They are long, unique sequences of letters and numbers. Users usually work with repositories because image identifiers are difficult to work with due to their unpredicatability.

A **repository** is named bucket of images. The name is similar to a URL. A repository's name is made up of the name of the host where the image is located, the user account that owns the image and a short name. For example, `quay.io/dockerinaction/ch3_hello_registry`. A new version of the image gets a tag assigned to it to identify it. A single image can have several tags. So, there can be same image with tags like 7-jdk, 7u71-jdk, openjdk-7, etc. To find images, we can look at Docker Hub. Docker Hub is a registry and index and is the default registry and index used by Docker. When we issue `docker pull` or `docker run` without specifying alternative registry, Docker will look for the repository on Docker Hub. Docker Hub also provides a set of official repositories that are maintained by Docker Inc. or software maintainers. These are called *libraries*.

Image authors can publish their images on Docker Hub by:
- Using the command line to push images that they built independently and on their own systems.
- Make a Dockerfile publicly available and use Docker Hub's continuous build system. Images created from these automated builds are preferred because the Dockerfile is avilable for examination prior to installing the image. These images will be marked as trusted.

For authenticating with Docker Hub registries that you control, you can use `docker login` command. We can logout using `docker logout`. We can search for repositories using `docker search` command.

Run docker in interactive session for a repository

```shell
docker run -it dockerinaction/ch3_ex2_hunt
docker rmi dockerinaction/ch3_ex2_hunt
```

**1. Alternate registries**

Using an alternate registry to download images is simple.  All we need is the address of the registry.

```shell
docker pull quay.io/dockerinaction/ch3_hello_registry:latest
docker rmi quay.iodockerinaction/ch3_hello_registry
```

**2. Images as Files**

Docker provides a command to load images into Docker from a file. If you receive image in single file, we can load file using `docker load` command. To save an image file, we can use `docker save` command. This command creates TAR archive files.

```shell
# Install an image to export
docker pull busybox:latest
# export and save an image as tar
docker save -o myfile.tar busybox:latest
docker rmi busybox # remove this image
docker images # make sure that image is not available
docker load -i myfile.tar # re-load image from tar file
```

**3. Installing from Dockerfile**

A Dockerfile is a script that describes steps for Docker to take to build a new image. These files are distributed along with software that the author wants to be put into an image. Distributing a Dockerfile is similar to distributing image files. We can build docker image using Dockerfile

```shell
# This repo contains Dockerfile file
git clone https://github.com/dockerinaction/ch3_dockerfile.git
docker build -t dia_ch3/dockerfile:latest ch3_dockerfile
```

Docker image is installed on `dia_ch3/dockerfile:latest` which is specified using `-t` option.

A **layer** is an image that's related to at least one other image. Images maintain parent/child relationships and they build from their parents and form layers. The files available to a container are the union of all the layers in the lineage of the image the container was created from. An image is named when its author tags and publishes it. A user can create aliases using the `docker tag` command. Until the image is tagged, the only way to refer to it is to use UID that was generated when the image was built. From the perspective of the container, it has exclusive copies of the files provided by the image. This is made possible with a union file system. The file system is used to create mount points on your host's file system that abstract the use of layers. The most important benefit of such layered approach is that common layers need to be installed only once. 

## Volumes

A **volume** is a mount point on the container's directory tree where a portion of the host directory tree has been mounted. Altough the union file system works for building and sharing images, volumes are useful for working with persistent or shared data. A volume is a tool for segmenting and sharing data that has a scope or life cycle that's independent of a single container. For example, web application versus log data, Data processing application versus input and output data, Web server versus static content, Products versus support tools.

Let's try using Volumes with Cassandra image. Cassandra is NoSQL database taht stores its data in files on disk. We will create single-node Cassandra cluster, create a keyspace, delete the container and recover the keyspace on a new node in another container.

```shell
docker run -d \
    --volume /var/lib/cassandra/data \ # specify volume mount point inside the container
    --name cass-shared \
    alpine echo Data container

# Inherit volume definitions from earlier container
docker run -d \
    --volumes-from cass-shared \
    --name cass1
    cassandra:2.2

# After this both containers have a volume mounted at /var/lib/cassandra/data
# Run Cassandra client tool 
docker run -it --rm \
    --link cass1:cass \
    cassandra:2.2 cqlsh cass
```

```sql
select * from system.schema_keyspaces where keyspace_name = 'docker_hello_world';
-- create keyspace
create keyspace docker_hello_world
  with replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
  };
quit
```

Now, let's remove cassandra container.

```shell
docker stop cass1
docker rm -vf cass1
```

Now, If modifications we made are persisted, the only place is the volume container.

```shell
docker run -d 
    --volumes-from cass-shared --name cass2
    cassandra:2.2

docker run -it --rm
    --link cass2:cass 
    cassandra:2.2 cqlsh cass
```

```sql
select * from system.schema_keyspaces where keyspace_name= 'docker_hello_world';
quit
```

`docker rm -vf cass2 cass-shared`

### Volume types:

There are two types of volume. Every volume is a mount point on the container directory tree to a location on the host directory tree, but the types differ in where that location is on the host. 

**Bind mount** volumes use any user-defined directory or file on the host OS. A bind mount volume are useful when the host provides some file or directory that needs to be mounted into the container directory tree at a specific point. These are useful if you want to share data that lives on your host at some known location with a specific program that runs in a container. We could use docker to work on web application and share the code with nginx server to serve the website. We could use Docker to launch the web server and bind mount the location of document into the new container at the web server's document root. For example, if we create an `~/example-docs/index.html` then we can bind that to Apache HTTP server's document root using this command.

```shell
docker run -d --name bmweb \
    -v ~/example-docs:/usr/local/apache2/htdocs \
    -p 80:80 httpd:latest
```

Visit `http://local` and we can see our page. We use `-v` option to bind absolute path on host file system to the location where it should be mounted inside the container. The path should be specified with absolute paths. This overrides the content of `/usr/local/apache2/htdocs/` by the content on the host.

Suppose you want Apache HTTP web server not to be able to change the contents of this volume to minimize the impact of attack on your website, we can mount volumes as read-only by appending `:ro` to the volume mapping. This will prevent any process inside the container from modifying the content of the volume.

```shell
docker rm -vf bmweb
docker run --name bmweb_ro \
    --volume ~/example-docs:/usr/local/apache2/htdocs/:ro
    -p 80:80 httpd:latest

# below command fails
docker run --rm -v ~/example-docs:/testspace:ro \
    alpine /bin/sh -c 'echo test > /testspace/test'
```

Finally, if we specify a host directory that doesn't exist, Docker will create it for you.

```shell
ls ~/example-docs/absent # directory doesn't exist
docker run --rm -v ~/example-docs/absent:/absent alpine:latest \
    /bin/sh -c 'mount | grep absent'
ls ~/example-docs/absent/ # directory exists now
```

We can use bind mount volumes to mount individual files. This provides flexibility to create or link resources at a level that avoids conflict with other resources. The important thing in this case its that the file must exist on the host before you create the container otherwise Docker will assume that you wanted to use a directory.

However, such mounts create an opportunity for conflict with other containers. For example, if multiple instances of Cassandra use the same host location as a volume, then each of the instances would compete for the same set of files. Without tools like file locks, they would likely result in corruption of the database. Bind mount volumes are appropriate tools for workstations. We can take advantage of volumes in a host-agnostic and portable way with Docker-managed volumes.


**Managed volumes** use locations that are created by the Docker daemon in space controller by the daemon, called Docker managed space. In managed volumes, Docker daemon creates managed volumes in a portion of the host's file system that's owned by Docker. Using managed volumes is a method of decoupling volumes from specialized locations on the file system. Managed volumes are created when you use `-v` option on `docker run` but only specify the mount point in the container directory tree.

```shell
docker run -d \
    -v /var/lib/cassandra/data \
    --name cass-shared \
    alpine echo Data Contaienr
```

When above container is create, Docker daemon created directories to store the contents of the three volumes somewhere in a part of the host file system that it controls.

```shell
docker inspect -f "{{json .Volumes}}" cass-shared
```

Above command would show the location of the directory on the host file system where it is mounted. With Docker managed volumes, you say "I need place to put some data that I'm working with.". This is something Docker can fill on any machine with Docker installed. When we're done and we ask Docker to clean things up for us, Docker can confidently remove any directories or files that are no longer being used by a container. This avoid clutter.

### Sharing volumes between different containers

Suppose we have a web server which writes logs to `/logs/access`. If we want to move those logs off web server into more permanent storage, we might do that with a script inside another container. There are two ways to share volumes between containers.

**Host-dependent sharing**

Two or more containers are said to use host-dependent sharing when each has a bind mount volume for a single known location on the host file system.

```shell
mkdir ~/web-logs-example # set up known location
docker run --name plath -d \
    -v ~/web-logs-example:/data \
    dockerinaction/ch4_writer_a
docker run --rm \
    -v ~/web-logs-example:/reader-data \
    alpine:latest \
    head /reader-data/logA
cat ~/web-logs-example/logA
docker stop plath # stop the writer
```

Host-dependent sharing requires you to use bind mount volumes but this might be expensive to maintain if you're working with large number of machines.

**Generalized sharing**

The `docker run` command provides a flag that will copy the volumes from one or more containers to the new container. The flag `--volumes-from` can be set multiple times to specify multiple source containers.

```shell
docker run --name fowler \
    -v ~/example-books:/library/PoEAA \
    -v /library/DSL \
    alpine:latest \
    echo "Fowler collection created."

docker run --name knuth \
    -v /library/TAoCP.vol1 \
    -v /library/TAoCP.vol2 \
    -v /library/TAoCP.vol3 \
    -v /library/TAoCP.vol4.a \
    alpine:latest echo "Knuth collection created."
# Container reader copied all the volumes defined by both fowler and knuth.
docker run --name reader \
    --volumes-from fowler \
    --volumes-from knuth \
    alpine:latest ls -l /library/ # List all volumes as they were copied into new container
docker inspect reader # check volume list for reader
```

We can also copy volumes directly or transitively. So, if we're copying the volumes from another container, we'll also copy the volumes that it copied from some other container. Copied voluems always have the same mount point. We can't use `--volumes-from` in three situations. 
(1) If the container you're building needs a shared volume mounted to a different location. 
(2) Another is when volume sources conflict with each other or a new volume specification. If same mount point is specified, then a consumer of both will receive only one of the volume definitions.

```shell
docker run --name chomsky --volume /library/ss \
    alpine:latest echo "Chomsky collection created."
docker run --name lamport --volume /library/ss \
    alpine:latest echo "Lamport collection created"
docker run --name student \
    --volumes-from chomsky --volumes-from lamport \
    alpine:latest ls -l /library/
docker inspect student
```

(3) Third condition where `--volumes-from` can't be used is if you need to change the write permission of a volume. This is because it copies the full volumes definition. For example, if source has a volume mounted with read/write permission and you want to share that with a containe that should have only read access, using `--volumes-from` won't work.

### Managed volume life cycle

Managed volumes have life cycles that are independent of any container. Managed volumes are second-class entities. Managed volumes are only created when you omit a bind mount source, and they're only identifable by the containers that use them. A container owns all managed volumes mounted to its file system. Cleaning up managed volumes is a manual task. Docker can't delete bind mount volumes because the source exists outside the Docker scope. Docker can delete managed volumes when deleting containers. Running `docker rm` with `-v` option will try to delete any managed volumes referenced by the target container. Any managed volumes that are referenced by other containers will be skipped, but internal counters will be decremented. Always use `-v` option when removing contaienr. Orphan volumes (volumes whose container has been removed) render disk space unstable until they've been cleaned.

`docker rm -v student`

We can remove all stopped containers and their volumes using `docker rm -v $(docker ps -aq)` command.

### Advanced container patterns

**1. Volume container pattern**

This is when you come across a case for sharing a set of volumes with many containers or if you can categorize a set of volumes that fit a common use case. Volume containers are important for keeping a handle on data even in cases where a single container should have exclusive access to some data. Suppose you wanted to update your database. If your DB container writes its state to a volume and that volume was defined by a volume container, the migration would be as simple as shutting down the original database container and starting the new one with the volume container as a volume source.

**2. Data-packed volume containers**

Volume containers are in a unique position to seed volumes with data. THe data-packed volume containers describe how images can be used to distribute static resources like configuration or code for use in containers created with other images. A data-packed volume container is built from an image that copies static content from its image to volumes it defines. Data is packed and distributed in an image that defines a volume. At container-creation time the data is copied into the volume and is accessible to any containers that use this volume container. This could be built by hand if we have an image that has data you'd like to make available by running and defining the volume and running a `cp` command at creation time.

```shell
docker run --name dpvc \
    -v /config \
    dockerinaction/ch4_packed /bin/sh -c 'cp /packed/* /config/' # copy image content into new volume
docker run --rm --volumes-from dpvc \
    alpine:latest ls /config # List shared material
docker run --rm --volumes-from dpvc \
    alpine:latest cat /config/packedData
docker rm -v dpvc
```

**3. Polymorphic container pattern**

A polymorphic tool lets you interact with a consistent way but might have special implementations that do different things. A polymorphic container is one that provides some functionality that's easily substituted using volumes. For example, if an image contains the binaries for NodeJS and by default executes a command that runs the NodeJS program located at `/app/app.js`. We can change the behavior of containers created from this image by injecting new `app.js` using a volume mounted at `/app/app.js`. 

For example, deploying a multi-state application deployment pipeline where application configuration would change depending on where it is deployed.

```shell
docker run --name devConfig  \
    -v /config \
    dockerinaction/ch4_packed_config:latest \
    /bin/sh -c 'cp /development/* /config/' # copy development configuration
docker run --name prodConfig \
    -v /config \
    dockerinaction/ch4_packed_config:latest \
    /bin/sh -c 'cp /production/* /config/' # copy production configuration
# Run dev app with devConfigurations
docker run --name devApp \
    --volumes-from devConfig \
    dockerinaction/ch4_polyapp 
# run production app with production configurations
docker run --name prodApp \
    --volumes-from prodConfig \
    dockerinaction/ch4_polyapp
```

## Networking with Docker

Docker is mostly concerned with two types of networks. The first is the one that a host computer is connected to. The second is a virtual network that Docker creates to connect all of the running containers to the host network which is called *bridge*. Bridge is a network that connects multiple networks so that they can function as a single network. They work by selectively forwarding traffic between the connected networks based on another type of network address. 

### Docker container networking

Docker is about single-host virtual networks and multi-host networks. Local networks provide container isolation. In multi-host virtual networks, any container will have its own routable IP addresses. The virtual network is local to the machine where Docker is installed and is made u pof routes between participating containers and to host. Containers have their own private loopback interface and a separate Ethernet interface linked to another virtual interface in the host's namespace. This creates a separate link between host and each container. Each container is assigned a unique private IP address that's not directly reachable from external network. Connections are routed through the Docker bridge called `docker0`. Using `docker` commnad line tools, we can customize IP addresses used, the host interface that docker0 is connected to and the way containers communicate with each other. Docker uses kernel namespaces to create private virtual interfaces. Network exposure or isolation is provided by host's firewall rules.

All Docker containers follow one of the four archetypes. They define how a container interacts with other local containers and the host's network.

- Closed containers
- Bridged conainers
- Joined containers
- Open containers

#### Closed containers 

It doesn't allow any network traffic. In this, processes inside container need to communicate only with themselves or each other. Docker builds this types of container by skipping the step where an externally accesible network interface is created. The closed archetype has no connection to the Docker bridge interface. All Docker containers have access to a private loopback interface. By creating private loopback interfaces for each container, Docker enables programs run inside a container to communicate but without communication leaving that container.

```shell
docker run --rm \
    --net none \ # create closed container
    alpine:latest
    ip addr
```

The only network interface available is loopback address 127.0.0.1. This means it cannot connect to anything outside the container. Try below command to see.

```shell
docker run --rm \
    --net none \
    alpine:latest \
    ping -w 2 8.8.8.8 # ping google
```

#### Bridged Containers

Docker creates bridged containers by default. This archetype is most customizable and should be hardened. They have private loopback interface and another private interface that's connected to the rest of the host through a network bridge. All interfaces connected to docker0 are part of the same virtual subnet. This means they can communicate with each other and with larger network through the docker0 interface.

The most common reason to choose this is that the process needs access to the network.

```shell
docker run --rm \
    --net bridge \ # even if we remove this option, it will create bridge archetype
    alpine:latest \
    ip addr # list network addresses, there are two loopback and broadcast
docker run --rm \
    alpine:latest \
    ping -w 2 8.8.8.8
```

DNS is a protocol for mapping host names to IP addresses. `docker run` has a `--hostname` flag that can be used to set the host name of a new container. This adds an entry to the DNS override system inside the container. This entry maps the host name to the container's bridge IP address.

```shell
docker run --rm \
    --hostname  barker \
    alpine:latest \
    nslookup barker
```

Setting hostname of a container is useful when programs running inside a container need to look up their own IP address. If we can use external DNS server, we can share these hostnames with other containers. We can specify one or more DNS servers for a container using below command.

```shell
docker run --rm \
    --dns 8.8.8.8 # set primary DNS server to google's public DNS service
    alpine:latest \
    nslookup docker.com
```

`--dns` flag can be set multiple times to set multiple DNS servers in case one or more are unreachable. The DNS option `--dns-search` allows to specify a DNS search domain. With this one set, any host names that don't have a known top-level domain will be searched for with the specified suffix appended.

```shell
docker run --rm \
    --dns-search docker.com \ # Set search domain
    busybox:latest
    nslookup registry.hub # Look up shortcut for registry.hub.docker.com
```

This can be useful. For example, if you maintain a single DNS server for development and test environment, rather than building environment-aware software, we can consider using DNS search domains and using environment-unaware names.

```shell
docker run --rm \
    --dns-search dev.mycompany \
    busyxbox:latest \
    nslookup myservice # Resolves myservice.dev.mycompany
docker run --rm \
    --dns-search test.mycompany \
    busybox:latest \
    nslookup myservice # Resolves to myservice.test.mycompany
```

The `--add-host` flag on `docker run` command lets you provide a custom mapping for an IP addresses and host name pair. This flag cannot be set as a default at daemon startup. We could use it to route traffic for a particular destination through a proxy. 

```shell
docker run --rm \
    --add-host test:10.10.10.255 \ # Add host entry
    alpine:latest \
    nslookup test # REsolves to 10.10.10.255
```

All custom mappings live in a file at `/etc/hosts` inside container.

```shell
docker run --rm \
    --hostname mycontainer \ # set hostname
    --add-host docker.com:127.0.0.1 \
    --add-host test:10.10.10.2 \ # create entry
    alpine:latest \
    cat /etc/hosts # view all host entries
```

DNS (name to IP address map) provides a simple interface that can be used to decouple programs from specific network addresses.

Host network is not accessible from host network by default as they are protected by host's firewall. There is no way to get to a container from outside the host. The `docker run` provides a flag `-p` or `--publish` that can be used to create a mapping between a port on host's network stack and the new container's interface. This can be of four forms:

- `<containerPort>`: binds the container port to dynamic port on all host's interfaces. For example, `docker run -p 3333 ...`
- `<hostPort>:<containerPort>`: binds specified container port to the specific port on each host's interfaces. Like, `docker run -p 80:80`
- `<ip>::<containerPort>`: binds the container port to a dynamic port on the interface with specific IP address. `docker run -p 192.168.0.32::2222 ...`
- `<ip>:<hostPort>:<containerPort>`: binds the container port to the specified port on the interface with specific IP address. For example, `docker run 192.168.0.32:1111:1111 ...`. Here, 192.168.0.32 is host's IP address.

If we accept a dynamic or ephemeral port assignment on the host, we can use `-P` or `--publish-all` flag. We can expose multiple ports using two methods as shown below.

```shell
docker run -d --name dawson \
    -p 5000 \ # export each port one by one
    -p 6000 \
    -p 7000 \
    dockerinaction/ch5_expose
docker run -d --name woolery \
    -P \ # expose relevant ports that docker exposes
    dockerinaction/ch5_woolery
```

The `docker run` command provides flag `--expose` that takes port numbers that the container should expose. This is used for `-p` option to find which ports to expose.

```shell
docker run -d --name philbin \
    --expose 8000 \
    -P \
    dockerinaction/ch5_expose
```

We can see which ports are mapped using `docker ps` or `docker inspect` or `docker port`.

Now, for **inter-container communication**, all local containers are on the same bridge network connected to Docker bridge virtual interface (docker0).

```shell
# run `nmap` to scan all the interfaces attached to the bridge network
docker run -it --rm dockerinaction/ch5_nmap -sS -p 3333 172.17.0.0/24
```

Here, it's looking for any interface that's accepting connections on port 3333. If we had another container with such a service, it would have discovered it. This may be risky as any container is fully accessible from any other local container. When we start the Docker daemon, we can configure to disallow network connections between containers. This is best practice in multi-tenant environments. This can be achieved using `--icc=false` when we start Docker daemon.

`docker -d --icc=false ...`

At worst, leaving inter-container communication enabled allows compromised programs within containers to attack other local containers.

Docker provides three options for customizing bridge interface. These let you define the address and subnet of bridge, the range of IP addresses that can be assigned to containers and the maximum transmission unit (MTU).

Using the `-bip` flag, we can set the IP addresses of the bridge interface the Docker will create and the size of the subnet using a classless inter-domain routing (CIDR) formatted address. For example, if we set value of `--bip` to `192.168.0.128/25` will set docker0 interface IP address to 192.168.0.128 and allows IP in range 192.168.0.128 to 192.168.0.255. We can customize which IP addresses in that network can be assigned to new containers using `--fixed-cidr` flag. If we wanted to reserve only 64 addresses, we could use 192.168.0.192/26. The range specified must be a subnet of the network assigned to the bridge. Network interfaces have a limit to the maximum size of a packet. By protocol, Ethernet have a maximum packet size of 1500 bytes. We can use `--mtu` to set the size in bytes using `docker -d --mtu 1200`.

#### Joined Containers

These containers share a common network stack. Interfaces are shared like managed volumes.

```shell
# Create closed container
docker run -d --name brady \
    --net none alpine:latest \
    nc -l 127.0.0.1:3333
# Create container and specify container value that new container should be joined to
docker run -it \
    --net container:brady \ # Either container name or its ID should be used.
    alpine:latest netstat -al
```

These are two containers that are joined but has no access to larger network because they are closed containers. This is useful when two different programs with access to two different pieces of data need to communicate but shouldn't share direct access to the other's data. Such joined containers create port conflict issues if they are using same port. Communication between containers is subject to firewall rules. If one process needs to communicate with another on an unexposed port, the best thing is to join the containers.

#### Open containers

These containers have full access to the host's network. They provide no isolation. This is created when we speicfy `host` as the value of `--net` option.

```shell
docker run --rm \
    --net host \
    alpine:latest ip addr # you should see several interfaces listed
```

### Inter-container dependencies

Bridge network assigns IP addresses to ontainers dynamically at creation time, so using them to setup small system may not be easy. When you create a new container, you can tell Docker to link it to any other container. That target container must be running when the new container is created. **Adding a link** on a new container does three things:
1. Environment variables describing target container's end point will be created.
2. The link alias will be added to the DNS override list of the new container with the IP address of the target container.
3. If inter-container communication is disabled, Docker will add specific firewall rules to allow communication between linked containers.

The ports that are opened for communication are those that have been exposed by the target container. So the `--expose` flag provides a shortcut for only one particular type of container to host port mapping when ICC is enabled. When ICC is disabled, `--expose` becomes a tool for defining firewall rules.

```shell
docker run -d --name importantData \
    --expose 3306 \
    dockerinaction/mysql_noauth \
    service mysql_noauth start
# Create link and setup alias to db
docker run -d --name importantWebapp \
    --link importantData:db \
    dockerinaction/ch5_web startapp.sh -db tcp://db:3306
docker run -d --name  buggyProgram \
    dockerinaction/ch5_buggy # container has no route to importantData
```

In above example, when the web applications opens a database connection to tcp://db:3306, it will connect to database. In the last container, if inter-container communication is enabled, attackers could easily steal the data from the database in the importantData container. They can do network scan to identify open port and then gain access by opening a connection. If inter-container communication was disabled, an attacker would be unable to reach any other containers from the container running the compromised software.

**Links** are one-way network dependencies created when one container is created and specifies a link to another. It takes `--link` argument which map a container name or ID to an alias. Software running inside a container needs to know the alias of the container or host it's connecting to so that it can perform the lookup. Similar to host names, link aliases become a sym bol that multiple parties must agree on for a system to operate correctly.

`docker run --link a:alias-a --link b:alias-b ...`

Below is a code for dockerinaction/ch5_ff to validate that a link named "database" has been set at startup. This is useful if ch5_ff needs to use database but other container was defined with different name or there is no link created with "database" name.

```shell
#!/bin/sh

if [ -z ${DATABASE_PORT+x} ]
then
    echo "Link alias 'database' was not set!"
    exit
else
    exec "$@"
fi
```

Try below commands as some of them won't work.

```shell
docker run -d --name mydb --expose 3306 \
    alpine:latest nc -l 0.0.0.0:3306
docker run -it --rm \
    dockerinaction/ch5_ff # It will fail.
docker run -it --rm \
    --link mydb:wrongalias dockerinaction/ch5_ff # won't work due to incorrect link
docker run -it --rm \
    link mydb:database dockerinaction/ch5_ff echo It worked.
docker stop mydb && docker rm mydb # Shut down link target container
```

```shell
docker run -d --name mydb \
    --expose 2222 --expose 3333 --expose 4444/udp \
    alpine:latest nc -l 0.0.0.0:2222 # create valid link target
docker run -it --rm \
    --link mydb:database \
    dockerinaction/ch5_ff env # Create link and list environment variables
docker stop mydb && docker rm mydb
```

These environment variables are available for any need application developers might have in connecting to linked containers.

The nature of links is such that dependencies are directional, static and nontransitive (linked containers won't inherit links). Links work by determining the network information of a contaienr and then injecting that into a new container. Link can only be built from new containers to *running* containers. If the dependency stops, the link will be broken. 

## Isolation in Docker

### Resources allowances

If the resource consumption of processes on a computer exceeds the available physical resources, the processes will experience performance issues and may stop running. If we want to make sure tha a program won't overwhelm others on the computer, we can set limit on the resources that it can use. Docker provides three flags for managing thee different types of resource allowances that we can set on a container, memory, CPU and devices.

**Memory limits** restrict the amount of memory that processes inside a container can use. We can put a limit by using `-m` or `--memory` flag on `docker run` or `docker create` commands.

```shell
docker run -d --name ch6_mariadb \
    --memory 256m \
    --cpu-shares 1024 \
    --user nobody \
    --cap-drope all \
    dockerfile/mariadb
```

This installs MariaDB and starts container with a memory limit of 256MB. Here, memory limits are not reservations means they are not guaranteed to be available. They are only protection from overconsumption. You must consider whether the software can operate with proposed memory allowance and whether the system support the allowance. On hosts that have swap space (virtual memory that extends onto disk), a container may realize the allowance. Docker does not detect memory issues. The best it can do is restart if `--restart` flag is used.

**Processing time** is another important resource whose starvation will degrade performance. To set CPU shares of a container and establish its relative weight, both `docker run` and `docker create` has `--cpu-shares` flag.

```shell
docker run -d -P --name ch6_wordpress \
    --memory 512m \
    --cpu-shares 512 \ # relative weight of processor, so mariadb gets two processors for every one Wordpress cycle
    --user nobody \
    --cap-drop net_raw \
    --link ch6_mariadb \
    wordpress:4.1
```

We can find the port of this wordpress using `docker port ch6_wordpress` to get port number. Once we get port number, we can open `http://localhost:<port>` in browser. CPU shares are only enforced when there is contention for time on the CPU. The intent of this tool is to prevent one process from overwhelming a computer. Docker also has ability to assign a container to a specific CPU set. Context switching is expensive and may cause noticeable impact on the performance of system. We can use `--cpuset-cpus` flag to limit a container to execute only on specific set of CPU cores.

```shell
# Start container limited to a single CPU and run load generator
docker run -d \
    --cpuset-cpus 0 \ # restrict to CPU number 0
    --name ch6_stresser dockerinaction/ch6_stresser

# start a container to watch the load on the CPU under load
docker run -it --rm dockerinaction/ch6_htop # run withing 30 seconds
docker rm -vf ch6_stresser
```

If we use above with different `cpuset-cpus` value, we can see different processes assigned to different cores.

**Devices access** is more like resource authorization control. In some conditions, it may be important to share devices between a host and specific container. We can use `--device` flag to specify a set of devices to mount into the container. If we have webcam at `/dev/video0`, it will be mounted at the same location using following:

```shell
docker -it --rm \
    --device /dev/video0:/dev/video0 \
    ubuntu:latest ls -al /dev
```

### Shared memory

Linux has few tools for sharing memory between processes running on same computer. Such inter-process communication (IPC) performs at memory speeds. Docker creates a unique IPC namespace for each container by default. The IPC namespace prevents processes in one container from accessing the memory on the host or in other containers. The image `dockerinactionch6_ipc` contains both producer and consumer and they communicate using shared memory.

```shell
# creates message queue and starts broadcasting messages to it
docker -d -u nobody --name ch6_ipc_producer \
    dockerinaction/ch6_ipc -producer # start producer
# pulls from the message queue and writes to the logs
docker -d -u nobody --name ch6_ipc_consumer \
    dockerinaction/ch6_ipc -consumer # start consumer
docker logs ch6_ipc_producer
docker logs ch6_ipc_consumer
```

With above commands, each process used the same key to identify the shared memory resource, but they referred to different memory. The reason is each container has its own shared memory namespace. To run programs that communicate with shared memory in different containers, we'll need to join their IPC namespaces with `--ipc` flag which will create a new container with same IPC namespace as another target container.

```shell
docker rm -v ch6_ipc_consumer # remove earlier consumer
docker -d --name ch6_ipc_consumer \
    --ipc container:ch6_ipc_producer \ # join IPC namespace
    dockerinaction/ch6_ipc -consumer 
docker logs ch6_ipc_producer
docker logs ch6_ipc_consumer

# clean up volume (-v) and kill if running (-f)
docker rm -vf ch6_ipc_producer ch6_ipc_consumer
```

Sharing memory with containers is safer than sharing with host.

If we want to operate in the same namespace as the rest of the host, we can do so using open memory container. These consumers will be able to comunicate with each other and any other processes running on the host computer. This should be avoided as much as possible. Open memory containers are a risk.

```shell
docker -d --name ch6_ipc_producer \
    --ipc host \
    dockerinaction/ch6_ipc -producer
docker -d --name ch6_ipc_consumer \
    --ipc host \
    dockerinaction/ch6_ipc -consumer
docker rm -vf ch6_ipc_producer ch6_ipc_consumer
```

### Users in Docker

Docker starts containers as the root user inside that container by default. This could be dangerous as root user has almost all access. Linux has a mechanism  namespace (USR) to map users from one namespace to another. There is currently no way to examine an image to discover attributes like default user. Once a container has been created, we can find the username that container is using:

```shell
docker create --name bob busybox:latest ping localhost
docker inspect bob
docker inspect bob --format "{{.Config.User}}" bob
```

If the result is blank, the container will run with root user. The metadata returned by `docker inspect` only includes the configuration that the container was started with. 

```shell
docker run --rm --entrypoint "" busybox:latest whoami
docker run --rm --entrypoint "" buxybox:latest id # get the id and username
# get list of all available users
docker run --rm busybox:latest awk -F: '$0=$1' /etc/passwd
```

Once we have specific user that we want to user when running a container, we can do so using:

```shell
docker run --rm \
    --user somebody \
    busybox:latest id
docker run --rm \
    -u nobody:default \
    busybox:latest id # use default group with specific username
docker run --rm \
    -u 10000:20000 \
    busybox:latest id # use specific uid, gid instead of usernames
```

Unless you want a file to be accessible to a container, don't mount it into that container with a volume. We can also edit the image ahead of time by setting the user Id of the user we're going to run the container with.

```shell
mkdir logFiles
sudo chown 2000:2000 logFiles # set ownership of directory to desired user and group
docker run --rm -v "$(pwd)"/logFiles:/logFiles \
    -u 2000:2000 ubuntu:latest \
    /bin/bash -c "echo This is important info > /logFiles/important.log"
docker run --rm -v "$(pwd)"/logFiles:/logFiles \
    -u 2000:2000 ubuntu:latest \
    /bin/bash -c "echo More info >> /logFiles/important.log"
sudo rm -r logFiles
```

Docker can adjust the feature authorization of processes within containers. When we create a new container, Docker drops a specific set of capabilities by default. The default set of capabilities provided to Docker containers provides a resonable feature reduction. We could drop specific funtionality (for example, NET_RAW) from a container using `--cap-from` flag.

```shell
docker run --rm -u nobody \
    ubuntu:latest \
    /bin/bash -c "capsh --print | grep net_raw"
docker run --rm -u nobody \
    --cap-drop net_raw ubuntu:latest \
    /bin/bash -c "capsh --print | grep net_raw"
```

Similarly, `--cap-add` can be used to add capabilities. These options can be specified multiple times to specify multiple capabilities. To add SYS_ADMIN capabilities:

```shell
docker run --rm -u nobody \
    ubuntu:latest \
    /bin/bash -c "capsh --print | grep sys_admin"
docker run --rm -u nobody \
    --cap-add sys_admin ubuntu:latest \
    /bin/bash -c "capsh --print | grep sys_admin"
```

When you need to run a system administration task inside a container, you can grant that container privileged access to your computer.

```shell
docker run --rm --privileged \
    ubuntu:latest id # check out our IDs
docker run --rm --privileged \
    ubuntu:latest capsh -print # Check our Linux capabilities
docker run --rm --privileged \
    ubuntu:latest ls /dev # Check list of mounted devices
docker run --rm --privileged \
    ubuntu:latest ifconfig # check network configuration
```

There are tools to enhance and harden your containers include AppArmor and SELinux. Docker has a `--security-opt` to specify Linux security modules at container creation or runtime.

Docker ships with libcontainer by default but users can change the container execution provider. To use LXC, we need to install it and make sure that Docker was started with the LXC driver enabled using `--exec-driver=lxc` option. Then, we can use `--lxc-conf` flag to set the LXC configuration for a container.

```shell
docker run -d \
    --lxc-conf="lxc.cgroup.cpuset.cpus=0,1" \
    --name ch6_stresser dockerinaction/ch6_stresser
docker run -it --rm dockerinaction/ch6_htop
docker rm -vf ch6_stresser
```