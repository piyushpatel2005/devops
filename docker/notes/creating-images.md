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