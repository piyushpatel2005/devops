# Packer

Packer is a tool for creating identical machine images from a single source configuration. It used to create Compute images for AWS, Azure, Google Cloud and OpenStack. This way you can have exactly what configuration, dependency you need in your image. You can define everything you need in an image along with packages, depedencies, source code, starting of services etc. 

Packer runs in three stages: Builder, Provisioner and Post-Processor.

**Builder** is responsible for creating the image. They are the most important piece. Depending on the platform, you will use different builder depending on your cloud provider. You want to specify base image and modify this image with configurations and dependencies. You can provide these instructions to add packages, download source code, install dependencies etc. These modification instructions are used in **provisioner** section. Once the image is created, the **post processor** runs. All these operations are performed with single configuration file.

## Mutable Infra

In mutable infrastructure, you would spin up server and then install required dependencies and patches. You would set up firewall rules and follow it up with application source code installation. You would update and patch this server as you maintain it. This is called mutable infrastructure as you're mutating the changes to the server. When you need to make changes, you will connect to server and modify them. However, if you have several servers, this can be difficult where you may end up modifying few servers and miss few and they are also difficult to keep track of. Automation tools like Ansible can be used to keep configuration changes. However, it is still mutable infrastructure. The immutable infrastructure is where you would create a new image from the source code and then spin up the server from the image. You would then have a immutable infrastructure where you can deploy the same server over and over again without worrying about configuration drift.

The workflow for immutable infrastructure looks like this.
1. Develop the code
2. Create image using packer which will create v1 image.
3. Deploy the server from v1 image. This image includes everything you need. You don't modify by signing into the server machine
4. When you need to make changes, you modify the source code.
5. Run packer again to create a new image with v2 image.
6. Deploy the server from v2 image. This image includes everything you need. You don't modify by signing into the server machines. You can remove the older version of servers.

You don't have to connect to servers to modify anything. This way all servers will have identical configuration because they use the exact same images.

## Example

Install packer in your system. With VScode, you can use Hashicorp HCL extension to write packer files easily with syntax highlighting.

Create custom image for default ubuntu image with nginx installed and forwarding rules for http and https ports.

```hcl
packer {
    required_plugins {
        amazon = {
            version = ">= 1.2.3"
            source  = "github.com/hashicorp/amazon"
        }
    }
}

source "amazon-ebs" "ubuntu" {
    access_key    = "<ACCESS KEY>"
    secret_key    = "<SECRET KEY>"
    ami_name      = "nginx-ubuntu-custom-image"
    instance_type = "t2.micro"
    region        = "us-east-1"
    # source_ami    = "ami-0c55b159cbfafe1f0"
    source_ami_filter {
        filters = {
            name                = "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
            root-device-type    = "ebs"
            virtualization-type = "hvm"
        }
        most_recent = true
        owners      = ["099720109477"] # Canonical
    }
    ssh_username = "ubuntu"
}

build {
    name = "nginx-ubuntu-custom-image"

    sources = ["source.amazon-ebs.ubuntu"]
    provisioner "shell" {
        inline = [
            "sudo apt update",
            "sudo apt install -y nginx"
            "sudo systemctl enable nginx",
            "sudo systemctl start nginx"
            "sudo ufw allow proto tcp from any to any port 22,80,443"
            "echo 'y' | sudo ufw enable"
        ]
    }

    post-processor "vagrant" {}
    post-processor "compress" {}
}
```

Once you have this configuration file, you can navigate to the directory and run packer commands.

```shell
packer init -y
packer fmt .
packer validate .
packer build <packer_config_file>
```

The build step itself tries to spin up instance and create custom image. You should now see the new AMI in your AWS account. You try using this AMI to build a new instance and you should have NGINX installed and running by default with this new AMI.