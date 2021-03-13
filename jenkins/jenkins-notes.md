# Jenkins Notes

Jenkins is free, open source automation server. It is CI tool that allows continuous deployment, building, testing the code. It is server based system that runs in servlet containers such as Apache Tomcat. Jenkins is self-contained Java program which can run on any OS. Configuration is done via web interface and it has built-in error checking mechanism. There are numerous plugins available which allows to integrate with every tool available in CI/CD scope. it can be extended via plugins and provides a lot of flexibility to achieve automation. It can distribute workload across multiple nodes to reduce time to build and release.

1. Launch EC2 instance (centos image)
2. Install Java
```shell
yum install java-1.8* -y
java -version
find /usr/lib/jvm/java-1.8* | head -n 3
```

Add following lines to `~/.bash_profile` file.

```shell
export JAVA_HOME=/usr/lib/jvm/java-1.8.0
PATH=$PATH:$HOME/.local/bin:$HOME/bin:$JAVA_HOME
```

Finally, run `source ~/.bash_profile` to load new variables.

3. Install Jenkins

```shell
yum -y install wget
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum -y install jenkins
```

4. Start and Enable Jenkins

```shell
systemctl start jenkins
systemctl enable jenkins
```

5. Test Jenkins
  - Create "New Item"
  - Enter an item name and choose *FreeStyle* project.
  - Under *Build* section, Execution shell, type simple echo statement.
  - Save job and click *Build job*.
  - Check *Console Output*.

## Jenkins Master-Slave 

Jenkins can have master slave architecture. SCM will trigger webhook on commit to Jenkins which will pull code from SCM. Then it will distribute its load to slave servers. Slave on receipt of request will perform build and test the code.

1. Create another slave EC2 server.
2. Setup and install Java and Jenkins
3. Setup the slave machine

```shell
sudo su -
useradd jenkins-slave-01
sudo su - jenkins-slave-01
ssh-keygen -t rsa -N "" -f /home/jenkins-slave-01/.ssh/id_rsa
cd .ssh
cat id_rsa.pub > authorized_keys
chmod 700 authorized_keys
```
4. Configure master machine

```shell
# Copy public key from slave machine into master machine
sudo su -
mkdir -p /var/lib/jenkins/.ssh
cd /var/lib/jenkins/.ssh
ssh-keyscan -H SLAVE_NODE_IP_OR_HOSTNAME >> /var/lib/jenkins/.ssh/known_hosts
chown jenkins:jenkins known_hosts
chmod 700 known_hosts
```

5. Setup slave node on master node. Go to Master node Jenkins UI. click *Manage Jenkins* > *Manage Nodes and Clouds* > *New Node*. Provide reasonable name to this machine. Select *Permanent Node* and click add.

## Role based access

Different users are given different access: developer, tester, admins, operations, etc.

## Integrating Github with Jenkins

Install git on Jenkins server.

New Item > Pipeline > Click OK
In Pipeline tab, configure Github location and trigger based on SCM polling to check every specific duration.