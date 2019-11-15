# Creating Custom Images

## Packaging software in Images

We can create Docker image by either modifying an existing image inside a container or defining and executing a build script called a Dockerfile.

### Building from container

A union file system (UFS) mount provides a container's file system. Any changes we make to the file system inside a container will be written as new layers that are owned by the container that created them. Basic workflow for building an image from container includes three steps.
1. You need to create a container from an existing image.
2. Modify the file system of the container.
3. Commit those changes. Once committed, you'll be able to create new containers from the resulting image.

```shell
# Create container
docker run --name hw_container \
    ubuntu:latest \
    touch /HelloWorld # modify the container
# Commit changes
docker commit hw_container hw_image
# Test new container
docker rm -vf hw_container # remove changed container
docker run --rm \
    hw_image ls -l /HelloWorld
```

Let's try packaging Git in a container. 

```shell
# Open interactive session on base image
docker run -it --name image-dev ubuntu:latest /bin/bash
# From this interactive shell, we can customize our container.
apt-get -y install git
git version
exit # close interactive session
# Check the changes in the files and directories of docker image
docker diff image-dev
# Here, lines that start with A are added, those with C are changed and those with D are deleted.
```

When committing, it's always best practice to use `-a` flag that signs the image with an author string. You should also use `-m` flag which sets a commit message.

```shell
docker commit -a "@dockerinaction" -m "Added git" image-dev ubuntu-git
docker images
docker run --rm ubuntu-git git version # test this image
docker run --rm ubuntu-git
```

For testing of `docker diff` command, you can try:

```shell
docker run --name tweak-a busybox:latest touch /HelloWorld
docker diff tweak-a
docker run --name tweak-d busybox:latest rm /bin/vi
docker diff tweak-d
docker run --name tweak-c busybox:latest touch /bin/vi
docker diff tweak-c
docker rm -vf tweak-a
docker rm -vf tweak-d
docker rm -vf tweak-c
```

An **entrypoint** is the program that will be executed when the container starts. If entrypoint is not set, the default command will be executed directly. If entrypoint is set, the default command and its arguments will be passed to the entrypoint as arguments. To set the entrypoint use `--entrypoint` flag.

```shell
docker run --name cmd-git --entrypoint git ubuntu-git
docker commit -m "Set CMD git" \
    -a "@dockerinaction" cmd-git ubuntu-git # Commit new image to same name
docker rm -vf cmd-git
docker run --name cmd-git ubuntu-git version
```

When we use `docker commit`, we commit not only file system but also meta data describing the execution context. Below parameters will be carried forward when a container is created.
- All environment variables
- The working directory
- The set of exposed ports
- All volume definitions
- The container entrypoint
- Command and arguments

If these values weren't set for the container, they will be inherited from the original image.

```shell
# Environment variables
docker run --name rich-image-example \
    -e ENV_EXAMPLE1=Rich -e ENV_EXAMPLE2=Example \
    busybox:latest # Create environment variable specialization
docker commit rich-image-example rie
docker run --rm rie \
    /bin/sh -c "echo \$ENV_EXAMPLE1 \$ENV_EXAMPLE2" 
```

```shell
# Entrypoint and command specialization
docker run --name rich-image-example2 \
    --entrypoint "/bin/sh" \ # set entrypoint
    rie -c "echo \$ENV_EXAMPLE1 \$ENV_EXAMPLE2" # set default command
docker commit rich-image-example2 rie
docker run --rm rie # different command but same output
```

When we read a file from a union file system, that file will be read from the top-most layer where it exists. If the file was not created or changed on the top layer, the read will fall through the layers until it reaches a layer where that file exists. All this layer functionality is hidden by the union file system. When a file is deleted, a delete record is written on the top layer, which overshadows any versions of that file on lower layers. When file is changed, that change is written to the top layer, which again shadows any versions of that file on lower layers. We can see the changes made to file system using `docker diff` command.

