# Automating deployment using Git, Docker and Travis CI with AWS

## Using Docker for development environment

We host a repository in Github. Create feature branch. Push code changes to feature branch. When we merge to master branch, it requests Travis CI to run some tests and then push the changes to AWS hosting.

We can run `npm run test` to run tests and `npm run build` to build the project.

For development, enter into project directory `docker/examples/frontend` and use following command.

```shell
docker build -f Dockerfile.dev .
docker run -p 3000:3000 <image_id> # container id is visible at the end
```

Although above commands work, when we edit our code, we need to redeploy the docker image to update the code inside container.

```shell
docker run -p 3000:3000 -v /app/node_modules -v $(pwd):/app <image_id>
# /app/node_modules are present in container but not in local system, that's why we need to bookmark this 
# so that it doesn't map to empty location in host system
# It means don't try to change its mapping to host system.
```

To override existing command in the Docker container, we can add that new command to the docker run command like `docker run <image_id> npm run test` or `docker run -it <image_id> npm run test` to see the output from the container.

To run automated tests as soon as test file is updated, we can attach to existing service `web` and run tests.

```shell
docker ps # get id of the running container using docker-compose up
docker exec -it <container_id> npm run test
```

This is not an easy solution, so better option is to use `docker-compose.yml` file. We add a new service of `tests` and then run `docker-compose up --build`.

Docker compose doesn't allow us to attach to the terminal and run extra commands. For deploying app, we use nginx container. We copy only `build` directory to serve our app. This will have two sections, one for building the application and another for deploying to nginx.

At the end, we can test using:

```shell
docker bulid .
docker run -p 8080:80 <image_id>
```

Create Git repository and set up code with Dockerfile on Git repository.
Now create an account on TravisCI. Travis can lookup code changes in Github repository and Travis will run tests and once tests pass Travis can deploy to AWS.

To instruct Travis, we need to use Travis YAML (`.travis.yml`) file. 
Create Docker environment using Amazon Elastic Beanstalk.
To deploy our app once tests pass on Travis , we have to add another section `deploy` to travis file. 
Search for IAM, click User, Add User and make a user `docker-reac-travis-ci`, provide programmatic access. Click Next, Attach Existing policies directly and grant full access to AWS Elastic Beanstalk, Review and Create user. Write down Access Key ID and Secreat Access Key. In Travis-CI website, find repos and create Environment variables for AWS (AWS_ACCESS_KEY and AWS_SECRET_KEY)