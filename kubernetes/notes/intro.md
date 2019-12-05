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

Containers and Kubernetes encourage developers to build distributed systems that adhere to the principles of immutable infrastructure. In an immutable system, rather than a series of incremental updates and changes, an entirely new, complete image is built where the update simply replaces the entire image with newer in a single operation. This way old image is still there and if something goes wrong, we can easily rollback. It uses declarative configuration. In an declartive configuration you define state where as in imperative configuration, we define set of actions. Following are the features and advantages of Kubernetes.

- Declarative configuration
- Immutable
- Decoupled application architecture
- Easy scaling for applications and clusters
- Separation of concerns for consistency and scaling

Kubernetes has numerous abstractions and APIS to make services decoupled.
- Pods or groups of containers can group together container images developed by different teams into a single deployable unit.
- Services provide load balancing, nameing and discovery to isolate one microservice from another.
- Namespaces provide isolation and access control so that each microservice control the degree to which other services interact with it.
- Ingress objects provide an easy to use frontend that can comibine multiple microservices into a single externalized API surface area.

For these steps, install Docker by following instructions on Docker website.

```shell
docker run busybox echo "Hello World"
```

Create simple app which will print server hostname. 

```shell
cd ../examples/first-app;
docker build -t kubia .
docker images
docker run --name kubia-container -p 8080:8080 -d kubia
curl localhost:8080
docker ps # list running containers
docker inspect kubia-container
docker stop kubia-container
docker ps -a
docker rm kubia-container
```

When we run `docker build`, all the files in that directory are uploaded to the daemon. Don't include any unnecessary files in the build directory because it may take longer to upload those files especially if Docker daemon is no a remote machine. Open `http://localhost:8080/` to see hostname of the Docker container. We can also look up hostname or IP of the VM running the daemon using DOCKER_HOST environment variable.

```shell
docker tag kubia <username>/kubia
docker images
docker push <username>/kubia
```

A proper Kubernetes installation spans multiple physical aor virtual machines and requires the networking to be set up propertly so that containers running inside the Kubernetes cluster can connect to each other through the same flat networking space. Kubernetes can be run on local machine, cluster of machiens or on cloud services. Another option covers installing a cluster with `kubeadm` tool.

The simplest and quickest path to a fully functioning Kubernetes cluster is by using Minikube. Minikube is a tool that sets up a single node cluster locally. Install Minikube using its instructions on repository. To interact with Kubernetes, also need the `kubectl` CLI client.

```shell
# Start minikube
minikube start
kubectl version
# verify cluster is working
kubectl cluster-info
# list all nodes in cluster
kubectl get nodes
# get details about a node
kubectl describe node <node_name>
# get description of all nodes
kubectl describe node # without explicit name of node
```

To work easily with kubernetes, we can set alias for kubectl using `alias k=kubectl` in `~/.bashrc` file. To enable auto completion using TAB character, we need to add following to `.bashrc` file.

```shell
source <(kubectl completion bash)
# to enable auto completion for even alias use following
source <(kubectl completion bash | sed s/kubectl/k/g)
```

Usually to deploy an app on Kubernetes, a JSON or YAML manifest file is created which contains description of all components you want to deploy.

```shell
kubectl run kubia --image=piyushpatel2005/kubia --port=8080 --generator=run/v1
```

Here, `--image` specifies the image you want to run, `--port` tells kubernetes that app is listening on port 8080.

Kubernetes doesn't deal with individual containers directly. It uses the concept of multiple co-located containers, called **pod**. A pod is a group of one or more tighly related containers that will always run together on the same worker node and in the same Linux namespaces. Each pod is like a separate logical machine with its own IP, hostname, processes running a single application. All containers in a pod will appear to be running on the same logical machine. One pod may contain more than one containers and each worker node can run more than one pod.

```shell
# list pods
kubectl get pods
# describe pod with its information
kubectl describe pod <pod_name>
```

Each pod gets unique IP address but that is internal to the cluster and isn't accessible from outside. To make pod accessible from outside, we need to expose it through a Service object. In earlier versions, we could expose ReplicationController using

```shell
kubectl expose rc kubia --type=LoadBalancer --name kubia-http
# OR in newer versions it is replica set and deployments, try
kubectl get deployments
# If you see kubia here, then try following
kubectl expose deployment kubia --type=LoadBalancer --name kubia-http
# list whether the service is created with external ip address
kubectl get services
# We can also use shortcut names
kubectl get svc
# If running minikube cluster, use
minikube service kubia-http
```

Once Load Balancer service kubia-http is assigned external IP address, we can use `<IPADDrESS>:8080` to access the web app. Here we declaratively tell kubernetes to expose the deployment and it does it.

A pod may disappear at any time for any reason (node may fail or someone deleted the pod). Then new pod is automatically created. This pod gets a new IP address. When a service is created, it gets a static IP address which never changes during the lifetime of the service. Instead of connecting to pods directly clients should connect to the service through its constant IP address. Requests to IP and port of the service will be forwarded to the IP and port of one of the pods belonging to the servie at that moment.

### Scaling application

Try how many replicas have been created using following and scale up

```shell
kubectl get replicationcontrollers
kubectl get deployments
kubectl scale rc kubia --replicas=3
kubectl scale deployment kubia --replicas=3
# check how many deployments appear
kubectl get deployments
kubectl get pods
# get deailed information on all pods
kubectl get pods -o wide
# check dashboard with minikube
minikube dashboard
# In production cluster, use
kubectl cluster-info | grep dashboard
# Stop minikube cluster
minikube stop
# Remove cluster
minikube delete
```