`docker commit` commits the top-layer changes to an image. When we commit a container's changes to its file system, we're saving a copy of that top layer in an identifable way. When we commit the layer, a new ID is generated for it and copies of all the file changes are saved. The metadata for a layer includes that generated identifier, the identifier of the layer below it (parent), and the execution context of the container that the layer was created from. Layer IDs and metadata form the graph that Docker and UFS use to construct images.

When we commit a docker container, we get large hexadecimal numbers with new image ID. We can create containers using this ID but they are difficult to remember. That's why we have Docker **repositories**. A repository is roughtly defined as a named bucket of images. Repositories are location/name pairs that point to a set of specific layer IDs. Each repository contains at least one tag that points to a specific layer ID and thus image definition.

If you want to copy an image, you need to create a new tag or repository from the existing one. We can do this using `docker tag` command. Every repository has 'latest' tag, which will be used if no tag is specified.

```shell
docker tag myuser/myfirstrepo:mytag myuser/mod_ubuntu
```

All layers below the writable layer created for a container are immutable. This means you can share these images without worrying but you need to add a new layer, anytime you make changes.

```shell
docker tag ubuntu-git:latest ubuntu-git:1.9 # create new tag 1.9

docker run --name image-dev2 \
    --entrypoint /bin/bash \
    ubuntu-git:latest -c "apt-get remove -y git" # remove git
docker commit image-dev2 ubuntu-git:removed
docker tag -f ubuntu-git:removed ubuntu-git:latest  # Reassign latest tag
docker images # check image size
```

Even though we remove Git, the image actually increased in size. UFS will mark a file as deleted by actually adding a file to the top layer. The original file and any copies that existed in other layers will still be present in the image. The union file system may have layer count limit around 42. We can examine all layers in an image using `docker history` command.

`docker history ubuntu-git:removed`

We can flatten image but that would be bad idea. Instead of fighting with the layer system, we can solve size and layer growth problems using the layer system to create branches. Branching means you will need to repeat the steps that were accomplished in peer branches.

The `docker export` will stream the full contents of the flattened union file system to stdout or an output file as a tarball. This is useful if you need to use the file system that was shipped with an image outside the context of a container. We can use `docker cp` for this.

```shell
docker run --name export-test \
    dockerinaction/ch7_packed:latest ./echo For Export
docker export --output contents.tar export-test
docker rm export-test
tar -tf contents.tar # Show archive contents
```

The `docker import` command will stream the content of a tarball into a new image. 

## Build automation

A Dockerfile is a file that contains instructions for building an image. These are followed by Docker image builder from top to bottom and can be used to change anything about an image.

```Dockerfile
# An example Dockerfile for installing Git on Ubuntu
FROM ubuntu:latest
MAINTAINER "piyushpatel@gmail.com"
RUN apt-get install -y git
ENTRYPOINT ["git"]
```

Tag the new image with 'auto'
```shell
docker build --tag ubuntu-git:auto .
docker images # Check if this image exists
docker run --rm ubuntu-git:auto
```

If you are starting from empty repository, we can add that using repository named `scratch`. The `docker build` command starts the build process of the image with specific tag. If we have named Dockerfile with different name, we can specify which file to use in build process using `--file` or `-f` flag. Each instruction in Dockerfile triggers the creation of a new container with the specified modification. At the end of modification, the builder commits the layer and moves on to the next instruction and container is created from the fresh layer. If you want to omit the output of RUN command, we can invoke Docker build using `--quiet` or `-q` flag. 

The layered structure of each instruction means that we could branch on any of these steps and Docker builder can cache the results of each step. If a problem occurs after several other steps, the builder can restart from the same position after the problem has been fixed.

### Dockerfile

Dockerfiles are expressive and maintaining multiple versions of an image is as simple as maintaining multiple versions of Dockerfiles. For more information on all instructions, you can refer to Docker documentation for builder.

