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

Infrastructure is defined using a high-level configuration files. Terraform has a planning step where it generates execution plan. This shows what Terraform will do when we call `apply`. Terraform builds a graph of all your resources and parallelizes the creation and modification of any non-dependent resources. Complex change sets can be applied to infrastructure with minimal human interaction. 

Terraform integrates with providers to create different resources. It has many different providers to integrate with different cloud providers. **Resources** are the most important element in Terraform. Each resource block describes one or more infrastructure objects, such as compute instances, VPC, subnet, etc.

```golang
resource "aws_instance" "bastion" {
  ami = "ami-01lkj3j4ab45sdflk34"
  instance_type = "t2.micro"
}
```

Terraform use HCL (Hashicorp Configuration Language) to describe the infrastructure. It defines provider and resouces. If we are using multiple resources together, it creates a module. The basic syntax looks like this.

```
block_type "block_label" "block_label" {
  # block body
  identifier = expression # argument
}
```

Arguemnts assign a value to a name and appear within the blocks. Expressions represent value either literally or by referring other values.

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
# terraform console allows to verify variable names
cd examples/terraform-basics
terraform console
"${var.name}"
exit
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

## Details:

In order to allow Terraform to create and modify resources on AWS, we need to create IAM user and provide AdministratorAccess. Generate the ACCESS KEY and SECRET KEY for this user. For every new directory or file, we need to run `terraform init`. Create below file `examples/createInstance.tf`.

```golang
provider "aws" {
    access_key = "ACCESS KEY"
    secret_key = "SECRET KEY"
    region = "us-east-2"
}

resource "aws_instance" "MyFirstInstance" {
    ami = "ami-05692172625678b4e"
    instance_type = "t2.micro"
}
```

```shell
cd examples/terraform-basics
terraform apply
# To clean up the resources
terraform destroy
# Show the plan for Terraform configuration
terraform plan
terraform plan --out myfirstplan.out
terraform apply "myfirstplan.out"
```

Let's see how we can provide credentials separately. Now, I have separated `provider.tf` to provide the credentials and removed that section from `createInstance.tf` file.

```shell
cd examples/terraform-basics
terraform plan
terraform apply
terraform destroy
```

We can also supply credentials in the environmental variables by creating following environment variables.

```shell
export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="AWS_SECRET_KEY"
export AWS_DEFAULT_REGION="us-east-2"
env | grep -i AWS
cd examples/terraform-basics
rm provider.tf
terraform plan
terraform apply
terraform destroy
```

If we want to create multiple instances of the same type, we can modify the `createInstance.tf` file as below.

```golang
resource "aws_instance" "MyFirstInstance" {
  count = 3
  ami = "ami-05692172625678b4e"
  instance_type = "t2.micro"
  tags = {
    Name = "demoinstance-${count.index}"
  }
}
```

Variables are used to parameterize deployment using Terraform. Input variables enable user to pass configuration values at the time of deployment. This allows deployment of development, staging or production environments using the same resource declarations with different configurations. Terraform input variables are defined using variable block with variable name and other option parameters for the variables. These variable blocks can be placed in any `.tf` file within Terraform project. Usually this file is called `variables.tf`. While specifying variable, we must provide `type` to define datatype as string, number, object and other supported data types. We can also provide `default` value or `description` parameters. Inside, input variables, we can also provide conditional input variables. When defining input variables, it can have a custom validation rules defined. These are defined by adding a validation block within the variable block for the Input Variable.

Variable tyes include string, bool and number as primitive types. It can also have complex types like collection type or structural types. These include list, map, set, object, tuple. We can use multiple configuration files to store variables. This means we can use variables to manage the secrets and avoid pushing AWS credentials in Git repo.

Now the structure looks like this. We create `vars.tf` or `variables.tf` to define varibles and their values. We can use those variables inside `provider.tf` file like `${var.AWS_ACCESS_KEY}`. We can create `terraform.tfvars` to keep secret information like ACCESS_KEY or SECRET_KEY and add that file inside `.gitignore` to avoid committing it in version control.

