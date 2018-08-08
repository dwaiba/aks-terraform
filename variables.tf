/**
variable "resource_group_name" {
  default = "hclaks"
}
**/
variable "resource_group_name" {}

variable "location" {
  default = "westeurope"
}

/**
variable "client_id" {
  default     = ""
}

variable "client_secret" {
  default     = ""
}
**/
variable "client_id" {}

variable "client_secret" {}

variable "cluster_name" {}

variable "dns_prefix" {}
variable "azure_container_registry_name" {}

/**
variable "cluster_name" {
  default = "hclaks"
}

variable "dns_prefix" {
  default = "hclaks"
}
**/
variable "ssh_public_key" {
  default = "/aks-terraform/id_rsa.pub"
}

variable "admin_username" {
  default = "aksadmin"
}

variable "agent_count" {}

variable "azurek8s_sku" {
  default = "Standard_F2s"
}

variable "resource_storage_acct" {
  default = "acisa12345"
}

/**
variable "resource_aci-dev-share" {
  default = "aci-dev-share"
}

variable "resource_aci-hw" {
  default = "aci-helloworld"
}

variable "resource_dns_aci-label" {
  default = "aci-dev-hw"
}
**/
locals {
  username = "clusterUser_${var.cluster_name}_{$var.cluster_name}"
}
