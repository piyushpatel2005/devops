# Pods, Labels and Annotations

## Pods

In real world deployments, you will often want to colocate multiple applications into a single atomic unit, scheduled onto a single machine. Still we want to avoid memory leak from on app affecting another. By separating two applications into two separate containers, we ensure reliable operations. Kubernetes groups multiple containers into a single atomic unit called a Pod (group of whales - symbol of Docker containers). Pods are the smallest deployable artifact in Kubernetes cluster. All containers in a pod therefore always land on the same machine. Each container within a Pod runs in its own cgroup, but they can share a number of Linux namespaces.
Applications in same Pod share the same IP addresses and por space, have same hostname and can communicate using native interprocess communication. Applications in different Pods are isolated, have different IP addresses, different hostnames, etc. 

The best question to ask when designing Pods is "Will these containers work correctly if they land on different machines?".If two containers interact via local file system, it both containers will need to be on the same pod.

Pods are described in a Pod manifest file. We write declarative configuration with desired state of the world in a configuration file and submit this configuration to a service to ensure desired state becomes actual state. Kubernetes API server accepts and processes Pod manifests before storing them in persistent storage (etcd). The scheduler uses the Kubernetes API to find Pods thta haven't been scheduled to a node and places the Pods on to nodes depending on the resources and constraints expressed in Pod manifests.  Multiple pods can be placed together as long as there are sufficient resources. Kubernetes scheduler tries to ensure that pods from the same application are distributed onto different machines for reliability. Once scheduled, Pods don't move and must be explicitly destroyed and rescheduled. ReplicaSets are for running multiple instances of a Pod. Once Pod run on a healthy node, it will be monitored by `kubelet` daemon process.

If we have an image at Google registry with `kuard-amd64:blue`, we can create a pod using

```shell
kubectl run kuard --generator=run-pod/v1 \
    --image=gcr.io/kuar-demo/kuard-amd64:blue
kubectl get pods
kubectl delete pods/kuard
```

## Create Pod Manifest file

Pod manifests can be written in YAML or JSON.

Check [Pod manifest file](../examples/manifests/kuard-pod.yaml)

```shell
kubectl apply -f ../examples/manifests/kuard-pod.yaml
kubectl get pods
kubectl describe pods kuard
# To delete a pod, either delete the pod by name
kubectl delete pods/kuard
# or by using the same file that used to create
kubectl delete -f ../examples/manifests/kuard-pod.yaml
```

By default, when we delete a pod, it will have a grace period of 30 seconds. when a Pod is deleted, data stored in the containers associated with Pod will be deleted. If you want to persist data across multiple instances of a Pod, you need to use PersistentVolumes.

To access the running app, we may use `kubectl port-forward kuard 8080:8080` and then we can access running app on local machine at port 8080. We can use `kubectl logs kuard` to view logs. If containers are continuously restarting, we can use `--previous` flag to get logs from a previous instance of the container.

We can run commands inside a container using `kubectl exec kuard date` or open an interactive session using `kubectl exec -it kuard bash`.

Kubernetes also introduced **health checks** to verify that the application is functioning properly. These are defined using Pod manifest file. Liveness probes are defined per container. For example, [liveness check](../examples/manifests/kuard-pod-health.yaml) has health check at `/healthy` path.

Kubernetes differentiates between liveness and readiness. Liveness determines if an application is running properly. Containers that fail liveness checks are restarted. Readiness describes when a container is ready to serve user requests. Containers that fil readiness checks are removed from service load balancers. Combining readiness and liveness probes helps ensure only healthy containers are running within cluster.

In addition to HTTP checks, Kubernetes supports tcpSocket health checks that open a TCP socket, if the connection is successful

### Resource Management

Ensuring that machines are maximally active increases the efficiency of the money spent. Utilization is measure defined as the amount of a resource actively being used divided by the amount of a resource that has been purchased. Kubernetes comes with resource management to optimally utilize resources. Resource limits specify the maximum amount of a resource that an application can consume.

With Kubernetes, a Pod requests the resources required to run its containers. Kubernetes guarantees that these resources are available to the Pod. These are called **resource requests**. For example, to request that kuard container lands on a machine with half a CPU free and gets 128 MB of memory allocated to it, we can define as below.

```yaml
apiVersion: v1
kind: Pod
metadata:
    name: kuard
spec:
    containers:
        - images: gcr.io/kuar-demo/kuard-amd64:blue
        name: kuard
        resources:
            requests:
                cpu: "500m"
                memory: "128Mi"
            ports:
                - containerPort: 8080
                name: http
                protocol: TCP
```

Kubernetes scheduler will ensure that the sume of all requests of all Pods on a node does not exceed the capacity of the node. 

In addition to setting the resources required by a Pod, you can also set a maximum on a Pod's resource usage via **resource limits**. To limit kuard pod with 1 CPU and 256MB max memory, we can add following.

```yaml
spec:
  containers:
    - image: gcr.io/kuar-demo/kuard-amd64:blue
    name: kuard
    resources:
      limits:
        cpu: "1000m"
        memory: "256Mi"
```


## Volumes

When a pod is deleted or restarts, data is also deleted. To add a volume to manifest file, we can use `spec.volumes` to define volumes as array. These are mounted to all containers. Second one is `volumeMounts` array that defines the volumes that are mounted into a particular container and path where it should be mounted. Two different containers in a Pod can mount the same volume at different paths.

