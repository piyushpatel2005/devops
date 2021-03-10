# Terraform Notes

This is used to maintain infrastructure as a code. It creates an execution plan. Based on execution plan, it will have Resource graph. It is also used for automation of infrastructure. It keeps infrastructure in certain state in the form of code. This also makes our infrastructure auditable using version control like Git. When updating infrastructure, Terraform determines changes and creates incremental execution plans which can be applied. Terraform can work with many providers like AWS, Azure, DigitalOcean and on-prem solutions.

Installing Terraform is simple. We just need to download the binary file and set up the PATH environment variable for it to be accessible.

```shell
# Login to BAstion host
wget https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
unzip terraform_0.12.28_linux_amd64.zip
./terraform -version
sudo mv terraform /usr/local/bin/
```

Terraform integrates with providers to create different resources. It has many different providers to integrate with different cloud providers. **Resources** are the most important element in Terraform. Each resource block describes one or more infrastructure objects, such as compute instances, VPC, subnet, etc.

```golang
resource "aws_instance" "bastion" {
  ami = "ami-01lkj3j4ab45sdflk34"
  instance_type = "t2.micro"
}
```

```shell
# Attach a role to Bastion host or add AWS credentials
# Initialize Terraform directory inside your terraform directory
cd examples/instance
terraform init
# Validate runs checks and verifies configuration i syntactically valid and consistent
terraform validate
# Dry run terraform plan, will throw error if there is any issue
terraform plan
# Run Terraform
terraform apply
# clean up resources
terraform destroy
```

Terraform graph command is used to generate a visual representation of either a configuration or execution plan. The output is in DOT format which can be used by GraphViz to generate charts.

```shell
sudo yum -y install graphviz
terraform graph | dot -Tsvg > graph.svg
```

We can set `TF_LOG` environment variable to TRACE, DEBUG, INFO, WARN, ERROR to enable different logging level. To save the log output to a file, we can export environment variable `TF_LOG_PATH`. If we want to pass variables into our Terraform files, we can create `vars.tf` file in the directory. Terraform will look into this file for variable definitions. If we have sensitive information that we want to pass to Terraform files, we can create files with `tfvars` extension and add them to .gitignore file.

```shell
cd examples/parameterizing
terraform init
# Edit variables in terraform.tfvars file
terraform plan
terraform apply
```

Similarly, if you want to create variables with lookup, you can check those configurations in `lookup-variables` folder.

```shell
cd examples/lookup-variables
terraform init
terraform plan -out lookup.out # checkout lookup.out file
terraform apply "lookup.out"
```

AWS Key pair resource helps generate SSH keys. This keypair's public key will be registered with AWS to allow logging in to EC2 instances. Example in `install-nginx` folder shows how we can publish and use key pairs.

```shell
cd examples/install-nginx
terraform init
ssh-keygen -f foo
ls -l
terraform plan
terraform apply
# Connect to public IP of this new EC2 instance on port 80
```

### Deploying Kubernetes using Terraform

```shell
# Connect to BAstion host 
# Install kubectl binaries on this host.
# Install AWS IAM authenticator on bastion host.
ssh-keygen -f devops
# Upload this key pair to AWS
# Copy devops keypairs to terraform directory.
cp devops* examples/aws-eks/
cd examples/aws-eks
terraform init
terraform plan
terraform apply
# Verify EKS cluster created on AWS console in AWS container services
# Configure kubectl and mapping nodes
terraform output kubeconfig > ~/.kube/config
terraform output config_map_aws_auth > config_map_aws_auth.yaml
kubectl apply -f config_map_aws_auth.yaml
kubectl get nodes
kubectl apply -f ../kubernetes/examples/manifests/flask-app.yml
kubectl get pods
```

If we want to create a generic Terraform code, we can use default values based on in which region this code is executed. Such information can be provided using **DataSources**. Providers provide with certain data sources which can be used in Terraform code.

## Templates

The template_file  data source renders a template from a template string which is usually loaded from an external file. Let's say we want to create dev, test and prod environments, we can dynamically change values and create three environments. Try `examples/templates` to see templates in action.

## Modules

A module is a group of terraform file to achieve desired functionality. It creates multiple resources that are used together to perform one or more function of desired architecture. the `.tf` files in working directory together form the root module. That module may call other modules and connect them together by passing output values from one to another.

Terraform registry is a web interface of all publicly available modules. These modules are organized based on providers. It provides more structured information on available module and their use in Terraform ecosystem. This can be accessed [here](https://registry.terraform.io)
