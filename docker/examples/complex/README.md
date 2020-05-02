# Complex Application Deployment

This is simple Fibonacci number calculator where React client (client) sends requests to Express server (server). Once request is received, it is lookedup in Postgres, if it's not found, it goes through Redis to worker process to calculate fibonacci number.

If we make changes to our source code, we don't want to make new image. For that we will mount volumes.

```shell
cd client;
docker build -f Dockerfile.dev .
docker run <container_id>
cd server
docker build -f Dockerfile.dev .
cd ../worker
docker build -f Dockerfile.dev .
```

For setting up environment variables, `variable=value` sets the variable in  the container at run time. It is used only when image is started whereas `variableName` sets a variable in the container at run time and the value is taken from host computer.

In this setup, Express server is listening on port 5000 and React frontend is listening on server 3000. Nginx will redirect all requests to `/api` to Express server and all requests without `/api` will be redirected to React server. Nginx will listen on port 80 inside container.