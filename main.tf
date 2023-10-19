terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.42.0"
    }
    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.13.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

variable "tenant_id" {
  description = "The Tenant ID for authentication"
  type        = string
}

variable "user_name" {
  description = "The username for authentication"
  type        = string
}

variable "password" {
  description = "The password for authentication"
  sensitive   = true
  type        = string
}

provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.us/"
  domain_name = "Default"
  tenant_id   = var.tenant_id
  user_name   = var.user_name
  password    = var.password
}

# provider "openstack" {
#   auth_url    = "https://auth.cloud.ovh.us/"
#   domain_name = "Default"
#   tenant_id   = "59c46d3a6cd54d66ade7c36e92279eaf"
#   user_name   = "user-yRhQhWf49pVd"
#   password    = "KHBFGu9CaYgNEFCet7DZ62CcE57nSZc4"
# }

variable "region" {
  type    = list(string)
  description = "List of regions for deployment"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 10
}

resource "random_pet" "vm_name" {
  count = var.instance_count
  length = 2
}

resource "openstack_compute_keypair_v2" "test_keypair_all" {
  count      = length(var.region)
  name       = "test_keypair_all"
  public_key = file("~/.ssh/id_rsa.pub")
  region     = element(var.region, count.index)
}

resource "openstack_compute_instance_v2" "instances_on_all_regions" {
  count        = var.instance_count
  name         = random_pet.vm_name[count.index].id
  flavor_name  = "d2-8"
  image_name   = "Debian 10 - Docker"
  region       = element(var.region, count.index % length(var.region))
  key_pair     = element(openstack_compute_keypair_v2.test_keypair_all.*.name, count.index % length(var.region))

  network {
     name = "Ext-Net"
  }

  security_groups = ["default"]

}

