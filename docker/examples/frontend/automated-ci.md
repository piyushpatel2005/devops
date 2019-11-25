# Automating deployment using Git, Docker and Travis CI with AWS

We host a repository in Github. Create feature branch. Push code changes to feature branch. When we merge to master branch, it requests Travis CI to run some tests and then push the changes to AWS hosting.

We can run `npm run test` to run tests and `npm run build` to build the project.

For development, enter into project directory `docker/examples/frontend` and use following command.

```shell
docker build -f Dockerfile.dev .
docker run -p 3000:3000 <container_id> # container id is visible at the end
```

Although above commands work, when we edit our code, we need to redeploy the docker image to update the code inside container.