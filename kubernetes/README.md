# Kubernetes

[Kubernetes Brief Notes](notes/kubernetes-notes.md)

[Kubernetes notes](notes/intro.md)

[Pods, Labels and annotations](notes/pods.md)

[Services](notes/services.md)

[Replica Sets, DaemonSets, Deployments and Replication Controllers](notes/replica-sets.md)

[Jobs, ConfigMaps and secrets](notes/jobs.md)

[Storage Solutions for Kubernetes](notes/storage-solutions.md)

[Kubernetes Multi-node installation](notes/installation.md)


# Common Kubernetes Commands

```shell
# View cluster configuration for authorization
kubectl config view
# Print out cluster information for active context
kubectl cluster-info
# Print out active context
kubectl config current-context
# Print out some details for all cluster contexts
kubectl config get-contexts
# View the resource usage across the nodes of the cluster
kubectl top nodes
# View resource usage across Pods in the cluster
kubectl top pods
# Get bash autocompletion for kubectl
source <(kubectl completion bash)
# Deploy nginx as a Pod named nginx-1
kubectl create deployment --image nginx nginx-1
# View all deployed pods
kubectl get pods
export my_nginx_pod=[your_pod_name]
# View complete details of the pod you created
kubectl describe pod $my_nginx_pod
# Coy file from local filesystem into nginx container
kubectl cp ~/test.html $my_nginx_pod:/usr/share/nginx/html/test.html
# Create a service to expose our nginx Pod externally
kubectl expose pod $my_nginx_pod --port 80 --type LoadBalancer
# View details about services
kubectl get services
# see running website from nginx using load balancer service external IP
curl http://[EXTERNAL_IP]/test.html
# Deploy a manifest file
kubectl apply -f ./nginx-pod.yaml # let's say named new-nginx
# Start an interactive shell in nginx container
kubectl exec --it new-nginx /bin/bash
# create file in /usr/share/nginx/html
# Set up port forwarding from host to nginx pod
kubectl port-forward new-nginx 10081:80
# test newly created html file
curl http://127.0.0.1:10081/test.html 
# Stream live logs as they arrive with timestamps for new-nginx pods
kubectl logs new-nginx -f --timestamps
# All manifest yaml files can be found in examples/manifests directory
# Deploy your manifest file for nginx with 3 replicas
kubectl apply -f nginx-deployment.yaml
# Scale the Pods up to four replicas
kubectl scale --replicas=3 deployment nginx-deployment
kubectl get deployments
# Update the version of nginx in the deployment
kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.9.1 --record # update to 1.9.1 nginx
# View the rollout status
kubectl rollout status deployment.v1.apps/nginx-deployment
# View rollout history
kubectl rollout history deployment nginx-deployment
# Roll back to previous version of nginx deployment
kubectl rollout undo deployments nginx-deployment
# View details of revision 3
kubectl rollout history deployment/nginx-deployment --revision=3
# Services can be configured as ClusterIP, NodePort and LoadBalancer.
# Configure service to distribute inbound traffic on 60000 port to port 80 on any container with label app: nginx
kubectl apply -f service-nginx.yaml
kubectl get service nginx # EXTERNAL IP is IP of service
curl http://[EXTERNAL_IP]:60000/
# Perform Canary deployment
# Deploy one nginx with latest nginx server and single instance with same label to be added into service
kubectl apply -f nginx-canary.yaml
kubectl get deployments
# If service looks ok, scale down old primary deployment to 0 replicas
kubectl scale --replicas=0 deployment nginx-deployment
# Verify the only running replicas is now Canary deployment
kubectl get deployments
# If we want each request from same user to go to same Pod, we can configure SessionAffinity, by putting `sessionAffinity: ClientIP` in spec for manifest file.
# Create a job from manifest file
kubectl apply -f example-job.yaml
# Check the status of this job
kubectl describe job example-job
# Get pods for this job
kubectl get pods
# Get a list of jobs in the cluster
kubectl get jobs
# Check log file from Pod that ran the Job
kubectl logs [POD_NAME]
# Delete the job, after deletion logs will no longer be available
kubectl delete job example-job
# Start cronjob
kubectl apply -f example-cronjob.yaml
# Check the status of this job
kubectl describe job [job_name]
# Get all jobs
kubectl get jobs
# Delete cron job
kubectl delete cronjob hello
# Create Gcloud Kubernetes cluster
export my_zone=us-central1-a
export my_cluster=standard-cluster-1
gcloud container clusters create $my_cluster \
   --num-nodes 2 --enable-ip-alias --zone $my_zone
# Configure access to cluster for kubectl
gcloud container clusters get-credentials $my_cluster --zone $my_zone
# Create a deployment web app
kubectl create -f web.yaml --save-config
# Create a service resource of NodePort type on port 8080
kubectl expose deployment web --target-port=8080 --type=NodePort
# Verify service was created and node port was allocated.
kubectl get service web
# Configure auto scaling for application with CPU utilization target of 1%
kubectl autoscale deployment web --max 4 --min 1 --cpu-percent 1
# Above command create HorizontalPodAutoscaler
# Auto scaler periodically adjusts the number of replicas of scale target to match average CPU utilization we specified.
# Get list of HorizontalPodAutoscaler
kubectl get hpa
# Inspect the configuration of HorizontalPodAutoscaler in YAML
kubectl describe horizontalpodautoscaler web
# View configuration of HPA
kubectl get horizontalpodautoscaler web -o yaml
# Test autoscaling by applying extra load
kubectl apply -f loadgen.yaml
# Verify autoscaling
kubectl get deployments
# Inspect auto scaler
kubectl get hpa
# Check scaling down by removing load
kubectl scale deployment loadgen --replicas 0
kubectl get deployment
# Deploy a new node pool with three preemtible VM instances.
gcloud container node-pools create "temp-pool-1" \
    --cluster=$my_cluster --zone=$my_zone \
    --num-nodes "2" --node-labels=temp=true --preemptible
# Get list of nodes
kubectl get nodes
# List only the nodes with temp=true label
kubectl get nodes -l temp=true
# To prevent scheduler from running a Pod on temporary preemtible nodes, you add a taint to each of the nodes in temp pool.  They are key-value pair with an effect (such as NoExecute) that determines whether Pods can run on a certain node.
# Add a taint to each nodes with temp=true
kubectl taint node -l temp=true nodetype=preemptible:NoExecute
# To allow application pods to execute on these tainted nodes, you must add a tolerations key to the deployment configuration like web-tolerations.yaml file. Check `spec.tolerations`
# In that file additionally, spec.nodeSelectors is added to run only on preemptible VM.
kubectl apply -f web-tolerations.yaml
# Inspect the running web Pods
kubectl describe pods -l run=web
# Force the web application to scale out again
kubectl scale deployment loadgen --replicas 4
# Verify that all new pods also run on preemptible VMs
kubectl get pods -o wide
# Install help
curl -LO https://git.io/get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
# Ensure user account has cluster-admin role in cluster
kubectl create clusterrolebinding user-admin-binding \
   --clusterrole=cluster-admin \
   --user=$(gcloud config get-value account)
# Create Kubernetes service account called Tiller. This will be used by Tiller for deploying helm charts
kubectl create serviceaccount tiller --namespace kube-system
# Grant tiller service account the cluster-admin role in cluster
kubectl create clusterrolebinding tiller-admin-binding \
   --clusterrole=cluster-admin \
   --serviceaccount=kube-system:tiller
# Initialize Helm using Tiller service account
helm init --service-account=tiller
# Update Helm repositories
helm repo update
# Check Helm version
helm version
# Deploy a set of resources to create a Redis service on active context cluster
helm install stable/redis
kubectl get services
# View StatefulSet that was deployed. A StatefulSet manages the deployment and scaling of a set of Pods and provides guarantees about the ordering and uniqueness of these Pods.
kubectl get statefulsets
# View configMaps that were deployed through Helm chart
kubectl get configmaps
# View secret that was deployed through the Helm chart
kubectl get secrets
# Inspect Helm chart 
helm inspect stable/redis
# See the templates that Helm chart deploys
helm install stable/redis --dry-run --debug
# Create cluster with network policies
gcloud container clusters create $my_cluster --num-nodes 2 --enable-ip-alias --zone $my_zone --enable-network-policy
gcloud container clusters get-credentials $my_cluster --zone $my_zone
# Run simple web server with label app=hello and expose the web application internally in cluster
kubectl run hello-web --labels app=hello \
  --image=gcr.io/google-samples/hello-app:1.0 --port 8080 --expose
# Define Ingress policy that allows access to Pods labeled app: hello from Pods labeled app: foo.
kubectl apply -f hello-allow-from-foo.yaml
# Verify network policy was created
kubectl get networkpolicy
# Run temporary Pod with label app=foo
kubectl run test-1 --labels app=foo --image=alpine --restart=Never --rm --stdin --tty
# Make a request to hello-web:8080 to verify ingress allowed
wget -qO- --timeout=2 http://hello-web:8080
exit
# Now define Pod using different label
kubectl run test-1 --labels app=other --image=alpine --restart=Never --rm --stdin --tty
# Make test requests
wget -qO- --timeout=2 http://hello-web:8080 # fails
exit
# Restrict egress (outgoing) traffic allowing pods with label app:foo to Pods labeled app: hello.
kubectl apply -f foo-allow-to-hello.yaml
# Verify policy was created
kubectl get networkpolicy
# validate egress policy
kubectl run hello-web-2 --labels app=hello-2 \
  --image=gcr.io/google-samples/hello-app:1.0 --port 8080 --expose
# Run temporary Pod to verify egress traffic
kubectl run test-3 --labels app=foo --image=alpine --restart=Never --rm --stdin --tty
wget -qO- --timeout=2 http://hello-web:8080
wget -qO- --timeout=2 http://hello-web-2:8080 # fails for hello-web-2
# Verify Pod cannot establish connections to external websites
wget -qO- --timeout=2 http://www.example.com
# Ingress Resource is load balancer of load balancers. Create Ingress resource below in GCP
# Create the service and Pods for DNS service
kubectl apply -f dns-demo.yaml
# Verify running pods
kubectl get pods
# open interactive session to one of the Pods
kubectl exec -it dns-demo-1 /bin/bash
# Test ping to another Pod
apt-get update
apt-get install -y iputils-ping
ping dns-demo-2.dns-demo.default.svc.cluster.local # This works from inside Pod
# Can also ping to DNS service's FQDN
ping dns-demo.default.svc.cluster.local
# Create a deployment for hello-v1 file which is simple web app on port 8080
kubectl create -f hello-v1.yaml
kubectl get deployments
# Create service using ClusterIP for pods with name: hello-v1 label
kubectl apply -f ./hello-svc.yaml
kubectl get service hello-svc
# Test connection from outside K8 cluster
curl hello-svc.default.svc.cluster.local # This fails
# Test connection from inside K8 cluster pod
kubectl exec -it dns-demo-1 /bin/bash
apt-get install -y curl
curl hello-svc.default.svc.cluster.local # This works
# Convert service to NodePort service
kubectl apply -f ./hello-nodeport-svc.yaml # redefines earlier service
kubectl get service hello-svc # PORTs are defined
# Verify connection from outside
curl hello-svc.default.svc.cluster.local # fails
# Verify connection from inside, from another Pod in interactive session
kubectl exec -it dns-demo-1 /bin/bash
curl hello-svc.default.svc.cluster.local # success
# Create regional static IP and global static IP, named regional-loadbalancer and global-ingress
# Deploy another version of hello app
kubectl create -f hello-v2.yaml
kubectl get deployments
# Assign regional static IP to hello-lb-svc service
export STATIC_LB=$(gcloud compute addresses describe regional-loadbalancer --region us-central1 --format json | jq -r '.address')
sed -i "s/10\.10\.10\.10/$STATIC_LB/g" hello-lb-svc.yaml
cat hello-lb-svc.yaml # verify STATIC LB IP is assigned
# Deploy LoadBalancer service
kubectl apply -f ./hello-lb-svc.yaml
kubectl get services
# Verify connections from outside
curl hello-lb-svc.default.svc.cluster.local # fails to connect to internal service name
curl [external_IP] # succeeds using external IP address of regional LB, gives different hostnames
# From inside K8 cluster still internal service name accesible
kubectl exec -it dns-demo-1 /bin/bash
curl hello-lb-svc.default.svc.cluster.local
curl [external_IP] # external IP connection also possible from inside Pod
exit
# Deploy Ingress resource
kubectl apply -f hello-ingress.yaml
kubectl describe ingress hello-ingress
# Test ingress resource can connect to both versions of app
curl http://[external_IP]/v1
curl http://[external_IP]/v2
# Persistent Volume claims
# Persistent volumes are usually created by admins, we can only create claims to access them.
# Check existing persistent volume claims
kubectl get persistentvolumeclaim
# Create PVC 
kubectl apply -f pvc-demo.yaml
kubectl get pvc # verify
# Mount PVC to nginx container Pod
kubectl apply -f pod-volume-demo.yaml
kubectl get pods
# Verify access to PVC within Pod
kubectl exec -it pvc-demo-pod -- sh
echo Test webpage in a persistent volume!>/var/www/html/index.html
chmod +x /var/www/html/index.html
cat /var/www/html/index.html
exit
# Verify persistence of the PV
# delete the pvc-demo-pod.
kubectl delete pod pvc-demo-pod
kubectl get pods
# Verify that PVC still exists
kubectl get persistentvolumeclaim
# Redeploy pvc-demo-pod to see PV again
kubectl apply -f pod-volume-demo.yaml
kubectl exec -it pvc-demo-pod -- sh
cat /var/www/html/index.html # works fine
exit
kubectl delete pod pvc-demo-pod
# StatefulSets are like a Deployment except that the Pods are given unique identifiers.
# Create StatefulSet with the volume
kubectl apply -f statefulset-demo.yaml
# Get details of the StatefulSet
kubectl describe statefulset statefulset-demo
# Get pods
kubectl get pods # see names are ordinal
# List the PVCs
kubectl get pvc
# View details of the first PVC in StatefulSet, These are newly created PVCs
kubectl describe pvc hello-web-disk-statefulset-demo-0
# Verify PVC access within Pod
kubectl exec -it statefulset-demo-0 -- sh
cat /var/www/html/index.html # not there in this folder now, as it is new PVC
# Create simple text message.
echo Test webpage in a persistent volume!>/var/www/html/index.html
chmod +x /var/www/html/index.html
cat /var/www/html/index.html
exit
# Verify the same PVC is allocated after recreating this Pod
# delete the Pod where we updated PVC
kubectl delete pod statefulset-demo-0
# StatefulSets will recreate it, once recreated verify the file exists.
kubectl exec -it statefulset-demo-0 -- sh
cat /var/www/html/index.html
exit
# Secrets and ConfigMaps
# Create ServiceAccount to access PubSub with Role PubSub Subscriber. Create credentials.json file
# Create Kubernetes Secret named pubsub-key to save credentials.json
kubectl create secret generic pubsub-key \
 --from-file=key.json=$HOME/credentials.json
# Deploy pubsub-secret file with GOOGLE_APPLICATION_CREDENTIALS configured to secret pubsub-key
kubectl apply -f pubsub-secret.yaml
kubectl get pods -l app=pubsub
# Test receiving published messages 
gcloud pubsub topics publish $my_pubsub_topic --message="Hello, world!"
# Inspect logs from the deployed Pod
kubectl logs -l app=pubsub
# ConfigMaps bind configuration files, command-line arguments, environment variables, port numbers and other configuration artifacts to your Pods' containers and system at runtime.
# Create configmap sample using simple literal
kubectl create configmap sample --from-literal=message=hello
# verify created configmap
kubectl describe configmaps sample
# Create configmap using sample2.properties file
kubectl create configmap sample2 --from-file=sample2.properties
# Create ConfigMap sample3 using YAML configuration file
kubectl apply -f config-map-3.yaml
kubectl describe configmaps sample3
# Use environment variables. For this Pod definition must include one or more configMapKeyRefs.
kubectl apply -f pubsub-configmap.yaml # INSIGHTS will have value of sample3 configmap
# Verify this environment variable has this value
kubectl get pods
kubectl exec -it [MY-POD-NAME] -- sh
printenv # INSIGHTS=testAllTheThings
exit
# We can populate a volume with the ConfigMap data instead of storing it in an environment variable. Below deployment will configmaps /etc/config location.
kubectl apply -f pubsub-configmap2.yaml
kubectl get pods
kubectl exec -it [MY-POD-NAME] -- sh
cd /etc/config
cat airspeed
exit
```

