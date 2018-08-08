resource "azurerm_resource_group" "k8s" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.cluster_name}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  dns_prefix          = "${var.dns_prefix}"
  kubernetes_version  = "1.10.6"

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = "${var.agent_count}"
    vm_size         = "${var.azurek8s_sku}"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
}

/**
resource "azurerm_storage_account" "acrstorageacc" {
  name                     = "${var.resource_storage_acct}"
  resource_group_name      = "${azurerm_resource_group.k8s.name}"
  location                 = "${azurerm_resource_group.k8s.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}
**/
resource "azurerm_container_registry" "acrtest" {
  name                = "${var.azure_container_registry_name}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  admin_enabled       = true
  sku                 = "Premium"

  /** storage_account_id  = "${azurerm_storage_account.acrstorageacc.id}" **/
}

resource "null_resource" "provision" {
  provisioner "local-exec" {
    command = "az aks get-credentials -n ${azurerm_kubernetes_cluster.k8s.name} -g ${azurerm_resource_group.k8s.name}"
  }

  provisioner "local-exec" {
    command = "curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl;"
  }

  provisioner "local-exec" {
    command = "chmod +x ./kubectl;"
  }

  provisioner "local-exec" {
    command = "mv ./kubectl /usr/local/bin/kubectl;"
  }

  provisioner "local-exec" {
    command = "curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh"
  }

  provisioner "local-exec" {
    command = "chmod 700 get_helm.sh"
  }

  provisioner "local-exec" {
    command = "./get_helm.sh"
  }

  provisioner "local-exec" {
    command = "kubectl config use-context ${azurerm_kubernetes_cluster.k8s.name}"
  }


  /**
                                      provisioner "local-exec" {
                                        command = "echo "$(terraform output kube_config)" > ~/.kube/azurek8s && export KUBECONFIG=~/.kube/azurek8s"
                                      } 
                                    **/

  provisioner "local-exec" {
    command = "helm init --upgrade"
  }

  provisioner "local-exec" {
    command = "kubectl create -f helm-rbac.yaml"
  }

  provisioner "local-exec" {
    command = <<EOF
            sleep 60
      EOF
  }

  provisioner "local-exec" {
    command = "helm install stable/cert-manager  --set ingressShim.defaultIssuerName=letsencrypt-staging  --set ingressShim.defaultIssuerKind=ClusterIssuer --set rbac.create=false  --set serviceAccount.create=false"
  }

  provisioner "local-exec" {
    command = "kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=\"${local.username}\""
  }

  /**
                                provisioner "local-exec" {
                                  command = "kubectl create -f azure-load-balancer.yaml"
                                }
                        **/
  provisioner "local-exec" {
    command = "helm repo add azure-samples https://azure-samples.github.io/helm-charts/"
  }

  provisioner "local-exec" {
    command = "helm repo update"
  }

  provisioner "local-exec" {
    command = "helm install stable/nginx-ingress --namespace kube-system --set rbac.create=false"
  }

  provisioner "local-exec" {
    command = "helm install azure-samples/aks-helloworld"
  }

  provisioner "local-exec" {
    command = "helm install -n hclaks stable/jenkins -f jenkins-values.yaml --version 0.16.18 --wait"

    timeouts {
      create = "12m"
      delete = "12m"
    }
  }

  provisioner "local-exec" {
    command = "wget -qO- https://azuredraft.blob.core.windows.net/draft/draft-v0.15.0-linux-amd64.tar.gz | tar xvz"
  }

  provisioner "local-exec" {
    command = "cp linux-amd64/draft /usr/local/bin/draft"
  }

  provisioner "local-exec" {
    command = "draft init"
  }

  provisioner "local-exec" {
    command = "draft config set registry ${azurerm_container_registry.acrtest.name}.azurecr.io"
  }

  provisioner "local-exec" {
    command = "helm repo add brigade https://azure.github.io/brigade"
  }

  provisioner "local-exec" {
    command = "helm install brigade/brigade --name brigade-server"
  }
}

/**
resource "azurerm_storage_account" "aci-sa" {
  name                     = "${var.resource_storage_acct}"
  resource_group_name      = "${azurerm_resource_group.k8s.name}"
  location                 = "${azurerm_resource_group.k8s.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "aci-share" {
  name = "${var.resource_aci-dev-share}"

  resource_group_name  = "${azurerm_resource_group.k8s.name}"
  storage_account_name = "${azurerm_storage_account.aci-sa.name}"

  quota = 50
}

resource "azurerm_container_group" "aci-helloworld" {
  name                = "${var.resource_aci-hw}"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  ip_address_type     = "public"
  dns_name_label      = "${var.resource_dns_aci-label}"
  os_type             = "linux"

  container {
    name   = "hw"
    image  = "seanmckenna/aci-hellofiles"
    cpu    = "0.5"
    memory = "1.5"
    port   = "80"

    environment_variables {
      "NODE_ENV" = "dev"
    }

    command = "/bin/bash -c '/path to/myscript.sh'"

    volume {
      name       = "logs"
      mount_path = "/aci/logs"
      read_only  = false
      share_name = "${var.resource_aci-dev-share}"

      storage_account_name = "${azurerm_storage_account.aci-sa.name}"
      storage_account_key  = "${azurerm_storage_account.aci-sa.primary_access_key}"
    }
  }

  container {
    name   = "sidecar"
    image  = "microsoft/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"
  }

  tags {
    environment = "Dev"
  }
}
**/