Below file builds a base image and two other images with distinct versions of the mailer program. The purpose of this program is to listen for messages on a TCP port and then send those messages to their intended recipients. The first version listen for messages and log those messages. The second will send the message as an HTTP POST to the defined URL. With Dockerfile, it is easier to copy files from local computer to Docker image. We can also define files which should not be copied into any images in a file called `.dockerignore`. When we create Dockerfile, it should be kept in mind that each Dockerfile instruction will result in a new layer being created. Instructions should be combined whenever possible because the builder won't perform any optimization.

```shell
cd example-dockerfiles/mailer
docker build -t dockerinaction/mailer-base:0.6 -f mailer-base.df .
```
`FROM` sets the layer stack to start from.
`MAINTAINER` sets the Author value in the image metadata.
`ENTRYPOINT` sets the executable to be run at container startup. Entrypoint could be specified using shell form or exec form. A command specified using shell form would be executed as an argument to default shell. `/bin/sh -c 'exec ./mailer.sh'`. If shell form is used, then all other arguments provided by CMD instruction will be ignored.
`ENV` sets environment variables for an image. Similar to `--env` flag for docker create.
`LABEL` is used to define key/value pairs that are recorded as additional metadata for an image or container. It is simialr to `--label` flag on docker create.
`WORDIR` sets the default working directory of an image. Setting WORKDIR to a location that doesn't exist will create that location.
`EXPOSE` creates a layer that opens port 33333.
`USER` sets the user and group for all further build steps and containers created from the image.

`docker inspect dockerinaction/mailer-base:0.6` can be used to inspect an image.

A Dockerfile defines three instructions to modify the file system: COPY, VOLUME and ADD. Check [mailer-logging.df](example-dockerfiles/mailer/mailer-logging.df)

`COPY` will copy files from file system where the image is being built into the build container. The last argument is destination and all other arguments are source files. It's better to delay the RUN instructions to change file ownership until all the files that you need to update have been copied into the image. 
`VOLUME` will create each value in string array as a nwe volume definition in the resulting layer. This will only create the defined location in the file system and then add a volume definition to the image metadata.
`CMD` is related to ENTRYPOINT. Thsi represents an argument list for the entrypoint. Here, ENTRYPOINT is defined as mailer command. The argument used is the location that should be used for the log file.

Create a directory `./log-impl` and create file inside it named `mailer.sh`.

```shell
#!/bin/sh
# mailer.sh
printf "Logging Mailer has started.\n"
while true
do
    MESSAGE=$(nc -l -p 33333)
    printf "[Message]: %s\n" "$MESSAGE" > $1
    sleep 1
done
```

Use following command to build the `mailer-logging` image from `example-dockerfiles/mailer` directory.

```shell
docker build -t dockerinaction/mailer-logging -f mailer-logging.df .
# start container from this image
docker run -d --name logging-mailer dockerinaction/mailer-logging
```

Containers that link to this mailer will have their messages logged to `/var/log/mailer.log`.

`ADD` instruction will fetch remote source files if a URL is specified or extract the files of any source determined to be an archive file.

Create subdirectory `live-impl` in the same folder and add `mailer.sh` file.

```shell
cd example-dockerfiles/mailer/
docker build -t dockerinaction/mailer-live -f mailer-live.df
docker run -d --name live-mailer dockerinaction/mailer-live
```

`ONBUILD` instruction defines instructions to execute if the resulting image is used as a base for another build.

### Startup scripts

Docker containers have no control over the environment where they're created. An image author can solidify the user experience of their image by introducing environment and dependency validation prior to execution of the main task. For example, Wordpress requires certain environment variables to be set or container links to be defined. WordPress images use a script as the container entrypoint. That script validates that the container context is set in a way that's compatible with the contained version of WordPress. If any required condition is unmet, then the script will exit before starting WordPress and the container will stop unexpectedly. The script should validate as much context as possible including links, aliases, environment variables, network access, network port availability, root file system mount parameters, volumes, current user, etc. At container startup, below script enforces that either another container has linked to the web alias and has exposed port 80 or the WEB_HOST environment variable has been defined.

