This app contains two docker containers interacting with each other to serve web applicaiton.

One is node server
Another is redis server.

```shell
docker build -t piyushpatel/visits:latest .
docker run redis # create redis server
``` 

Both containers cannot communicate unless we set up networking between two containers. We can do this using Docker CLI or using Docker compose.

Docker compose allows to avoid lots of repetitive commands when recreating the same environment. In docker compose, we specify containers we want to create, which ports we want to map to host. When we define servies in the same yaml file, it will create networking between the two containers. We don't need to explicitly declare port mapping between the two containers.

```shell
docker-compose up
```

If you want to rebuild images (source code changes for your application), use `docker-compose up --build`.
To launch all containers in background `docker-compose up -d`.
To stop all the containers use `docker-compose down`.
We can specify restart policy as 'no', 'always', 'on-failure' or 'unless-stopped'.