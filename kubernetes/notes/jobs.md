# Jobs

A job creates Pods that run until successful termintaion. Jobs are useful for things you only want to do once.

The **Job object** is responsible for creating and managing Pods defined in a template in the job specification. These Pods runn until successful completion. The Job object coordinates running a number of Pods in parallel. If the Pod fails before a successful termination, the job controller will create a new Pod based on the Pod template in the job specification.

Jobs are designed to manage batch like workloads where work items are processed by one or more Pods. By default, each job runs a single Pod once until successful termination. This job pattern is defined by two attributes of a job, the number of job completions and the number of Pods to run in parallel. For "run once until completion" pattern, the `completions` and `parallelism` parameters are set to 1.

| Type | Use Cases | Behavior | Completions | Parallelism |
|:-----|:---------|:-----------|:-----------|:------------|
| one shot | Database migrations | A single pod running once until successful termination | 1 | 1 |
| Parallel fixed completions | Multiple Pods processing a set of work in parallel | One or more Pods running one or more times until reaching fixed completion count | 1+ | 1+ |
| Work queue: parallel jobs | Multiple Pods processing from a centralized work queue | One ore more Pods running once until successful termination | 1 | 2+ |

**One shot** jobs provides a way to run a single Pod once until successful termination. Pod is created and submitted to the Kubernetes API using a Pod template defined in job configuration. Once a job is up and running, the Pod must be monitored for successful termination. If job fails, the job controller is responsible for recreating the Pod until a successful termination occurs.

```shell
kubectl run -i oneshot \
    --image=gcr.io/kuar-demo/kuard-amd64:blue \
    --restart=onFailure \
    -- --keygen-enable \
      --keygen-exit-on-complete \
      --keygen-num-to-gen 10
```

The `-i` option indicates that this is interactive command. The `--restart=onFailure` tells kubectl to create a Job object. All other options after `--` are command-line arguments to container image. After the job has completed, the Job object and related Pod are still around to inspect the log output.

```shell
kubectl get jobs 
kubectl get jobs -a # shows finished jobs too
kubectl delete jobs oneshot # delete the job
```

Another option to create a job is using [configuration file](../examples/manifests/job-oneshot.yaml).

```shell
kubectl apply -f ../examples/manifests/job-oneshot.yaml
kubectl describe jobs oneshot
kubectl logs oneshot-4kfdt
```

Because jobs have a finite beginning and ending, it is common for users to create many of them. It makes picking unique labels difficult. For this reason, the Job object will automatically pick a unique label and use it to identify the Pods it creates.

When a Pod fails, Kubernetes will wait a bit before restarting the Pod to avoid a crash loop eating resources on the node. This is handled by kubelet without the Job being involved. Modify the config file and change `restartPolicy` to Never. By setting restartPolicy to Never, we are telling the kubelet not to restart the Pod on failure but rather just declare the pod as failed. The Job object then notices and creates a replacement Pod. Therefore, it should be `restartPolicy: OnFailure`. Remove this using `kubectl delete jobs oneshot`.

Use `completions` and `parallelism` to adjust number of workers running together. Check [parallel job](../examples/manifests/job-parallel.yaml).

To start the parallel jobs 

```shell
kubectl apply -f ../examples/manifests/job-parallel.yaml
kubectl get pods -w
```

Use case for jobs is to process work from a work queue. Some task creates a number of work items and publishes them  to a work queue. A worker job can run to process each work item until the work queue is empty. 

We can launch a work queue service. `kuard` acts as a coordinator for all work to be done.

```shell
kubectl apply -f rs-queue.yaml
QUEUE_POD=$(kubectl get pods -l app=work-queue,component=queue -o jsonpath='{.items[0].metadata.name}'  )
kubectl port-forward $QUEUE_POD 8080:8080
```

Now, we can access `http://localhost:8080`. This work queue is exposed using [service](../examples/manifests/service-queue.yaml)

`kubectl apply -f service-queue.yaml` 

Check [job consumer configuration](../examples/manifests/job-consumers.yaml) file. Here, the job starts five Pods in parallel. Once the first Pod exits with a zero exit code, the job will start winding down and will not start any new Pods.

```shell
kubectl apply -f job-consumers.yaml
kubectl get pods
kubectl delete rs,svc,job -l chapter=jobs
```

## CronJobs

If you want to schedule a job to run at certain interval,you can use CronJob. CronJob looks like below.

```yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: example-cron
spec:
  # Run every 5th hour
  schedule: "0 */5 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: batch-job
            image: my-batch-image
          restartPolicy: OnFailure
```

# ConfigMaps and Secrets

ConfigMaps are used to provide configuration information for workloads. Secrets are more focused on making sensitive information available to workload.

## ConfigMaps

It provides set of variables that can be used when defining the environment or command line for container.

```shell
# myconfig.txt
parameter1 = value1
parameter2 = value2
```

