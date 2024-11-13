# Kubernetes DevOps

## Creating a Deployment

```shell
# Create a deployment by using YAML manifest file
kubectl apply -f ../examples/manifests/deployment-nginx.yaml
# Confirm the deployment status shows 'successfully rolled out'
kubectl rollout status deployment nginx-deployment
# Verify number of DESIRED and CURRENT values match
kubectl get deployments
# Check the ReplicaSets and pods deployed
kubectl get rs,pods
# Edit the deployment object and change the container image from image nginx 1.7.9 to 1.16.0
kubectl edit deployment nginx-deployment
# Verify changes in status
kubectl rollout status deployment nginx-deployment
# vefiry older ReplicaSet has been scaled down and new Deployment has spun up
kubectl get rs
# Check the details and 