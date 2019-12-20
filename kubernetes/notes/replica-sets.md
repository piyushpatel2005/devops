# Replica Sets

Mostly, you want multiple replicas of a container running at a particular time. You need multiple replicas for redundancy (fault tolerance), scaling, sharding, etc. We can manually create multiple pods, but doing so is tedius and error-prone. A **replica set** acts as a cluster-wide Pod manager, ensuring that the right types and number of Pods are running at all times. Pods managed by ReplicaSets are automatically rescheduled under certain failure conditions. When we define ReplicaSet, we define a specification for the Pods we want to create and a desired number of replicas. The actual act of managing the replicated Pods is an example of **reconsiliation loop**. 

### Reconsiliation Loops

The central concept for this loop is the notion of desired state versus observed or current state. The reconciliation loop is constantly running, observing the current state and taking action to try to make the state match the desired state. The relation between ReplicaSets and Pods is loosely coupled. ReplicaSets create and manage Pods, they do not own the Pods they create. ReplicaSets are label queries to identify the set of Pods they should be managing. They then use the same Pod API to create the Pods that they are managing. Having decoupled ReplicaSets from Pods gives us opportunity to debug sick Pods by modifying or removing their labels. ReplicaSet will recreate a new copy and we can debug sick Pod using interactive debugging.

Every Pod created by ReplicaSet controller is homogeneous. These Pods are then fronted by a Kubernetes service load balancer which spreads traffic across the Pods that make up the service. The elements created by ReplicaSet are interachangeable. All ReplicaSets must have a unique name, a spec that describes the number of Pods that should be running clusterwide and a Pod template that describe the Pod to be created when the defined number of replicas is not met.

[replica set template](../examples/manifests/kuard-rs.yaml) shows example ReplicaSet. The Pods are created using a Pod template that is contained in the ReplicaSet specification. ReplicaSet controller creates and submits a Pod manifest based on the Pod template to API server.

ReplicaSets monitor cluster state using a set of Pod labels. When initially created, ReplicaSet fetches a Pod listing from the Kubernetes API and filters the results by labels. The labels used for filtering are defined in the ReplicaSet spec section.

### Creating ReplicaSet

ReplicaSets can be created using a configuration file and `kubectl apply` command.

```shell
kubectl apply -f kuard-rs.yaml # create single instance of kuard pod
kubectl get pods # ensure the number of pods
kubectl describe rs kuard # describe replica set
```

If you want to find which ReplicaSet is managing a particular Pod, ReplicaSet controller adds an annotation to every Pod it creates. The key for this annotation is `kubernetes.io/created-by`.

`kubectl get pods <pod-name> -o yaml`

### Scaling ReplicaSets

ReplicaSets are scaled up or down by updating `spec.replicas` key on ReplicaSet object stored in Kubernetes. The easiest way to achieve this is using the `scale` command as `kubectl scale replicasets kuard --replicas=4`.

With such command, it is important to update the text configuration file to match the number of replicas that you set with this command.

Declaratively, edit the `kuard-rs.yaml` file and set the replicas count to 3. Then, you can use `kubectl apply -f kuard-rs.yaml` and ReplicaSet controller will detect the number of desired Pod has changed and will take action to meet the needs. Ensure it matches using `kubectl get pods`.

In some cases, you may want to scale in response to custom application metrics. Kubernetes can handle **autoscaling** via Horizontal Pod Autoscaling (HPA). HPA requires the presence of the heapster Pod on your cluster. heapster keeps track of metrics and provides an API for consuming metrics that HPA uses  when making scaling decisions. You can validate its presence by listing the Pods in the `kube-system` namespace using `kubectl get pods --namespace=kube-system`. There should be Pod named `heapster` in that list. Without this, autoscaling will not work correctly. Vertical scaling is not currently implemented in Kuberntes, but is planned.

To scale a ReplicaSet based on CPU usage use, `kubectl autoscale rs kuard --min=2 --max=5 --cpu-percent=80`. This command creates an autoscaler that scales between two to five replicas with a CPU threshold of 80%. Check `kubectl get hpa` or `kubectl get horizontalpodautoscalers`. It is bad idea to combine both autoscaling and imperative or declarative management of the number of replicas. If both you and autoscaler are attempting to modify the number of replicas, it will result in unexpected behavior.

Delete the ReplicaSets using `kubectl delete rs kuard`. If you only want to delete the ReplicaSet and don't want to delete Pods managed by it, you can use `--cascade` flag.

`kubectl delete rs kuard --cascade=false`

# Deployments

The Deployment object manages the release of new versions of containers. They enable you to easily move from one version of your code to next. This rollout process is specifiable and careful. It also uses health check to ensure that the new version is operating correctly and stops the deployment if too many failures occur. The actual mechanisms of software rollout performed by a deployment is controlled by a deployment controller that runs in Kubernetes cluster. Deployment can be represented by a declarative YAML object. Check [deployment](../examples/manifests/kuard-deployment.yaml) requesting a single instance of the kuard application.