```shell
kubectl create configmap my-config \
    --from-file=myconfig.txt \
    --from-literal=extra-param=extra-value \
    --from-literal=another-param=another-value
# YAML representation using 
kubectl get configmaps my-config -o yaml
``` 

The configmaps could be mounted into a Pod. The contents of that file are set to the value, to set environment variables dynamically.

Check [kuard config](../examples/manifests/kuard-config.yaml). With this one, we mount volumeMount at `/config` location.

```shell
kubectl apply -f kuard-config.yaml
kubectl port-forward kuard-config 8080
```

With this, if we see environment variables, there will be ANOTHER_PARAM and EXTRA_PARA?M values set via configmap.

## Secrets

For sensitive data like passwords, security tokens and other types of private keys, secrets are used. Secrets allow container images to be created without bundling sensitive data making containers portable across environments. Secrets are exposed to Pods via explicit declaration in Pod manifests and kubernetes API. By default, Kubernetes secrets are stored in plain text in etcd storage. Kubernetes also hasa support for encrypting the secrets with a user-supplied key. Secrets are created using the Kubernetes API or kubectl command line tool. They hold one or more data elements as key/value pairs. If we want to add TLS certificate to kuard image, we can use secrets.

The TLS key and certificate for the kuard application can be downloaded by using:

```shell
curl -o kuard.crt https://storage.googleapis.com/kuar-demo/kuard.crt
curl -o kuard.key https://stoarge.googleapis.com/kuar-demo/kuard.key
# create secret for certificate
kubectl create secret generic kuard-tls \
    --from-file=kuard.crt \
    --from-file=kuard.key
kubectl describe secrets kuard-tls
```

Now this `kuard-tls` secret could be consumed using a secrets volume from a Pod. To make Kubernetes applications portable, we can use secrets volume so that they can run unmodified on all platforms.

Secret data can be exposed to Pods using the **secrets volume** type. Secrets volumes are managed by kubelet and are create at Pod creation time. Secrets are stored on tmpfs volumes (RAM disks) and not written to disk on nodes. Each data element of a secret is stored in a separate file under the target mount point specified in the volume mount. The two data elements `kuard.tls` and `kuard.key` are stored in `/tls/kuard.crt` and `/tls/kuard.key` files if kuard-tls secrets volume is mounted to `/tls`. Check [kuard secret](../examples/manifests/kuard-secret.yaml) which declares a secret volume which exposes kuard-tls secret to kuard container under `/tls`.

```shell
kubectl apply -f kuard-secret.yaml
kubectl port-forward kuard-tls 8443:8443
```

Visit, `https://localhost:8443`

One of the use case of secrets is to **access credentials for private Docker registries**. Image *pull secrets* leverage the secrets API to automate distribution of private registry credentials. They are stored just like normal secrets but are consumed through `spec.imagePullSecrets` Pod specification field.

```shell
# Use create secret docker-registry to create thsi secret
kubectl create secret docker-registry my-image-pull-secret \
    --docker-username=<username> \
    --docker-password=<password> \
    --docker-email=<email-address>
```

If you are repeatedly pulling from the same registry, you can add the secrets to the default service account associated with each Pod to avoid having to specify the secrets in every Pod you create. The keys for configmaps and secrets can start with dot and can include underscores. Secret data values hold arbitrary data encoded using base64. It makes possible to store binary data. Maximum size for a ConfigMap or secret is 1MB.

```shell
# list all secrets
kubectl get secrets
# list all configmaps
kubectl get configmaps
kubectl describe configmap my-config
# see raw data 
kubectl get configmap my-config -o yaml
kubectl get secret kuard-tls -o yaml
```

The easiest way to create a secret or configmap is via ``kubectl create secret generic` or `kubectl create configmap`. There  are options for setting values for each of these.

- `--from-file=<filename>`: load from the file with the secret data key the same as filename
- `--from-file=<key>=<filename>`: load from the file with secret data key explicitly specified.
- `--from-file=<directory>`: load all the files in the specified directory where the filename is an acceptable key name.
- `--from-literal=<key>=<value>`: use the specified key/value pair directly.

If you have a manifest file for your configmap or secret, you can edit it directly and push a new version with `kubectl replace -f <filename>`. You can also use `kubectl apply -f <filename>`.
If you store the inputs into your config maps and secrets as separate files on disk, you can use kubectl to recreate the manifest and then use it to update the object.

```shell
kubectl create secret generic kuar-tls \
    --from-file=kuard.crt --from-file=kuard.key \
    --dry-run -o yaml | kubectl replace -f -
