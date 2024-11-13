# Helm

Helm packaging manager is just another package manager for Kubernetes environments. Helm pulls charts from charts repository. Below are simple commands to install, upgrade, rollback to previous version and finally uninstall some chart, in this case `bitnami/apache`.

```shell
helm install apache bitnami/apache --namespace=web
helm upgrade apache bitnami/apache --namespace=web
helm rollback apache 1 --namespace=web
helm uninstall apache
```

## What issues it solves?

It tries to solve following issues with Kubernetes.

1. With bare Kubernetes, the config files are static. 
2. It is hard to maintain consistency if those are modified directly on the kubernetes using `kubectl edit` command. 
3. As the application is installed and upgraded, kubernetes will not maintain the revision history on redeployment. If we want to go back to previous revision, there is no way we can go back.

### Advantages of Helm

1. It makes managing kubernetes deployment simple. Using helm, it will just pull single chart and we can also override default values which comes with specific chart. Helm maintains revision history. It will store all templates and configs to specific location. On updates, it will create new revision of those templates.
2. Helm allows for dynamic configurations. Kuberentes files are static, we can't pass values. This issue is resolved using helm templates. Helm uses `Values.yaml` to pass values to generate the final yaml which is passed to Kuberenetes API.
3. Helm allows for consistency because with helm, we can upgrade using `helm upgrade`. So, this makes sure whatever is on the chart, is what is deployed. When working with Kubernetes directly, we have to take care of order of resoureces. Helm manages these dependencies automatically.
4. Helm also allows hook, which helps do some process during upgrade, for test, like loading data into DB, etc.
5. Helm ensures charts on central repository are secure. It verifies signatures before install and makes sure they are from verified source.