When Pod security policy admission control is enabled, it prevents non-admin users running privileged pods.  Users with cluster-admin roles are allowed to use default policies. You have to bind other users to roles that grant them the right to use specific policies and this allows to control what those users can and cannot deploy.
Pod security policy `restricted-psp` only allows unprivileged Pods to be deployed and prevents privilege elevation using `runAsUser` with root account access.

```shell
# Create Pod security policy
kubectl apply -f restricted-psp.yaml
# Verify pod security policy has been created.
kubectl get podsecuritypolicy restricted-psp
# Create ClusterRole that includes restricted-psp resource. This will be bound to user accounts. The user creating this role should have `cluster-admin` role
export USERNAME_1_EMAIL=$(gcloud info --format='value(config.account)')
# Assign USERNAME_1_EMAIL cluster-admin role
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $USERNAME_1_EMAIL
# Create ClusterRole with access to SecurityPolicy
kubectl apply -f restricted-pods-role.yaml
# Confirm ClusterRole has been created
kubectl get clusterrole restricted-pods-role
# PodSecurityPolicy controller must be enabled to affect the admission control of new Pods in the cluster. If we do not define and authorize policies prior to enabling the PodSecurityPolicy controller, some accounts will not be able to deploy or run Pods on the cluster.
# Enable PodSecurityPolicy controller
gcloud beta container clusters update $my_cluster --zone $my_zone --enable-pod-security-policy
# Verify PodSecurityPolicy is active
kubectl get podsecuritypolicies
# After it is active, we will see number of policies starting with `gce`. `gce.privileged` policy allows privileged pods to be deployed
# Confirm access to `gce.privileged` pod security policy
kubectl auth can-i use podsecuritypolicy/gce.privileged
# Verify USERNAME_1_EMAIL has access to run privileged pods.
kubectl apply -f privileged-pod.yaml # Success
kubectl delete pod privileged-pod
# Using normal user, other users should not have access to deploy pods
# As username 2
kubectl apply -f privileged-pod.yaml # fails
# Even unprivileged pod deployment fails because username 2 has not been bound to any role that allows pods to be deployed.
kubectl apply -f unprivileged-pod.yaml # fails
# Verify permission to restriected-psp policy
kubectl auth can-i use podsecuritypolicy/restricted-psp # no
kubectl auth can-i use podsecuritypolicy/gce.privileged # No
# We can provide permission by binding restricted-pods-role to username2.
kubectl create clusterrolebinding restricted-pods-binding --clusterrole restricted-pods-role --user [USERNAME_2_EMAIL]
# now username2, normal user can run pods but can't run privileged pods
kubectl apply -f unprivileged-pod.yaml
kubectl apply -f privileged-pod.yaml
# It is secre practice to perform IP and credential rotation on cluster to reduce credential lifetimes. Rotating credentials rotates IP as well.
gcloud container clusters update $my_cluster --zone $my_zone --start-credential-rotation
# To view active operations to cluster
gcloud container operations list
# Save operations task ID for node upgrade operation to environment variable
export UPGRADE_ID=$(gcloud container operations list --filter="operationType=UPGRADE_NODES and status=RUNNING" --format='value(name)')
# Monitor the status of the node upgrade using
gcloud container operations wait $UPGRADE_ID --zone=$my_zone
# The cluster master now temporarily serves the new IP address in addition to the original address. If you initiate a credential rotation, but do no complete it, GKE automatically completes the rotation after seven days.
# To complete credential and IP rotation tasks
gcloud container clusters update $my_cluster --zone $my_zone --complete-credential-rotation


# RBAC
# Verify existing namespaces
kubectl get namespaces
# Create new namespace named production
kubectl create -f ./my-namespace.yaml
kubectl get namespaces # verify new namespace
kubectl describe namespaces production # describe to see resources in namespace
# Create a pod in production namespace
kubectl apply -f ./my-pod.yaml --namespace=production
kubectl get pods # by default shows default namespace pods
kubectl get pods --namespace=production # shows in production namespace
# Assign cluster-admin privileges to username1
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user [USERNAME_1_EMAIL]
# Create role for listing and creating pods in production namespace
kubectl apply -f pod-reader-role.yaml
kubectl get roles --namespace production
# The role must be assigned to a user and an object
# Assign username2 the role for creating and listing pods in production namespace
export USER2=[USERNAME_2_EMAIL]
sed -i "s/\[USERNAME_2_EMAIL\]/${USER2}/" username2-editor-binding.yaml
cat username2-editor-binding.yaml
# Create resource in the production namespace
kubectl apply -f ./production-pod.yaml # as username2 you cannot deploy pod in production namespace
# Assign role binding using username1 (cluster-admin) to username2
kubectl apply -f username2-editor-binding.yaml
kubectl get rolebinding # doesn't show
kubectl get rolebinding --namespace production # shows in production namespace
# Create resource in production namespace
kubectl apply -f ./production-pod.yaml
kubectl get pods --namespace production
# But it cannot delete the pods
kubectl delete pod production-pod --namespace production
# Sometimes an application might need to load large data or configuration files during startup and it cannot serve traffic. In such cases, you don't want to kill application, but you don't want to send it requests.
# Below livenessProbe uses `cat /tmp/healthy` command to test for liveness every 5 seconds. The startup script creates this file and then deletes after 30 seconds to simulate an outage that Liveness probe can detect.
# Create Pod with liveness Probe
kubectl create -f exec-liveness.yaml
# Within 30 seconds it will appear as running
kubectl describe pod liveness-exec
# after 35 seconds, the pod appears to have failed
kubectl describe pod liveness-exec
# Wait about 60 seconds and verify the container has restarted
kubectl describe pod liveness-exec
kubectl delete pod liveness-exec
# Similarly Readiness probes control whether a specific container is considered ready and this is used by services to decide when a container can have traffic sent to it.
# Each container is using readiness probe every 5 seconds. The startup script sleeps for 30 seconds, launches hello-world application in background and then creates `/tmp/healthy` file. So, each container fails readiness test for at least 30 seconds after startup. The script then waits random seconds between 30 to 180 to delete `/tmp/healthy` file causing both readiness and liveness probes to fail and readiness-svc service will remove the endpoint for that container and around same time liveness probe failure will cause the container to restart.
# Create readiness deployment
kubectl create -f readiness-deployment.yaml
# Within 30 seconds, view deployment events
kubectl describe deployment readiness-deployment
# You should see 3 container running with no restarts but not ready.
kubectl get pods 
# After 30 seconds, pods appear as Ready
kubectl get pods
# Create load balancer to test readiness probes
kubectl create -f readiness-service.yaml
# Check status until you see at least one Endpoint
kubectl describe service readiness-svc
# As pods fail, readiness and liveness probes will mark them as not ready. At the same time service will remove those endpoints and liveness probe initiates the restart. The restarted pods will wait for readiness test to pass before the service will add the endpoint back into its pool.
kubectl get pods
# Get external IP address from the load balancer service
export EXTERNAL_IP=$(kubectl get services readiness-svc -o json | jq -r '.status.loadBalancer.ingress[0].ip')
# Check the deployment status and send request to load balancer.
curl $EXTERNAL_IP
kubectl get pods
```