```yaml
spec:
  volumes:
    - name: "kuard-data"
    hostPath: 
      path: "/var/lib/kuard"
  containers:
    - image: gcr.io/kuar-demo/kuard-amd64:blue
    name: kuard
    volumeMounts:
      - mountPath: "/data"
      name: "kuard-data"
    ports:
      - containerPort: 8080
      name: http
      protocol: TCP
```

An application can use shared volumes to share between two containers. This is the basis for communication between Git sync and web serving containers. To achieve this, the Pod uses an `emptyDir` volume.
Sometimes for truly persistent data that is independent of the lifespan of a particular pod, we can use wide variety of remote network storage volumes including NFS as well as cloud provider storages like Amazon's Elastic Block Store, Azure's Files and Disk Storage and Google's Persistent Disk.
Sometimes, we need access to host file system in order to perform. In these cases, Kubernetes supports `hostPath` volume which can mount arbitrary locations on worker node into the container.

There are numerous methods for mounting volumes over the network. 

```yaml
# NFS vollume mount example
volumes:
  - name: "kuard-data"
  nfs:
    server: my.dfs.server.local
    path: "/exports"
```


Check [kuard-pod full](../examples/manifests/kuard-pod-full.yaml)

## Labels and Annotations

Labels and annotations let you work in setes of things that map to how you think about your application. You can organize, mark and cross-index all resources to represent the groups that make the most sense.

**Labels** are key/value pairs that can be attached to Kubernetes objects such as Pods and ReplicaSets. They are useful for attaching identifying information to objects just like tags in cloud world. **Annotations** provide a storage mechanism that resembles labels designed to hold nonidentifying information that can be leveraged by tools and libraries.

### Labels

Labels are key/value pairs and keys can be broken down into two part: prefix and a name separated by slash. The key name must be shorter than 64 characters. 
We apply labels to two apps (alpaca and bandicoot) and have two environments for each.

```shell
# Create alpaca-prod deployment and set `ver`, `app` and `env` labels.
kubectl run alpaca-prod \
    --image=gcr.io/kuar-demo/kuard-amd64:blue \
    --replicas=2 \
    --labels="ver-1,app=alpaca,env=prod"
# Create the alpaca-test deployment
kubectl run alpaca-test \
    --image=gcr.io/kuar-demo/kuard-amd64:green \
    --replicas=1 \\
    --labels="ver=2,app=alpaca,env=test"
# Create prod and staging deployments
kubectl run badicoot-prod \
    --image=gcr.io/kuar-demo/kuard-amd64:green \
    --replicas=2 \
    --labels="ver=2,app=bandicoot,env=prod"
kubectl run bandicoot-staging \
    --image=gcr.io/kuar-demo/kuard-amd64:green \
    --replicas=1 \
    --labels="ver=2,app=bandicoot,env=staging"
kubectl get deployments --show-labels # 4 deployments
# update label on alpaca-test, add one more label
kubectl label deployments alpaca-test "canary=true"
kubectl get deployments -L canary
# remove a label using dash suffix
kubectl label deployments alpaca-test "canary-"
```

**Label selectors** are used to filter Kubernetes objects based on a set of labels.

```shell
kubectl get pods --show-labels
# select pods that have ver label set to 2.
kubectl get pods --selector="ver=2"
# If two labels are specified only objects that specify both will be returned
# This is like Logical AND operation
kubectl get pods --selector="app=bandicoot,ver=2"
# Get objects with selector in given set
kubectl get pods --selector="app in (alpaca,bandicoot)"
# give all pods with given label set with whatever value
kubectl get deployments --selector="canary"
```

We can use following operators to select specific pods.

| Operator | Description |
|:---------|:-------------|
| key=value | key is set to value |
| key!=value | key is not set to value |
| key in (value1,value2) | key is one of the values |
| key notin (value1,value2) | key is not one of the two values |
| key | key is set |
| !key | key is not set |

```shell
kubectl get deployments --selector='!canary'
kubectl get pods -l 'ver=2,!canary'
```

A selector of `app=alpaca,ver in (1,2)` would be converted to following yaml.

```yaml
selector:
  matchLabels:
    app:alpaca
    matchExpressions:
      - {key: ver, operator: In, values: [1,2]}
```

Labels also play a role in linking various related kubernetes objects. Objects need to rleated to one another and these relations are defined by labels and label selectors. For example, service load balancer finds the pods it should bring traffic to via a selector query. When people want to restrict network traffic to their cluster, they use NetworkPolicy in conjunction with specific labels to identify Pods that should or should not be allolwed to communicate with each other.

### Annotations

Annotations provide a place to store additional metadata for Kubernetes objects with the purpose of assisting tools and libraries. Annotations can be used for tool to pass configuration information between external systems. Annotations are used to provide extra information about where an object came from, how to use it or policy around that object. Annotations are used to:
- keep track of reason for the update to an object
- communicate a specialized scheduling policy to a specialized scheduler.
- extend data about the last tool to update the resource and how it was updated 
- enable deployment object to keep track of replicaSets that it is manging for rollouts.

Annotations are good for small bits of data that are highly associated with a specific resource. When defining annotations, namespace is important. Example keys include `deployment.kubernets.io/revision` or `kubernetes.io/change-cause`.

```yaml
metadata:
  annotations:
    example.com/icon-url: "https://example.com/icon.png"
```

clean up resources using `kubectl delete deployments --all`. To delete selectively, use `--selector` flag to choose.