Helm uses Charts to install packages to Kubernetes cluster. These are stored in charts repository. There is [Bitnami repository](https://bitnami.com/stacks/helm) which is public repository.

```shell
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
# To uninstall
sudo apt-get remove helm
```

```shell
# minikube installation
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start
minikube delete --all # delete all resources
```

## Helm Basic commands

```shell
helm repo list # It doesn't come with pre-configured helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami # Add bitnami helm repository
helm repo list # Now it will show bitnami repository in the repo list
helm search repo apache # Search for 'apache' chart in repo
helm search repo mysql # By default shows the latest version only
helm search repo mysql --versions # Search for all versions
helm repo remove bitnami # Remove bitnami repo

kubectl get pods # Nothing in default namespace
helm install <instance_name> bitnami/mysql
# Above command would also give information as to how to connect to this mysql and credentials for it.
# The same information later can be retrieved using below command
helm status <instance_name>
kubectl get pods # new <instance_name> should be running

# On separate terminal if you login to minikube and check containers, there will be additional docker container running
minikube ssh
docker ps # see there will be mysql container running
# Go back to original terminal window.

kubectl create ns teamtwo # Create new namespace
helm install --namespace teamtwo <installation_name> bitnami/mysql # Installation name should be unique per namespace
helm list # list all the installations of default namespace
helm list --namespace <namespace_name> # list installations of give namespace
helm uninstall <instance_name> # Delete the installation
kubectl get pods
```

We can also pass custom configurations to charts. For example, we can pass custom mysql password using command `helm install mydb bitnami/mysql --set auth.rootPassword = somepassword`. However, there is better option to set properties file using yaml file using `--values` option.

```shell
cd examples/mysql
helm install mydb bitnami/mysql --values values.yaml # provide custom configuration for chart.
```

```shell
helm repo update # update local cache for new charts from remote repository
helm list # we have one installation
helm status mydb # This gives how to update the chart towards end.
helm upgrade --namespace default mydb bitnami/mysql --set auth.rootPassword=$ROOT_PASSWORD # This requires root password to ensure permission, alternatively use below command
# When upgrading if `--values` are not passed, it will default to default values and root password will change.
helm upgrade mydb bitnami/mysql --values values.yaml # You can check REVISION: 2
helm status mydb
helm list # Shows revision 2
# alternatively if we don't know the values we passed, helm actually stores them and we can use.
helm upgrade mydb bitnami/mysql --reuse-values # use the values used in the initial revision

helm ls # list installations
kubectl get secrets # For each version, helm maintains secrets, which are release record.
helm uninstall mydb # This will remove installation as well as secrets
# Alternatively, we can use option to keep history of revisions
helm uninstall mydb --keep-history
helm ls # installation is not available
kubectl get secrets # Depending on command used, relase secrets might be gone.
```

## Helm Details

Helm goes through following process when deploying helm charts.
- Load the chart and its dependencies
- Parse `values.yaml` and general yaml files.
- Parse yaml files to kube objects and validate the objects with kubernetes API.
- Generate yaml and send to kubernetes.

```shell
helm install <installation> bitnami/mysql --values values.yaml --dry-run
helm template <relase_name> bitnami/mysql --values values.yaml # generate kubernetes yaml files. It doesn't validate with kube api.
kubectl get secret <secret_name> -o yaml
helm get notes <relase_name> # Shows release notes from given release
helm get values <release_name> # Show custom values for release
helm get values <release> --all # Show all values (default + custom)
helm get values <release> --revision 1 # Show values for specific revision
helm get manifest # get manifest information
helm get manifest <release> --revision 1 # get manifest files for specific revision
helm history <release> # Show history of given release
# If we don't use --keep-history flag when using uninstall, you cannot rollback after uninstall
helm rollback <release> 1 # rollback release to version 1. This creates new version
kubectl get secret
# create namespace and deploy release
helm install <release> bitnami/apache --namespace mynamespace --create-namespace 
# upgrade or install a release. Check if release exists, if yes, then upgrade or install. Useful for automation
helm upgrade --install <release> bitnami/apache
# generate name for the release 
helm install bitnami/apache --generate-name
# Use got template  to generate name using double curly braces
helm install bitnami/apache --generate-name --name-template "mywebserver-{{ randAlpha 7 | lower }}"
# Make helm command synchronous by specifying --wait and timeout
helm install <release> bitnami/apache --wait --timeout 5m10s
# If installation doesn't finish in given timeout, helm will mark  it as failure. If you instead want to use previous release. This also doesn't require explicit --wait option
helm install <release> bitnami/apache --atomic --timeout 7m12s
# When we upgrade, kubernetes will only restart the pods for which values have changed. If you want to forcefully start all pods, we can use. This will deleted and recreate, so some downtime
helm upgrade <release> bitnami/apache --force
# If upgrade fails, we want to clean up secrets and configmaps. Usually you want to keep them to debug issues
helm upgrade <release> bitnami/apache --cleanup-on-failure
```


## Creating Charts

`Chart.yaml` file where the metadata for Chart exists
`Charts` include charts on which this chart depends. They will be stored in this directory.
`templates` include different files for manifest files. This also includes `NOTES.txt` which will be rendered when `helm install` is executed on this chart.
`values.yaml` contain values which should go into template files.

```shell
helm create firstchart
helm install firstapp firstchart/
```

- `Chart.yaml` file includes following mandatory fields, apiVersion, name, type, version. We can also have appVersion, icon, keywords, home, sources, maintainers (name and email).
- `templates` directory includes most of the files. `ingress.yaml`, `deployment.yaml`, etc are just manifest files which can be filled with Go templating using values from `Values.yaml` file. It also includes `_helpers.tpl` file is having just methods which can be used in aml files. Functions are defined using `define` keyword and ends with `end` keyword. This is used in manifest files using `include` keyword specifying the method to use.
- `Values.yaml` includes values for manifests. This can be overridden using `--values` option or `--set` option.

### Packaging Charts

To package a chart use `helm package firstchart`. 

```shell
# If you want to update dependencies before packaging
helm package firstchart -u
helm package firstchart --dependencies-update
# If we want the package to go in different directory
helm package firstchart --destination <path_to_store_package>
# Scan and verify issues for helm files (syntax, indentation)
helm lint firstchart
```

To ignore some files from being packaged, we can add entries into `.helmignore` file.

### Go Templating language

Helm uses Go programming language's templating language. Template actions are defined between two curly braces. They include helm templating language syntax. Below can be placed after `kind` in templates and can be tested using `helm template <release>` command. It will print the values for those fields.

```golang
// hyphen is used to remove additional white spaces
{{ "Helm Templating is" -}} , {{ "Cool" }}
// . represents root object. Inside this we have Values which contain values from values.yaml file
{{ .Values.replicaCount }}
// We can also access values from Chart.yaml
{{ .Char.Version }}
// Next, we can retrieve Release information using .Release
{{ .Release.Namespace }}
{{ .Release.IsInstall }}
{{ .Release.IsUpgrade }}
{{ .Release.Service }}
// Get information of current template using .Template
{{ .Template.Name }}
{{ .Template.BasePath }}
// pipe symbol is used to pass input on left to function on right
{{.Values.my.custom.data | default "testvalue" | upper | quote}}
```

- `nindent` adds a new line and adds as many number of spaces before data.
- `toYaml` converts the data of objects into yaml
All functions are listed in [helm documentation](https://helm.sh/docs/chart_template_guide/function_list/)

We can write conditional as below

```golang
{{- if .Values.my.flag }}
{{"Output of if" | nindent 2}}
{{- else}}
{{ "Output of else" | nindent 2}}
{{- end}}
// Similarly there is 'if not'
{{- if and .Values.my.firstCondition .Values.mySecondCondition }}
```

**with** allows us to open some variable in placeholder.

```golang
{{- with .Values.my.values}}
countriesOfDeployment:
{{ toYaml . | nindent 2}} // . referes to current element in with context. To use root object we can use $.
{{- else}}
{{}}
{{- end}}
```

We can also define our own variables in template.

```golang
// assignment using :=
{{ $myFLAG := true}}
{{ $myFLAG := .Values.my.flag }}
{{- if $myFLAG }}
{{"Output of if" | nindent 2}}
{{- end}}
// reassignment is done using =
{{ $myFLAG = false }}
{{- if $myFLAG }}
{{"Output of if" | nindent 2}}
{{- end}}
```

Loops in template file

```golang
countriesOfDeployment:
{{- range .Values.my.values}}
  - {{. | upper | quote}}
{{- end}}
// use key value from values file
{{- range $key,$value := .Values.image}}
  - {{$key}}: ${{value | quote}}
{{- end}}
```

```shell
helm install myapp firstchart --dry-run # it can be used to validate chart, also schema validation
helm template firstchart # again validate syntax but doesnt check schema of manifest file
# Fetch manifest used for any of existing release on helm
helm get manifest firstapp
```

`_helpers.tpl` is template file. It contains several templates with each containing comment using `{{/*` explaining what it does.

```golang
{{/*
My custom Template
*/}}
{{- define "firstchart.mytemplate" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end}}
```

To use this template, we can use `include` or `template`. The disadvantage of `template` is that we cannot use pipe.

```golang
{{template "firstchart.mytemplate" .}}
```

We can add dependencies to our charts using `depdendencies` block. Once we add those dependencies, we can update the chart using following commands. The dependency charts will be downloaded into `charts` directory.

```shell
helm dependency update firstchart
helm ls
helm install myfirstapp firstchart
helm ls
kubectl get pods # It will have mysql and application pod both.
kubectl get svc
```

If we want to specify a range of versions for mysql, we can use normal math operators like `>= 8.8.6` or `>= 8.8.6 and < 9.0.0`. Similarly, `^1.3.4` means major version 1.x like `>= 1.3.4 and < 2.0.0` and `~ 1.3.4` means minor version like `>= 1.3.4 and < 1.4.0`.

We can define repository using `@repo-name` as well if repo is defined using `helm repo add` command.
If we want to install dependency conditionally using some value in `values.yaml`, we can define those values in values file and use `condition` in `dependencies` block to define our condition. For example, if `mysql.enabled` has value `false`, it will not install dependency of mysql.

```shell
helm uninstall myfirstapp
helm install myfirstapp firstchart
kubectl get pods # mysql pod is not created
kubectl get svc
```

To define multiple dependencies conditionally, we can define another dependency and define its own value


```yaml
dependencies:
  - name: mysql
    version: "8.8.6"
    repository: "http://charts.bitnami.com/bitnami"
    condition: mysql.enabled
  - name: apache
    version: "8.8.6"
    repository: "http://charts.bitnami.com/bitnami"
    condition: apache.enabled
```

However, there is better way to do this using tags. So, in the values file, we will have 

```yaml
# values.yaml
tags:
  enabled: false
```

```yaml
# Charts.yaml
dependencies:
  - name: mysql
    version: "8.8.6"
    repository: "http://charts.bitnami.com/bitnami"
    tags:
      - enabled
```

If we want to override settings of dependency, we can define them in the `values.yaml` file using the same name as the dependency. In this case, `mysql`.

```yaml
mysql:
  auth:
    rootPassword: sample123
  primary:
    service:
      type: NodePort
      nodePort: 30788
```

To import values from child chart, we can use `import-values`. The child will expose values using

```yaml
export:
  service:
    port: 8080
```

To use this value, in parent yaml file, we can use below in `Chart.yaml` will import service value and then it can be used in any of the template files using `{{ .Values.service.port }}`.

```yaml
  import-values:
    - service
```

To import values even if child chart doesn't export any value, we can use `import-values` but with different syntax.

```yaml
  import-values:
    - child: primary.service
      parent: mysqlService
```

Now, this can be used using `{{.Values.mysqlService.type}}`.

If you want to perform some action during the release process like loading data into database or something, then it can be done using hooks. These are usually identified using different annotation `helm.sh/hook` and it comes with many different hooks like pre-install, post-install, pre-delete, post-delete, pre-upgrade, post-upgrade, pre-rollback, post-rollback, test, etc. We can also configure hook priority using `hook-weight`. There are deletion policies which allow to clean up this hooks using before-hook-creation, hook-succeeded, hook-failed, etc. Check `hookpod.yaml` file in `firstchart`.

```shell
helm uninstall myfirstapp
helm install myfirstapp firstchart
kubectl get pods # It will have extra pre-install pod
```

There is already a test hook pod inside `examples/firstchart/templates/tests`. This can be executed using `helm test firstchart`. It will return 0 error code using wget command for the service on correct deployment.

```shell
helm uninstall myfirstapp
helm test myfirstapp # We need release before running the test.
helm install myfirstapp firstchart
helm test myfirstapp
```

## Repositories

Helm repositories are web service which hosts charts. To set up a local repository of Helm charts, we can use local web server with `index.yaml` file. This can be created using following commands.


```shell
cd examples/
helm repo index chartsrepo/
helm package firstchart -d chartsrepo/ # package firstchart and put it under chartsrepo/
helm repo index chartsrepo/ # udpate index.yaml with the chart we packaged in the last step
# To host local helm repository, we need webserver. We can use python http module for webserver
cd examples/chartsrepo
python3 -m http.server --bind 127.0.0.1 8080
# Another terminal session
helm repo list
helm repo add localrepo http://127.0.0.1:8080
helm repo list # shows both repo added
helm install firstapp localrepo/firstchart
helm ls # firstapp installation visible
helm uninstall firstapp
```

Another way to install a repo is as below. First, inside firstchart deleted packaged file with `.tgz` suffix.

```shell
helm pull localrepo/firstchart
helm install firstapp firstchart-0.1.0.tgz
helm ls
cd examples
helm create secondchart
helm package secondchart -d chartsrepo/
helm repo index chartsrepo # This adds entry for second chart in chartsrepo/index.yaml file
helm search repo firstchart # searches bitnami repo and localrepo for this name
helm search repo secondchart # No results found because we need to update local chart cache
helm repo update # This will update all the repo now and now it will search for secondchart
helm search repo secondchart
```

There is no fine grained access control on such repositories. Helm started supporting OCI repositories starting 3.0.0 version.

```shell
docker run -d --name oci-registry -p 5000:5000 registry # Start local OCI registry using docker
docker ps # OCI registry container should be running
helm package firstchart
helm push firstchart-0.1.0.tgz oci://localhost:5000/helm-charts # push packaged chart to OCI registry
helm show all oci://localhost:5000/helm-charts/firstchart --version 0.1.0 # check details of chart for specific version
helm pull oci://localhost:5000/helm-charts/firstchart --version 0.1.0
helm template oci://localhost:5000/helm-charts/firstchart --version 0.1.0
helm install myocirelease oci://localhost:5000/helm-charts/firstchart --version 0.1.0
helm upgrade myocirelease oci://localhost:5000/helm-charts/firstchart --version 0.2.0
helm registry login -u <username> <oci-registry-url> # For remote OCI registry login
helm registry logout -u <username> <oci-registry-url>
```

Helm uses PGP for security. As a provider we will use private key and public key. When packaging a repo, we will have `.prov` file which contains information for chart and signature. When user pulls repo, the user can verify the chart and ensure it comes for original provider. To generate private and public key-pair we can use `GnuPG`.

```shell
gpg --version # by default stores keys in `/home/<user>/.gnupg`
gpg --full-generate-key # remember alias email
gpg --export-secret-keys > ~/.gnupg/secring.gpg # use .gpg extension file name
# Delete packaged charts because we need brand new pacakges
helm package --sign --key email@gmail.com --keyring ~/.gnupg/secring.gpg firstchart -d chartsrepo/ # package chart with signature
helm verify chartsrepo/firstchart-0.1.0.tgz --keyring ~/.gnupg/secring.gpg # Verify the chart
helm repo index chartsrepo/
cd chartsrepo/
python3 -m python3 -m http.server --bind 127.0.0.1 8080
# another terminal session
helm repo list
helm install --verify --keyring ~/.gnupg/secring.gpg temporaryrelease localrepo/firstchart # match signature while installing
```

### Helm Starters

Helm starters allow us to create application specific charts. Helm expects starter charts to be in specific folder. We can get that directory using `helm env HELM_DATA_HOME`. To create a starter we can name chart directory to specific name. To make chart a starter, we only have to replace existing chart name with `<CHARTNAME>` in all files of a chart. To use this chart, we can use `helm create --starter <starter_name> demoapp`

Staring Helm 3.0, we can validate schema of `Values.yaml` file. For this, we have to define JSON file representing schema with `values.schema.json`. This will allow us to ensure values are of certain type as well as they are present in the values file.