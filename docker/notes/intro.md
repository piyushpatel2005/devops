# Docker

Docker is command-line program, background daemon, and a set of services that take a logical approach to solving common software problems and simplifying installation, runnin, publishing and removing softwares. It is open source. Without Docker, businesses typically use hardware virtualization (virtual machines) to provide isolation. They take a long time to create and require significant resource overhead because they run a whole copy of an operating system in addition to the software you want to use. Docker containers don't use hardware virtualization. Programs inside Docker containers interface directly with the host kernel.

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