kubectl is the tool for interacting with the Kubernetes API.

```shell
# get client and server API version
kubectl version
# get a simple diagnostic for the cluster
# displays components that make up the kubernetes cluster
kubectl get componentstatuses
```

The controller-manager is responsible for running various controllers that regulate behavior in the cluster, ensuring that all replicas of a service are available and healthy. The scheduler is responsible for placing different pods onto different nodes in the cluster. Finally the etcd server is the storage for the cluster where all of the API objects are stored.

```shell
# list nodes in cluster
kubectl get nodes
# describe more information about a specific node such as node-1
kubectl describe nodes node-1
```

## Kubernetes Components

Kubernetes components are also deployed using Kubernetes. All these components run in the kube-system namespace.

**Kubernetes proxy** is responsible for routing network traffic to load-balanced services in the Kubernetes cluster. For this, proxy must be present on every node in the cluster. If cluster runs the Kubernetes proxy with a DaemonSet, we can see the proxies by using `kubectl get daemonSets --namespace=kube-system kube-proxy`.

Kubernetes runs a **DNS server** which provides naming and discovery for the services that are defined in the cluster. This DNS server runs as a replicated service on the cluster. DNS service is run as a Kubernetes deployment which manages its replicas. There is also kubernetes service that performs load balancing for DNS server.

```shell
kubectl get deployments --namespace=kube-system core-dns
kubectl get services --namespace=kube-system core-dns
```

**Kubernetes UI** is GUI that run as a single replica but is managed by a Kubernetes deployment for reliability and upgrades.

```shell
kubectl get deployments --namespace=kube-system kubernetes-dashboard
# Dashboard also has a service that performs load balancing
kubectl get services --namespace=kube-system kubernetes-dashboard
# To access this UI, use kubectl proxy
kubectl proxy
```

## Kubernetes Commands

Kubernetes uses **namespaces** to organize objects in the cluster. By default, the `kubectl` command interacts with the default namespace. To use specific namespace, you can pass the `--namespace` flag. If you want to change the default namespace more permanently, you can use a context. This gets recorded in the kubectl configuration file usually located in `$HOME/.kube/config`. This configuration also stores how to find and authenticate to your cluster.

```shell
# create a context with a different default namespace
kubectl config set-context my-context --namespace=mystuff
# To use this newly create context
kubectl config use-context my-context
```

Contexts can also be used to manage different clusters or different users for authenticating to clusters using `--users` or `--clusters` flag with `set-context`.

The most basic command for viewing kubernetes objects is `get`. If you run `kubectl get <resource-name>` you will get a listing all resources in current namespace. If you want to get a specific resource, you can use `kubectl get <resource-name> <obj-name>`. To get more information use `-o wide` flag. To view complete object, view the objects as JSON or YAML, use `-o json` or `-o yaml` flags. If we use `--no-headers` flag, `kubectl` will skip the headers at the top of table. kubectl uses the JSONPath query language to select fields in the returned object. For example, to get IP address of the specified Pod, use `kubectl get pods my-pod -o jsonpath --template={.status.podIP}`. To get more detailed information about a particular object ,use `kubectl describe <resource-name> <obj-name>`.

Objects in Kubernetes API are represented as JSON or YAML files. These YAML or JSON files can be used to create, update or delete objects on Kubernetes server. You can use kubectl to create object by running `kubectl apply -f obj.yaml`. Similarly, after making changes to the object, you can use same command to update the object. The apply tool will only modify objects that are different from the current objects in the cluster. You can use `--dry-run` to print the objects to the terminal without actually sending them to the server. To make interactive edits use `kubectl edit <resource-name> <obj-name>`

The apply command also records the history of previous configurations in an annotation within the object. To show the last state that was applied to the object, use `kubectl apply -f myobj.yaml view-last-applied`.

To delete an object, use `kubectl delete -f obj.yaml`.
Similarly, you can delete an object using `kubectl delete <resource-name> <obj-name>`.

**Labels and annotations** are tags for objects. For example, to add the `color=red` label to a Pod named bar, use `kubectl label pods bar color=red`. By default, label and annotate will not let you overwrite an existing label. To do this, you can use `--overwrite` flag.

To remove a label, use `<label-name>-` like `kubectl label pods bar color-`. `annotate` command is similar to `label` command.

To view logs for a running container, use `kubectl logs <pod-name>`.
If you have multiple containers in Pod, you can choose the container to view using the `-c` flag. To continuously stream the logs back to the terminal without exiting, you can add `-f` flag.

To execute a command in a running container use `kubectl exec -it <pod-name> -- bash`. This will open interactive shell inside the running container for debugging.
You can attach to the running process using `kubectl attach -it <pod-name>`. This will attach to the running process.
You can also copy files from and to a container using cp command `kubectl cp <pod-name>:</path/to/file> </path/to/local/file>`. This will copy a file from running container to local machine.

If you want to access your Pod via network, you can use the `port-forward` command to forward network traffic from local machine to the pod. This securely tunnels network traffic through to containers that might not be exposed anywhere on public network.

`kubectl port-forward <pod-name> 8080:80` forwards traffic from the local machien on port 8080 to remote container on port 80. We can use `port-forward` with services by specifying `services/<service-name>` instead of `<pod-name>`.

To see resources usage, you can use `kubectl top nodes` or `kubectl top pods`. By default, these will display total CPU and memory in current namespace. You can add `--all-namespaces` to see resource usage by all Pods in the cluster.