```shell
cd examples/terraform-variables
terraform init
terraform plan # It fails due to some variables not defined, but we can pass during this execution interactively.
# Another way to pass these variables is below.
terraform plan --var AWS_ACCESS_KEY="ACCESS_KEY" --var  AWS_SECRET_KEY="SECRET_KEY"
# Now, I create terraform.tfvars file and add this to gitignore file.
terraform plan # It reads tfvars file to read secrets
```

For examples of list and map look into Security_Group and AMI_ID. In AWS, AMI ID is dependent on the region, so that can be defined using map variable. For list of security groups, it will apply all of those security group to the instances created.


```shell
terraform plan
terraform plan --var AWS_REGION="us-west-2"
```

### Provision Software with Terraform

There are two ways to install software. (1) Build a custom AMI, (2) Boot up the standard AMI and install software at runtime. To install softwares, we can create a shell script and we can pass that script into the instance and run it. Below is a snippet of code. We can use `remote-exec` to execute the script. Check full source code inside `examples/terraform-software-provisioning` directory.

```golang
provisioner "file" {
  source="installNginx.sh"
  destination="/etc/installNginx.sh"
  connection {
    user = var.instance_user
    password = var.instance_pass
  }
}
```

```shell
examples/terraform-software-provisioning
terraform init
terraform plan
terraform destroy
```

Terraform provides DataSource for cloud providers like AWS. It provides dynamic information about entities that are not managed by the current Terraform and configuration. DataSource also provides all IPs in use by AWS. This can help in IP based traffic filter.

We can create a dynamic security group as shown in `securitygroup.tf` file in below directories.

```shell
cd examples/terraform-software-provisioning/DemoDataSource
terraform plan
terraform apply
terraform destroy
```

### Output

Terraform keeps output of all resources and its attributes. We can also query the output in Terraform. Output values are like return values of a Terraform module which can be used by a child module to expose a subset of its resource attributes to a parent module. A root module can use outputs to print certain values in the CLI output after running `terraform apply`. When we are using remote state, root module outputs can be accessed by other configurations via `terraform_remote_state` data source.

Each output value exported by a module must be declared using an output block

```golang
output "instance_ip_addr" {
  value = aws_instance.server.private_ip
}
```

Outputs are only rendered when Terraform applies the plan. so, it works only with `terraform apply`. We can also use output inside a script. We have created an output inside [CreateInstance](examples/terraform-software-provisioning/DemoDataSource/createInstance.tf) file.

## Remote state

Terraform records information about what infrastructure it created in Terraform state file (`terraform.tfstate`). It also maintains the backup of earlier statefile named `terraform.tfstate.backup`. If the remote state is changed and user executes `terraform apply` again, it will make changes to correct the remote state. There are few problems with this shared state files.

1. To be able to use Terraform to update your infrastructure, each team members need access to the same state files. This means it needs to be stored in a shared location.
2. As soon as data is shared, we can run into locking. If two members running `terraform apply`, it can result in race conditions or conflict or data loss and state file corruption.
3. When making changes to infrastructure, it's best practice to isolate different environments.

First problem could be solved using version control but then if we forget to pull new files and push, we will upload stale files to version control. Version control systems also do not provide any form of locking that would prevent two team members from running `terraform apply` on the same state file at the same time. All data in Terraform state files is stored in plain text. This is a sensitive data and should not be pushed in version control. So, the best way to manage shared storage for state files is to use built-in support for remote backends. Terraform backend determines how Terraform loads and stores state. TF will automatically store new state file when we apply a plan and it will pull new files before apply. Remote backend also provides support for locking. If someone is already running apply, they will have the lock and you will have to wait for your plan execution. Most of the remote backends natively support encryption in transit and encryption on disk of the state file.

We can specify backend, for example, S3 as below. Wehn using S3 as backend, it's recommended to use `aws configure` instead of AWS environment variables.

```golang
terraform {
  backend "s3" {
    bucket = "mybucket"
    key = "/path/to/key" // to separate the project
    region = "us-east-1"
  }
}
```

Create S3 bucket with given name.

```shell
sudo apt-get update
sudo apt-get install awscli --yes
aws configure
cd examples/terraform-software-provisioning/DemoDataSource
terraform plan
terraform apply
terraform destroy
```

