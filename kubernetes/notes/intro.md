# Introduction to Kubernetes

Kuberenetes enableds developers to deploy their applications themselves and as often as they want without ops team. It also helps in monitoring and rescheduling those apps in the event of a hardware failure. Kubernetes is Greek for pilot or helmsman (the person holding the ship's steering wheel). Kubernetes abstracts away the hardware infrastructuer and exposes your whole datacenter as a single enormous computational resource. It allows to deploy and run software components without having to know about the actual servers underneath. Kuberenetes allows cloud providers to offer developers a simple platform for deploying and running any type of application, while not requiring any sysadmins to know anything about the apps running on their hardware.

Monolithic applications consist of components all tightly coupled together and have to be developed, deployed and managed as one entity because they all run as a single OS process. This requires a small number of powerful servers. If any part of a monolithic application isn't scalable, the whole application becomes unscalable unless we can split up the monolithic somehow. Each microservice runs as an independent process and communicates with other microservices through simple, well-defined interfaces. Microservices communicates through HTTP or through asynchronous AMQP protocol.

Kubernetes uses Linux container technologies to provide isolation of running applications. A process running in a container runs inside the host's operating system but the process in the container is still isolated from other processes. To run greater numbers of isolated processes on the same machine, containers are a better choice because of low overhead. Linux namespaces make sure that each process sees its own personal view of the system. The Linux Control groups (Cgroups) limit the amount of resources the process can consume. By default, each Linux system has one single namespace but we can create additional namespaces and organize resources across them. When running a process, we run it inside one of those namespaces. Multiple kinds of namespaces exist, so a process dosen't belong to one namespace, but to one namespace of each kind. The kinds of namespaces include mount(mnt), process ID (pid), Network (net), Inter-process communication (ipc), UTS, User ID(user). Each namespace kind is used to isolate a certain group of resources. 

### Docker

Docker is a platform for packaging, distributing and running applications. It allows to package application together with its whole environment. A Docker-based container **image** is something you package your application and its environment into. A Docker **registry** is a repository that stores Docker images and facilitates easy sharing of those images between different people and computers. A **container** is a regular Linux container created from a Docker-based container image. A runnint container is a process running on the host running Docker but isolated from both the host and all other processes running on it. **rkt** (rock-it) is Linux container engine which is a platform for running containers. It uses the OCI container image format and can even run regular Docker container images.

## Kubernetes Intro

Google realized that as number of deployable application components grew, it needed better way of deploying and managing their software components anf infrastructure to scale globally.

Kubernetes is a software system that allows you to easily deploy and manage containerized applications. Because these apps run on containers, they don't affect other apps running on the same server. This is very important for cloud providers as they strive for the best possible utilization of their hardware. Kubernetes enables to run software applications on thousands of computer nodes as if all were a single, enormous computer. It abstracts away the underlying infrastructure. Cluster nodes represent an additional amount of resources available to deployed apps.

Kubernetes system is composed of a master node and any number of worker nodes. When developer submits a list of apps to the master, Kubernetes deploys them to the cluster of worker nodes. What node a components lands on doesn't matter. The developer can specify that certain apps must run together and Kubernetes will deploy them on the same worker node. Kubernetes can be thought of as an operating system for the cluster. It relieves application developers from having to implement certain services into apps. This includes things like service discovery, scaling, load-balancing, self-healing and even leader election. Kubernetes will run containerized app somewhere in the cluster, provide information to its components on how to find each other, and keep all of them running. Kubernetes can relocate the app at any time and achieve far better resource utilization than is possible with manual scheduling.

### Architecture

Kubernetes cluster is composed of many nodes: The *master* node which hosts the Kubernetes Control Plane that controls and manages the whole Kubernetes system and the *worker* nodes that run the actual applications we deploy.

The **Control Plane** is what controls the cluster and makes it functions. It contains multiple components that can run on a single master node or be split across multiple nodes and replicated to ensure high availability. The components of Control Plane hold and control the state of the cluster, but don't run applications. These include
- Kubernetes API server which you and Control Plane components communicate with
- The Scheduler, which schedules apps (assigns a worker node to each deployable component of your application)
- The Controller Manager, which performs cluster-level functions, such as replicating components, keeping track of worker nodes, handling node failures and so on
- etcd, a reliable distributed data stoer that persistently store the cluster configuration.

The applications are run by the worker nodes. The task of running, monitoring and providing services to your applications is done by following components:
- Docker, rkt or another container runtime which runs the containers.
- The Kubelet, which talks to the API server and manages containers on its node.
- The Kubernetes Service Proxy (kube-proxy), which load-balances network traffic between application components.

To **run an application** in Kubernetes, you first need to package it up into one or more container images, push those images to an image registry and then post a description of your app to the Kubernetes API server. The description includes information such as the container image or images that contain application components and how those are related to each other.

When the API server processes your app's description, the Scheduler schedules the specified groups of containers onto the available worker nodes based on computational resources required by each group and the unallocated resources on each node at that moment. The Kubelet on those nodes then instructs the Container Runtime to pull the required container images and run the containers. The container groups are called pods. Single pod may have multiple containers co-located and shouldn't be isolated from each other. The app descriptor lists containers grouped into pods. They may have multiple replicas of each pod that need to run in parallel. After submitting descriptor to Kubernetes, it will schedule the specified number of replicas of each pod to the available worker nodes. The Kubelets on nodes tell Docker to pull the container images from image registry and run the containers. Once the application s running, Kubernetes continuously makes sure that the deployed state of the application always matches the description we provided. For example, if one of the web server stops working, Kubernetes will restart it automatically.

If we want to **scale up**, Kubernetes will spin up additional ones or stop the excess ones. We can even leave the job of deciding the optimal number of copies to Kubernetes. It can automatically adjust the number, based on real-time metrics such as CPU load, memory consumption, etc.

To allow clients to easily find containers that provide a specific service, you can tell Kubernetes which containers provide the same service and Kubernetes will expose all of them at a single static IP address and expose that address to all applications running in the cluster. This is through environment variables, but clients can also look up the service IP through DNS. The kube-proxy will make sure connectiosn to the servie are load balanced across all the containers that provide the service. The IP address of service stays constant, so clients can connect to its containers, even when they're moved around the cluster if a node has failed.

As Kubernetes exposes all its worker nodes as a single deployment platform, application developers can start deploying application on their own without knowing about the servers that make up the cluster.

When you tell Kubernetes to run your application, you're letting it choose the most appropriate node to run application based on the description of the application's resource requirements and the available resources on each node. The ability to move applications around the cluster at any time allows Kubernetes to utilize the infrastructure much better than what you can achieve manually. 

Kubernetes monitors your app components and the nodes they run on and automatically reschedules them to other nodes in the event of a node failure. If your infrastructure has enough spare resources to allow normal system operation even without the failed node, the ops team doesn't even need to react to the failure immediately.

Kubernetes can also **auto scale** to keep adjusting the number of running instances of each application. If Kubernetes is running in cluster, it can automatically scale the whole cluster size based on the needs of the deployed applications.

## Docker and Kubernetes

For these steps, install Docker by following instructions on Docker website.

```shell
docker run busybox echo "Hello World"
```

Create simple app which will print server hostname. 