Run `kubectl create -f ../examples/manifests/kuard-deployment.yaml`

Deployments manage ReplicaSets using labels and label selector.

```shell
kubectl get deployments kuard \
    -o jsonpath --template {.spec.selector.matchLabels}
# With above command we get that kuard deployment is managing ReplicaSet with label `run=kuard`
# find that specific replica set
kubectl get replicasets --selector=run=kuard # there is only one running
# we can resize the deployment using the scale command on deployment
kubectl scale deployments kuard --replicas=2
kubectl get replicasets --selector=run=kuard # we see 2 running
# Scaling the deployment also scales ReplicaSet it controls
# Rescale ReplicaSet now
kubectl scale replicasets kuard-<number> --replicas=1
kubectl get replicasets --selector=run=kuard # still shows 2
```    

When we scale ReplicaSet to one replica, it still has two replicas. The top-level Deployment object is managing this ReplicaSet. When we rescaled ReplicaSet to one, the dpeloyment controller notices this and takes corrective action to match the desired state and adjusts the number of replicas back to two. If you want to manage ReplicaSet directly, you need to delete the deployment using `--cascade=false`.

```shell
kubectl get deployments kuard --export -o yaml > kuard-deployment.yaml
kubectl replace -f kuard-deployment.yaml --save-config
```

`--save-config` option with `replace` adds an annotation so that when applying changes in the future, `kubectl` will know what the last applied configuration was for smarter merging of configs.

The deployment spec looks similar to ReplicaSet spec. The `strategy` object dictates the different ways in which a rollout of new software can proceed. There are two different strategies `Recreate` and `RollingUpdate`. You can get details info about the deployment using `kubectl describe deployments kuard`. We can see OldReplicaSets and NewReplicaSets. If the deployment is in the midlde of a rollout, bothe fields will be set to a value. Once the rollout is complete, the OldReplicaSets will be set to <none>. We can use `kubectl rollout history` to get history of rollouts with a particular deployment. If deployment is in progress, use `kubectl rollout status`.

We can scale the deployment using `kubectl scale` or using YAML file and increasing number of replicas. Once we save and commit changes, we can update the deployment using `kubectl apply -f kuard-deployment.yaml`. The other possible update is roll out a new version of software running in one or more containers. For example, for updating the container image, you would change yaml to download new container image as below.

```yaml
containers:
- image: gcr.io/kuar-demo/kuard-amd64:green
    imagePullPolicy: Always
# ....
# add metadata for update notes
template: 
    metadata:
        annotations:
            kubernetes.io/change-cause: "Update to green kuard"
```

Do not change the `change-cause` as it will trigger a new rollout.

```shell
kubectl apply -f kuard-deployment.yaml
# monitor the rollout
kubeclt rollout status deployments kuard
kubectl get replicasets -o wide
# pause the rollout in the middle
kubectl rollout pause deployments kuard
# resume rollout
kubeclt rollout resume deployments kuard
# see deployment history, the revision history is given from oldest to newest
kubectl rollout history deployment kuard
# view details about a specific revision
kubectl rollout history deployment kuard --revision=2
```

Update the kuard deployment back to `blue` by modifying the container version number and updating the `change-cause` annotation and apply it using `kubectl apply`.

```shell
kubectl rollout history deployment kuard # there should be 3 entries
# roll back due to some issue in update
kubectl rollout undo deployment kuard
# check desired replica counts in RepicaSets
kubectl get replicasets -o wide
# check revision history, revision 2 is missing
kubectl rollout history deployment kuard
# roll back to revision 3
kubectl rollout undo deployments kuard --to-revision=3
kubectl rollout history deployment kuard
```

Better method to rollout back to earlier version is to change yaml file and update using `kubectl apply` command. You can also rollback to specific revision using `--to-revision` flag. By default, the complete revision history of a deployment is kept attached to the Deployment object. You should set a maximum history size for deployment revision history. If you daily update, you may limit revision history to 14, to keep a maximum of 2 weeks' revisions. To accomplish this, use the `revisionHistoryLimit` property in deployment specification.

```yaml
spec:
    revisionHistoryLimit: 14
```

### Deployment strategies

Kubernetes supports two different rollout strategies: Recreate and RollingUpdate.

The **Recreate** strategy simply updates the ReplicaSet it manages to use the new image and terminates all of the Pods associated with the deployment. The ReplicaSet recreates all Pods using the new image. It has a drawback that it is catastophic and will result in some site downtime. Therefore, this should only be used for test deployments where small downtime is acceptable.