```shell
#!/bin/bash
set -e

if [ -n "$WEB_PORT_80_TCP" ]; then
    if [ -z "$WEB_HOST" ]; then
        WEB_HOST='web'
    else
        echo >&2 '[WARN]: Linked container, "web" overridden by $WEB_HOST.'
        echo >&2 "===> Connecting to WEB_HOST ($WEB_HOST)"
    fi
fi

if [ -z "$WEB_HOST" ]; then
    echo >&2 '[ERROR]: specify a linked container, "web" or WEB_HOST environment variable'
    exit 1
fi
exec "$@" # run the default command
```

Init process typically use a set of files to describe the ideal state of the initialized system. These files describe what programs to start, when to start them and what actions to take when they stop.

A docker container user can always override image defaults when they create a container. The best thing an image author can do are create other non-root users and establish a non-root default user and group. `USER` instruction sets the user and group in Dockerfile. We can drop high privileges in Dockerfile or with startup script before a container is created. If we drop privileges too early, the active user may not have permission to complete the instructions in a Dockerfile.

```
# UserPermissionDenied.df
FROM busybox:latest
USER 1000:1000
ENTRYPOINT ["nc"]
CMD ["-l", "-p", "80", "0.0.0.0"]
```

With above Dockerfile, if we build an image and create a container, the command will fail.

```shell
docker build \
    -t dockerinaction/ch8_perm_denied \
    -f UserPermissionDenied.df .
docker run dockerinaction/ch8_perm_denied
```

Docker currently lacks support for the Linux USR namespace. This means UID 1000 in container is UID 1000 on host machine.
There are two other aspects of hardening container, SUID and SGID. An executable file with the SUID bit set will always execute as its owner.
For example, program like `/usr/bin/passwd` owned by root user has SUID permission set. If a non-root user like bob executes passwd, he will execute that program as the root user.

```
FROM ubuntu:latest
# SET SUID bit on whoami
RUN chmod u+s /usr/bin/whoami
# Create an example user and set it as default
RUN adduser --system --no-create-home --disabled-password --disabled-login \
    --shell /bin/sh example
USER example
# Set the default to compare the container user and the effective user for whoami
CMD printf "Container running as: %s\n" $(id -u -n) && \
    printf "Effectively running whoami as: %s\n" $(whoami)
```

```shell
docker build -t dockerinaction/ch8_whoami .
docker run dockerinaction/ch8_whoami
```

The SGID works similarly. The difference is that the execution will be from the owning group's context, not user.

Below command shows how many and which files have these permissions.

```shell
docker run --rm debian:wheezy find / -perm +6000 -type f
# Find all files with SGID permission
docker run --rm debian:wheezy find / -perm +2000 -type f
```

A bug in any of these files could be used to compromise the root account inside a container. So, either unset their SUID and SGID permissions or delete these files. The following instruction will unset the permissions on all files currently in the image.

```shell
RUN for i in $(find / -type f \( -perm +6000 -o -perm +2000 \)); \
    do chmod ug-s $i; done
```

## Software Distribution

Hosted registries offer both public and private repositories with automated build tools. Running a private registry lets you hide and customize your image distribution infrastructure.

### Choosing a distribution method

Choosing the best distribution method for your needs may require you to consider cost, visibility, transport speed, availability, access control, etc. So, free registries like DockerHub may be free but we can't control access on them. Docker registries are services that make repositories accessible to Dcoker pull commands. A hosted registry is a Docker registry service that's owned and operated by third-party vendor like DockerHub, Quay.io, Tutum.co, etc.

The simplest way to **publish repository** is to start with hosted registries. Once we have account, create a Dockerfile named HelloWorld.df and add following.

```
FROM busybox:latest
CMD echo Hello World
```

Build your new image using following.

```shell
docker build -t <your-username>/hello-dockerfile \
    -f HelloWorld.df
# Login using following
docker login
docker push <your-username>/hello-dockerfile
docker search <your-username>/hello-dockerfile
```

Hosted repositories are layer-aware and will work with Docker clients to transfer only the layers that client doesn't have. Repositories owned by an individual may be written only by that individual account. Repositories owned by organizations may be written to by any user who is part of that organization.

