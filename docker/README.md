# Docker

## Docker quick guide

Installation Guide

```shell
cat /etc/redhat-release
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# configure docker repo
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo systemctl enable docker
sudo systemctl start docker
docker version
sudo docker run hello-world # run sample docker image
# if we download and run this docker image as super user, the general user won't have permission to run this image
docker run hello-world # fails
#  We need to add our general user to docker group
sudo usermod -a -G docker <username>
docker run hello-world
```

There is Github repository `docker-install` which installs docker quite easily by running a script.
Docker has docker engine and docker hub. Docker hub is the registry where we have repository of different images.

For example, if we want to set up common development environment all developers, we can have ubuntu 16.04 for all developers. We can use base image for this and then update according to our requirements.

```shell
docker images # see list of images available locally
docker pull ubuntu:16.04 # pull ubuntu:16.04 image
docker images # docker image Id is also like docker image name
docker run ubuntu:16.04 # repository:tag
docker run a5123badfs35 # same as above using image id
docker images --no-trunc # full image id
mkdir onboarding
cd onboarding
vi dockerfile
```

```
FROM ubuntu:16.04
MAINTAINER piyushpatel2005@gmail.com
RUN apt-get update
RUN apt-get install python3 -y
```

```
FROM ubuntu:16.04
LABEL maintainer="piyushpatel2005@gmail.com"
RUN apt-get update
RUN apt-get install python3 -y
```

```shell
cd onboarding
docker build . # run docker build using docker file in this directory
docker image ls # same as docker images
docker run hello-world
docker container run hello-world
docker container run -it --name python-container 345lnk345lngd # run given image id in interactive mode.
cat /etc/issue
python3 
exit
```

```shell
docker images
docker container ls
docker container ls -a # shows previously run containers as well
docker container run -it ubuntu:16.04
exit # once we exit, container is no longer running
docker container ls
docker container start goofy_elgamal # provide container id or container name
exit
docker attach goofy_elgamal # use container name or image id
# now back in the environment
exit
docker container ls -a # container has now stopped.
docker container ls # see running containers
docker container ls -a
docker images
# If we don't need images
docker container rm <container_id>
docker container rm 234nl45jgsds 324lhut534k
docker container ls -a
docker images
docker rmi 345nsl43f4ds # remove docker image
docker login
docker images
# push image to docker hub
docker tag <image_id> piyushpatel2005/onboarding:v1 # now image tag must be updated in docker image
docker push piyushpatel2005/onboarding
docker rmi <image id> # image ids must be specified in order such that dependency should not be deleted.
docker pull piyushpatel2005/onboarding:v1
```

To open up the container port for local computer, we can have following.

```shell
docker container ls
docker container ls -a
docker images
docker cotnainer run -d nginx # run image in detached mode
docker image history nginx # will have EXPOSE command to expose port 80
docker container ls 
docker container inspect b62sdfo5ddf | grep IPAdd # get IP address of the container
sudo apt-get install elinks
elinks 172.17.0.2
elinks localhost # does not work
docker container run -d -P nginx
docker container ls # now port is mapped to port 80 of container. It uses ephemeral port range from 32768 to 61000
docker container run -d -p 80:80 httpd
curl -4 icanhazip # get the IP of existing system
elinks <host_ip> # we default default apache httpd page
docker container ls
```

Docker volumes is the preferred way to store generated data from docker containers.

```shell
docker volume ls # list the volumes for any container
docker volume create devvolume
docker volume ls
docker volume inspect devvolume # inspect the creation date and location
# mounting a volume to a container
docker container run -d --name devcontainer --mount source=devvolume,target=/app nginx
docker container ls
docker container inspect devcont # inspect if the volume has been mounted under Mounts
sudo ls /var/lib/docker/volumes/devvolume/_data # location on the volume
docker container exec -it devcont
ls
echo "hello" > /app/hello.txt
ls /app
exit
sudo ls /var/lib/docker/volumes/devvolume/_data
docker container stop devcont
docker container ls # make sure it's stopped
docker container rm devcont
sudo ls /var/lib/docker/volumes/devvolume/_data # file is still there
docker containre -d --name devcont2 -v devvolume:/app nginx
docker container exec -it devcont2 sh
ls /app # it's mounted to the same location
```

Earlier in the history, it started with `chroot` command which changes root.

[Docker Notes](docker/notes)

[Creating automated deployments using Travis](examples/frontend/automated-ci.md)

[Multiple container deployment](examples/complex)