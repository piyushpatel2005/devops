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

153