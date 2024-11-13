# Creating your own Personal Docker Repository

Docker Registry holds and distributes Docker images. Docker hub is popular registry hosted by Docker, Inc.

Pushing an image requires user to be logged in.

```shell
docker pull centos
docker tag centos username/test:v1.0
docker push username/test:v1.0 # fails due to not logged in
docker login
docker push username/test:v1.0
```

## Creating Private Registry

For private registry, we first need the Docker installed.
After that, there is a service called `docker-distribution` which needs to be downloaded and started.



```shell
yum install docker-distribution
systemctl start docker-distribution
systemctl enable docker-distribution
```

Update the configuration file for this registry, i.e. define port where you can access this registry on this host at `/etc/docker-distribution/registry/config.yml`.

```yaml
version: 0.1
log:
  fields:
    service: registry
storage:
    cache:
        layerinfo: inmemory
    filesystem:
        rootdirectory: /var/lib/registry
http:
    addr: :5000
```

If you update, you may need to restart docker-distribution service

Next, add insecure Registry to Docker engine. Add the file `/etc/docker/daemon.json` to allow insecure registry using following content.

```json
{
  "insecure-registries": ["local.repo:5000"]
}
```

Restart docker engine for that to take effect using `systemctl restart docker`.
Add an entry into `/etc/hosts` with a line representing IP address and the hostname

`<public_ip_address_of_host>  local.repo`

You can validate this using `ping local.repo` command.
On this host, create a Docker image and tag it if you want to.

```shell
docker build -t app .
docker images
docker tag app:latest local.repo:5000/app:v1.0
docker images
docker push local.repo:5000/app
ls /var/lib/registry
curl -ik --user admin:admin123 http://local.repo:5000/v2/_catalog
```
