<img src="https://blog.headforcloud.com/content/images/2017/10/Capture.PNG" width="180" height="50" /> <img src="https://dd3hq3hnmbuiz.cloudfront.net/images/Terraform-Background.jpg" width="100" height="50" /> <img src="https://carlos.mendible.com/assets/img/posts/aks.png" width="100" height="50" />   <img src="https://azure.microsoft.com/svghandler/container-registry/?width=600&height=315" width="90" height="50" /> <a href="https://helm.sh/"><img src="http://www.razibinrais.com/wp-content/uploads/2018/07/helm.png" width="50" height="50" /></a> <img src="https://ordina-jworks.github.io/img/2018-02-12-Azure-Draft/draft-logo.png" width="110" height="50" /> <a href="https://brigade.sh/"><img src="https://brigade.sh/assets/images/brigade.png" width="110" height="50" /></a>
  
Table of Contents (Azure Kubernetes Service with Terraform)
=================

1. [ServicePrincipal and Subscription ID](#serviceprincipal-and-subscription-id)
2. [Install terraform locally](#install-terraform-locally)
3. [Automatic provisioning](#automatic-provisioning)
   * [All in one with docker azure-cli-python](#all-in-one-with-docker-azure-cli-python)
      * [kubeconfig](#kubeconfig)
      * [Sanity](#sanity)
4. [License](#license)
5. [Manual stepped provisioning](#manual-stepped-provisioning)
   * [ Run Azure cli container and copy terraform binary along with id_rsa to it](#run-azure-cli-container-and-copy-terraform-binary-along-with-id_rsa-to-it)
   * [Clone this repo in the azure-cli-python container](#clone-this-repo-in-the-azure-cli-python-container)
   * [Fill in the variables.tf with default values](#fill-in-the-variables-file-with-default-values)
   * [Terraform for aks](#terraform-for-aks)
   * [kubeconfig](#kubeconfig)
   * [Sanity](#sanity)
5. [Reporting bugs](#reporting-bugs)
6. [Patches and pull requests](#patches-and-pull-requests)

### ServicePrincipal and Subscription ID
`docker run -ti docker4x/create-sp-azure aksadmin`

`Your access credentials ==================================================`

`AD ServicePrincipal App ID:       xxxxxx `

`AD ServicePrincipal App Secret:   xxxxxx `

`AD ServicePrincipal Tenant ID:   xxxxxx`

### Install terraform locally
`wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip -O temp.zip; unzip temp.zip; rm temp.zip ;sudo cp terraform /usr/local/bin`
### Automatic provisioning 
#### All in one with docker azure-cli-python
Please note **docker** should be installed with **terraform** binary and your **id_rsa.pub** present in directory for running the following.

>**Terraform locally installed has binary in `/usr/local/bin`**

Create new cluster -Please note **docker** should be installed with **terraform** binary and your **id_rsa.pub** present in directory for running the following.

**`wget https://raw.githubusercontent.com/dwaiba/aks-terraform/master/create_cluster.sh && chmod +x create_cluster && ./create_cluster.sh`**

Terraform will now prompt for the 7 variables as below in sequence:

* agent_count 
* azure_container_registry_name 
* client_id
* client_secret
* cluster_name
* dns_prefix
* resource_group_name

Values and conventions for the 6 variables are as follows : 
* agent_count are the number of "agents" - 3 or 5 or 7
* azure_container_registry_name as "alphanumeric"
* client_id which is the sp client Id
* client_secret which is the secret for the above as created in pre-req
* cluster_name as "--org--_aks_--yournameorBU--"
* dns_prefix as "--org--aks--yournameorBU--"
* resource_group_name as "--org--_aks_--yournameorBU--"

> The DNSPrefix must contain between 3 and 45 characters and can contain only letters, numbers, and hyphens.  It must start with a letter and must end with a letter or a number. 

> Only alpha numeric characters only are allowed in azure_container_registry_name.

>Expected account_tier for storage to be one of **Standard** **Premium** with max **GRS** and **not RAGRS**. `storage_account_id` can only be specified for a **Classic (unmanaged)** Sku of Azure Container Registry. This does not support web hooks. Default is **Premium** Sku of Azure Container Registry.
  
After Cluster creation  all you need to do is perform "kubectl get svc" to get url for jenkins and obtain jenkins password as follows- preferably from within the container prompt post creation:

`printf $(kubectl get secret --namespace default hclaks-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d);echo`

One can also use draft with the Container Registry and use helm to install any chart as follows:

<br/> <img src="https://cdn-images-1.medium.com/max/1600/1*Nsme583Ut1TY6IDZjKl27w.png" width="450" height="225" /> <br/> <img src="https://cdn-images-1.medium.com/max/1600/1*kV56ClDz_rrMg5wT4lpQ5Q.png" width="450" height="225" />

#### KUBECONFIG
`echo "$(terraform output kube_config)" > ~/.kube/azurek8s`

Also one can echo and copy content to local kubectl config.


`export KUBECONFIG=~/.kube/azurek8s`

#### Sanity
`kubectl get nodes`

`kubectl proxy`

Dashboard available at `http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default`.

### License
  * Please see the [LICENSE file](https://github.com/dwaiba/aks-terraform/blob/master/LICENSE) for licensing information.
  
### Manual stepped provisioning
#### Run Azure cli container and copy terraform binary along with id_rsa to it

`docker run -dti --name=azurecli-python --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python:/ && docker cp ~/.ssh/id_rsa azure-cli-python:/ && docker exec -ti azure-cli-python bash -c "az login && bash"`

#### Clone this repo in the azure-cli-python container
`git clone https://github.com/dwaiba/aks-terraform`

`curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;`

Optionally, you can also install kubectl locally. This repo installs kubectl in the azure-cli-python container.


`chmod +x ./kubectl;`

`mv ./kubectl /usr/local/bin/kubectl;`

`mv /id_rsa.pub /aks-terraform;`

#### Fill in the variables file with default values

#### Terraform for aks
`mv ~/terraform aks-terraform/`
`cd aks-terraform`
`terraform init`

`terraform plan -out run.plan`

`terraform apply "run.plan"`

#### KUBECONFIG
`echo "$(terraform output kube_config)" > ~/.kube/azurek8s`

Also one can echo and copy content to local kubectl config.


`export KUBECONFIG=~/.kube/azurek8s`

#### Sanity
`kubectl get nodes`

`kubectl proxy`

Dashboard available at `http://localhost:8001/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/overview?namespace=default`

### Reporting bugs

Please report bugs  by opening an issue in the [GitHub Issue Tracker](https://github.com/dwaiba/aks-terraform/issues)

### Patches and pull requests

Patches can be submitted as GitHub pull requests. If using GitHub please make sure your branch applies to the current master as a 'fast forward' merge (i.e. without creating a merge commit). Use the `git rebase` command to update your branch to the current master if necessary.