```

Here, we first create new secret with the same nname as our existing secret, we pipe that to replace command and replace command reads from stdin. This way, we can update a secret from iles on disk without having to manually base64-encode data. Yet another method to edit configmap is in editor using `kubectl edit configmap my-config`
Once a ConfigMap or secret is updated using API, it'll be automatically pushed to all volumes that use that configmap or secret.


# Role-Based Access Control

RBAC is critical to harden access to Kubernetes cluster and prevent unexpected accidents where one person in wrong namespace mistakenly takes down production when they think they are destroying their test cluster. Every request to Kubernetes is first authenticated. Once user have been properly identified, authorization determines whether they are authorized to perform request which is a combination of identify of user, the request and the action on the resource. If particular user is authorized for performing action on that resource, then the request is allowed to proceed otherwise an HTTP 403 error is returned.

### RBAC

Every request that comes to Kubernetes is associated with some identity. Even request with no identity is associated with the `system:unauthenticated` group. Service accounts are created and managed by Kubernetes itself and are generally associated with components running inside the cluster. User accounts are all other accounts associated with actual users of the cluster, and often include automation like continuous delivery as a service that runs outside of the cluster. Kubernetes uses generic interface for authentication providers. Each providers supplies a username and optionally the set of groups to which user belongs. Kuberenetes supports following authentication providers:
- HTTP Basic Authentication
- x509 client certificates
- Static token files on the host
- Cloud authenticated providers like Azure AD and AWS IAM
- Authentication webhooks

Once the system knows the identity of the request, it needs to determine if the request is authorized for that user. A **role** is a set of abstract capabilities. A **role binding** is an assignment of a role to one or more identities. In Kubernetes there are two pairs of related resources that represent roles and role bindings. One pair is just a namespace (Role and RoleBinding) while other pair applies across cluster (ClusterRole and ClusterRoleBinding). *Role* resources are namespaced and represent capabilities within that single namespace. Following is a simple role that gives an identity the ability to create and modify Pods and services.

```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namepsace: default
  name: pod-and-services
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
```

To bind this Role to user alice, we create RoleBinding like below.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: default
  name: pods-and-services
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: alice
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: mydevs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pods-and-services
```

If you want to limit access to cluster-level resources, you can use *clusterRole* and *ClusterRoleBinding* resources.

Roles are defined in terms of both a resource and a verb that describes an action that can be performed on that resource.

| Verb | HTTP method | Description |
|:-----|:-------------|:-----------|
| create | POST | Create new resource |
| delete | DELETE | Delete existing resource |
| get | GET | Get a resource |
| list | GET | List a collection of resources |
| patch | PATCH | Modify an existing resoruce via partial change |
| update | PUT | Modify existing resource via a complete object |
| watch | GET | Watch for streaming updates to a resource |
| proxy | GET | Connect to resource via a streaming WebSocket proxy |

Kubernetes has a large numnber of built-in cluster roles. To view these, use `kubectl get clusterroles`. There are four generic end user roles cluster-admin (for entire cluster), admin (namespace), edit (namespace), view (namespace). Most clusters already have numerous ClusterRole bindings setup which can be viewed with `kubectl get clsuterrolebindings`.

When Kubernetes API server starts up, it automatically installs a number of default ClusterRoles that are defined in the code for the API server. If you modify any built-in cluster role, those modifications are transient. Whenever the API server is restarted, your changes will be overwritten. To prevent this from happening, before you make any other modifications you need to add `rbac.authorization.kubernetes.io/autoupdate` annotation with a value of false to build-in ClusterRole resource. If you are running a Kubernetes service on the public internet or any other hostile environment, you should ensure that the `--anonymous-auth=false` flag on your API server.

The auth tool **can-i** is useful for testing if a particular user can do a particular action. This can be used to validate configuration settings as you configure cluster.

```shell
kubectl auth can-i create podsd
# test subresources like logs or port forwarding
kubectl auth can-i get pods --subresource=logs
```

The kubectl command line tool comes with a `reconcile` command that operates like `kubectl apply` and will reconcile text-based set of roles and role bindings with the current state of the cluster.

```shell
kubectl auth reconcile -f some-logic-config.yaml
```

Above command will reconcile the data with the cluster. To ensure changes before they are made, use `--dry-run` to print the changes.

Sometimes you want to be able to define roles that are combinations of other roles. Kubernetes RBAC supports the usage of an aggregation rule to combine multiple roles together in a new role. This new role combines all of the capabilities of all aggregate roles together, and any changes to any of the constituent subroles will automatically be propogated back into aggregate role. All ClusterRole resources that match selector clusterRoleSelector field are dynamically aggregated into the rules array in the aggregate ClusterRole resource. The best practice for managing ClusterRole is to create a number of fine-grained cluster roles and then aggregate them together to form higher-level or broadly defined cluster roles. For example, built-in `edit` role looks like this.

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: edit
  ... ...
aggreagationRule:
  clusterRoleSelectors:
  - matchLabels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
  ...
```

The edit role is defined to be aggregate of all ClusterRole objects that have a label of `rbac.authorization.k8s.io/aggregate-to-edit` set to true.

When managing a large number of people in different organizations with similar access to cluster, it's generally best practice to use groups to manage the roles that define access to the cluster. When you bind a group to a ClusterRole or namespace Role, anyone who is a member of that group gains access to the resources and verbs defined by that role. We  only need to add individual to the group. To bind a group to a ClusterRole:

```yaml
...
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: my-great-groups-name
...
```