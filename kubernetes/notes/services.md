# Services in Kubernetes

Service discovery tools help solve the problem of finding which processes are listening at which addresses for which services. The DNS is the traditional system of service discovery on the internet. It is for relatively stable name resolution with wide and effiicient caching, but falls short in the dynamic Kubernetes environment. Real Service discovery in Kubernetes starts with a Service object. It is a way to create a named label selector. We can use `kubectl expose` to create a service.

```shell
kubectl run alpaca-prod \
    --image=gcr.io/kuar-demo/kuard-amd64:blue \
    --replicas=3 \
    --labels="ver=1,app=alpaca,env=prod"
# expose using service
kubectl expose deployment alpaca-prod
kubectl run bandicoot-prod \
    --image=gcr.io/kuar-demo/kuard-amd64:green \
    --replicas=2 \
    --labels"ver=2,app=bandicoot,env=prod"
kubectl expose deployment bandicoot-prod
kubectl get services -o wide
```

The `kubectl expose` will pull both the label selector and the relevant ports from the deployment definition. The service is assigned a cluster IP and will load  balance across all the Pods that are identified by the selector. 

```shell
ALPACA_POD=$(kubectl get pods -l app=alpaca \
            -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $ALPACA_OOD 48858:8080
```

Now access `http://localhost:48858` and you can access the service.

The cluster IP is virtual, stable and appropriate to give it a DNS address. Kubernetes provides **DNS service** exposed to Pods running in the cluster. This DNS system is installed when the cluster was creted. DNS service is managed by Kubernetes so it is like Kubernetes on Kubernetes.

Service object also tracks which of the Pods are ready via a readiness check. To add these follow the steps below.

```shell
kubectl edit deployment/alpaca-prod
```

After you edit the deployment it will write back to Kubernetes.

```yaml
name: alpaca-prod
readinessProbe:
    httpGet:
        path: /ready
        port: 8080
    periodSeconds: 2
    initialDelaySeconds:  0
    failureThreshold:  # 3 failed checks means pod is not ready
    successThreshold: 1 # 1 successful check means pod is ready
```

Above will delete and recreate the alpaca Pods. So, we need to restart the `port-forward` command.

```shell
ALPACA_POD=$(kubectl get pods -l app=alpaca -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $ALPACA_POD 48858:8080
```

We can also keep watching the endpoint using `--watch`

`kubectl get endpoints alpaca-prod --watch`

If you hit "Fail", after three failed attemps the Pod is removed from the service. Hit "Succeed" and after a single readiness check the endpoint is added back.

### Connecting to internet

The easiest way to expose to the Internet is to use NodePorts. In addition to a cluster IP, the system picks a port and every node then forwards traffic to that port to the service.

`kubectl edit service alpaca-prod`

Change the `spec.type` field to NodePort. The same can be achieved using `kubectl expose` by specifying `--type=NodePort`.

`kubectl describe service alpaca-prod`

We can see which port is assigned to service as NodePort value. We can access any of the cluster nodes on this port to access the service. If on the same network, you can access directly. If the cluster is in the cloud, we can use SSH tunnels with something like `ssh <node> -L 8080:localhost:32711` where 32711 is the selected port. Each request will be randomly directed to one of the pods.

On cloud, edit the `alpaca-prod` serivce again using `kubectl edit service alpaca-prod` and change `spec.type` to LoadBalancer. Try `kubectl get services`, we get EXTERNAL-IP.

`kubectl describe service alpaca-prod`. You can open browser and try accessing LoadBalancer ip address at a given port.

### Endpoints

Some apps want to be able to use services without using a cluster IP. This is possible using Endpoints object. For every service objec,t Kubernetes creates a buddy Endpoints object that contains the IP addresses for that service.

`kubectl describe endpoints alpaca-prod`

Kubernetes also supports watching objects and be notified as soon as they change. A client can react immediately as soon as the IPs associated with a service change using `kubectl get endpoitns alpaca-prod --watch`

```shell
kubectl delete deployment alpaca-prod
kubectl run alpaca-prod \
    --image=gcr.io/kuar-demo/kuard-amd64:blue \
    --replicas=3 \
    --port=8080 \
    --labels="ver=1,app=alpaca,env=prod"
```

Kubernetes services are built on top of label selectors over Pods. 

```shell
# get what IPs are assigned to each Pod in our deployment
kubectl get pods -o wide --show-labels
kubectl get pods -o wide --selector=app=alpaca,env=prod # select based on labels
```

Cluster IPs are stable virtual IPs that load-balance traffic across all of the endpoints in a service. This is performed by `kube-proxy` running on every node in cluster. The cluster IP is usually assigned by the API server as the service is created. However, the user can specify a cluster IP. Once set, it cannot be modified without deleting and recreating the Service. The Kubernetes service address range is configured using `--service-cluster-ip-range` flag on the `kube-apiserver` binary.The service address range should not overlap with the IP subnets and ranges assigned to each Docker bridge on Kubernetes node.

Cleanup all objects using `kubectl delete services,deployments -l app`.

## Load Balancing with Ingress

Kubernets has a set of capabilities to enable services to be exposed outside of the cluster. The Service object operates at Layer 4 (OSI model). It only forwards TCP and UDP connectiosn and doesn't look inside of those connections. If these servicse are NodePort, we have to have clients connect to unique port per service. If these services are type LoadBalancer, we'll be allocating cloud resources for each service. When solving this problem in non-Kubernetes situations, users often turn to the idea of virtual hosting. Kubernetes calls its HTTP-based load-balancing system Ingress. Ingress is a Kubernetes-native way to implement the virtual hosting pattern. The Ingress Controller is a software system exposed outside the cluster using a service of type LoadBalancer. Look at [Simple ingress manifest](../examples/manifests/simple-ingress.yaml).

```shell
kubectl apply -f ../examples/manifests/simple-ingress.yaml
kubectl get ingress
kubectl describe ingress simple-ingress
```

This sets up things so that any HTTP request that hits the Ingress controller is forwarded on to alpaca service.
There are many different implementations of Ingress controllers. The most popular generic controller is open source NGINX ingress controller.