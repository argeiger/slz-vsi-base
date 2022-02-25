##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

##############################################################################


##############################################################################
# Resource Group where VPC is created
##############################################################################

data "ibm_resource_group" "resource_group" {
  name = var.resource_group
}

##############################################################################


##############################################################################
# Create VPCs
##############################################################################

locals {
  # Convert VPC List to Map
  vpc_map = {
    for vpc_network in var.vpcs :
    (vpc_network.prefix) => vpc_network
  }
}

module "vpc" {
  source   = "github.com/Cloud-Schematics/multizone-vpc-module.git"
  for_each = local.vpc_map

  resource_group_id           = data.ibm_resource_group.resource_group.id
  region                      = var.region
  prefix                      = "${var.prefix}-${each.value.prefix}"
  vpc_name                    = "vpc"
  classic_access              = each.value.classic_access
  use_manual_address_prefixes = each.value.use_manual_address_prefixes
  default_network_acl_name    = each.value.default_network_acl_name
  default_security_group_name = each.value.default_security_group_name
  default_routing_table_name  = each.value.default_routing_table_name
  address_prefixes            = each.value.address_prefixes
  network_acls                = each.value.network_acls
  use_public_gateways         = each.value.use_public_gateways
  subnets                     = each.value.subnets
}

##############################################################################


##############################################################################
# SSH key for creating VSI
##############################################################################

resource "ibm_is_ssh_key" "ssh_key" {
  name       = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key
}

##############################################################################


##############################################################################
# Add VPC to Flow Logs
##############################################################################

resource "ibm_is_flow_log" "flow_logs" {
  for_each       = module.vpc
  name           = "${each.key}-logs"
  target         = each.value.vpc_id
  active         = var.flow_logs.active
  storage_bucket = var.flow_logs.cos_bucket_name
  resource_group = data.ibm_resource_group.resource_group.id
}

##############################################################################