**Automated builds** are images that are built by the registry pprovider using image sources that you've made available. Distributing your work with automated builds requires a hosted image repository and a hosted Git repository. DockerHub integrates with Github.com and Bitbucket.org for automated builds. They provide *webhook* which is a way for your Git repository to notify your image repository that a change has been made to the source. When Docker Hub receives a webhook for Git repo, it will start an automated build for Docker Hub repository.

Create Git repository named `hello-docker` and make it public. Create a new file named Dockerfile and include following.

```
FROM busybox:latest
CMD echo Hello World
```

Create Git repository. You should also set up Automated builds from the dropdown menu on DockerHub website.

```shell
git init
git remote add origin <github repo link>
git add Dockerfile
git commit -m "First commit"
git push -u origin master
```

After a while search your docker image using `docker search <your username>/hello-docker`

**Private repositories** are similar to public. Individuals and small teams will find the most utility in private hosted repositories. Large companies that need a higher degere of secrecy and have a suitable budget may find their needs better met by running their own private registry.

### Private registries

Private repositories provide better control and secercy. People can interact with a private registry exactly as they would with a hosted registry. The distribution software for Docker registry is available on Docker Hub. Staring a local repository in a container can be done with a single command.

```shell
docker run -d -p 5000:5000 \
    -v "$(pwd)"/data:/tmp/registry-dev \
    --restart=always --name local-registry registry:2
```

This image is configured for insecure access from machine running a client's Docker daemon. In this case, registry location is `localhost:5000`. To see workflow of copying images from Docker Hub into your new registry:

```shell
docker pull dockerinaction/ch9_registry_bound
# Verify image is discovered with label filter
docker images -f "label=dia_excercise=ch9_registry_bound"
# Push demo image into your private registry
docker tag dockerinaction/ch9_registry_bound \
    localhost:5000/dockerinaction/ch9_registry_bound
# remove existing tagged reference
docker rmi dockerinaction/ch9_registry_bound \
    localhost:5000/dockerinaction/ch9_registry_bound
docker images -f "label=dia_excercise=ch9_registry_bound"
docker pull localhost:5000/dockerinaction/ch9_registry_bound
# Image is back now, verify
docker images -f "label=dia_excercise=ch9_registry_bound"
docker rm -vf local-registry # Cleanup local repository
```

## Customized Registries

A company may run one or more centralized registries that are backed by durable artifact storage.

### Personal registry

For a personal registry, pull the image and launch a personal registry to start.

```shell
docker run -d --name personal_ergistry \
    -p 5000:5000 --restart=always \
    registry:2
```

The distribution project runs on port 5000, but clients make no assumptions about locations and attempt connecting to port 80 by default. We could map port 80 on host to port 5000 on the container, but we map port 5000 directly. Anytime you connect to the registry, you'll need to explicitly state the port where the registry is running. The container you started from the registry image will store the repository data that you send to it in a managed volume mounted at `/var/lib/registry`. 

```shell
docker tag registry:2 localhost:5000/distribution:2
docker push localhost:5000/distribution:2
```

The `push` command will output a line for each image layer that's uploaded to the registry and finally output the digest of the image.

The V2 Registry API is RESTful. Create `curl.df` file.

```
FROM gliderlabs/alpine:latest
LABEL source=dockerinaction
LABEL category=utility
RUN apk --update add curl
ENTRYPOINT ["curl"]
CMD ["--help"]
```

Build docker image using `docker build -t dockerinaction/curl -f curl.df .`. With this image, we can issue the curl commands in the examples without worrying about whether curl is installed or what version is installed on host computer.

```shell
docker run --rm --net host dockerinaction/curl -Is
    http://localhost:5000/v2/
```

Below command will retrieve the list of tags in the distribution repository on your registry.

```shell
docker run --rm -u 1000:1000 --net host \
    dockerinaction/curl -s http://localhost:5000/v2/distribution/tags/list
```
195