The **RollingUpdate** strategy is preferred for user-facing service. It is slower than Recreate, it is sophisticated and robust. This strategy works by updating a few Pods at a time, moving incrementally until all Pods are running new version. For a period of time, both the new and old version of service will be receiving requests and serving traffic. This means each version of software should be capable of talking interchangeably with both a slightly older and a slightly newer version. This sort of backward compatibility is critical to decoupling service from systems that depend on your service. The rolling update is configurable and can be tuned to suit your needs. The `maxUnavailable` sets the maximum number of Pods that can be unavailable during a rolling update. It can be either absolute number or to a percentage. This parameter helps tune how quickly a rolling update proceeds. There are situations where you don't want to fall below 100% capacity, but you are willing to temporarily use additional resources to perform rollout. In this, you can set maxUnavailblae to 0% and control the rollout using the `maxSurge`. It controls how many extra resoruces can be created to achieve a rollout.

The purpose of staged rollout is to ensure that the rollout results in a healthy, stable service running the new software version.  The deployment controller always waits until a Pod reports that it is ready before moving on to updating the next Pod. We can set `progressDeadlineSeconds` to set the timeout for any stage of roll out. This is seconds in terms of deployment progress and not the overall length of a deployment.

Delete a deployment using 

```shell
kubectl delete deployments kuard
kubectl delete -f kuard-deployment.yaml
```

It will delete deployment as well as ReplicaSets and Podsd.

### Monitoring Deployment

When the deployment timesout, its status changes to failed state. This state can be obtained from `status.conditions` array.

# DaemonSets

one reason to replicate a set of Pods is to schedule a single Pod on every node within the cluster. This is used to land some set of agent on each node which is achieved using DaemonSets. A DaemonSet ensures a copy of a Pod is running across a set of nodes in a Kubernetes cluster. They are used to deploy system daemons such as log collectors and monitoring agents. They share similar functionality as ReplicaSets. ReplicaSet should be used when your application is completely decoupled from the node and you can run multiple copies on a give node without special consideration. DaemonSet shoudl be used when a single copy of an application must run on all or a subset of the nodes in cluster.

## DaemonSet Scheduler

By default, DaemonSet will create a copy of a Pod on every node unless a node selector is used. DaemonSets determine which node a Pod will run on at Pod creation time by specifying the nodeName field in the Pod spec. DaemonSets, like ReplicaSets, are managed by a reconciliation control loop that measures the desired state with the observed state. If a new node is added to the cluster, then the DaemonSet controller notices that it is missing a Pod and adds the Pod to the new node.

DaemonSets are created by submitting a configuration to kubernetes API server. The [example configuration](../examples/manifests/fluentd.yaml) will create `fluentd` logging agent on every node in target cluster. DaemonSets require a unique name across all DaemonSets in given namespace. Each DaemonSet must include a Pod template spec, which will be used to create Pods as needed.

```shell
kubectl apply -f ../examples/manifests/fluentd.yaml
# query its current state using
kubectl describe daemonset fluentdd
kubectl get pods -o wide
```

## Limiting DaemonSets to specific nodes

Node labels can be used to tag specific nodes with specific workload requirements and that can be used to deploy Pods on specific nodes using DaemonSets.

```shell
# Create ssd=true label on single node
kubectl label nodes ka0-default-pool-23423jnkl23 ssd=true
kubectl get nodes # list nodes
kubectl get nodes --selector ssd=true # ensure specific node is selected
```

Node selectors can be used to limit what nodes a Pod can run on in a given Kubernetes cluster. They are defined as part of the Pod spec when creating a DaemonSet.

```yaml
# nginx-fast-storage.yaml
apiVersion: extensions/v1beta1
kind: "DaemonSet"
metadata:
    labels:
        app: nginx
        ssd: "true"
    name: nginx-fast-storage
spec:
    template:
        metadata:
            labels:
                app: nginx
                ssd: "true"
        spec:
            nodeSelector:   
                ssd: "true"
            containers:
                - name: nginx
                    image: nginx:1.10.0
```

```shell
kubectl apply -f nginx-fast-storage.yaml
kubectl get pods -o wide # verify that only one node with nginx-fast-storage
```

If a label is removed from a node, the Pod will be removed by DaemonSet controller.

DamonSets can be rolled out using the same `RollingUpdate` strategy that deployments use. You can configure the update strategy using the `spec.updateStrategy.type` field with value `RollingUpdate`. Then, any change in `spec.template` field will initiate a rolling update. The parameter `spec.minReadySeconds` determines how long a Pod must be ready before the rolling update proceeds to upgrade subsequent Pods. The `spec.updateStrategy.rollingUpdate.maxUnavailable` indicates how many Pods may be simultaneously updated by the rolling update. Once a rolling update starts, you can use `kubectl rollout` commands to see the current status of DaemonSet rollout as `kubectl rollout status daemonSets my-daemon-set`.

To delete a DaemonSet use `kubectl delete -f fluentd.yaml`