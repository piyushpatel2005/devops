# Specify a base image
FROM alpine

# Download and install a dependency
RUN apk add --update redis

# Tell image what to do when it starts as a container
CMD ["redis-server"]

# Once you run docker build .
# You get the id of build number
# docker run <build-id>
# docker build -t <username>/redis:latest .
# docker run <username>redis