provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

terraform {
  required_version = "< 0.12.0"
}

/************
* Variables *
*************/
variable "env_name" {}

variable "dns_suffix" {}
variable "access_key" {}
variable "secret_key" {}
variable "region" {}

variable "availability_zones" {
  type = "list"
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "hosted_zone" {
  default = ""
}

/**************
* Ops Manager *
***************/
variable "ops_manager_ami" {
  default = ""
}

variable "optional_ops_manager_ami" {
  default = ""
}

variable "ops_manager_instance_type" {
  default = "r4.large"
}

variable "ops_manager_private" {
  default     = false
  description = "If true, the Ops Manager will be colocated with the BOSH director on the infrastructure subnet instead of on the public subnet"
}

variable "ops_manager_vm" {
  default = true
}

variable "optional_ops_manager" {
  default = false
}

/******
* RDS *
*******/
variable "rds_db_username" {
  default = "admin"
}

variable "rds_instance_class" {
  default = "db.m4.large"
}

variable "rds_instance_count" {
  type    = "string"
  default = 0
}

/******
* SSL *
*******/

variable "ssl_cert" {
  default = ""
}
variable "ssl_private_key" {
  default = ""
}
variable "ssl_ca_cert" {
  default = ""
}
variable "ssl_ca_private_key" {
  default = ""
}

/********
* Tags  *
*********/
variable "tags" {
  type        = "map"
  default     = {}
  description = "Key/value tags to assign to all AWS resources"
}

locals {
  ops_man_subnet_id = "${var.ops_manager_private ? element(module.infra.infrastructure_subnet_ids, 0) : element(module.infra.public_subnet_ids, 0)}"

  bucket_suffix = "${random_integer.bucket.result}"

  default_tags = {
    Environment = "${var.env_name}"
    Application = "Control Plane"
  }

  actual_tags = "${merge(var.tags, local.default_tags)}"
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

module "infra" {
  source = "../modules/infra"

  region             = "${var.region}"
  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_cidr           = "${var.vpc_cidr}"

  hosted_zone = "${var.hosted_zone}"
  dns_suffix  = "${var.dns_suffix}"

  tags = "${local.actual_tags}"
}

module "ops_manager" {
  source = "../modules/ops_manager"

  vm_count       = "${var.ops_manager_vm ? 1 : 0}"
  optional_count = "${var.optional_ops_manager ? 1 : 0}"
  subnet_id      = "${local.ops_man_subnet_id}"

  env_name      = "${var.env_name}"
  region        = "${var.region}"
  ami           = "${var.ops_manager_ami}"
  optional_ami  = "${var.optional_ops_manager_ami}"
  instance_type = "${var.ops_manager_instance_type}"
  private       = "${var.ops_manager_private}"
  vpc_id        = "${module.infra.vpc_id}"
  vpc_cidr      = "${var.vpc_cidr}"
  dns_suffix    = "${var.dns_suffix}"
  zone_id       = "${module.infra.zone_id}"

  # additional_iam_roles_arn = ["${module.pas.iam_pas_bucket_role_arn}"]
  bucket_suffix = "${local.bucket_suffix}"

  tags = "${local.actual_tags}"
}

module "control_plane" {
  source                  = "../modules/control_plane"
  vpc_id                  = "${module.infra.vpc_id}"
  env_name                = "${var.env_name}"
  availability_zones      = "${var.availability_zones}"
  vpc_cidr                = "${var.vpc_cidr}"
  public_subnet_ids       = "${module.infra.public_subnet_ids}"
  private_route_table_ids = "${module.infra.private_route_table_ids}"
  tags                    = "${local.actual_tags}"
  region                  = "${var.region}"
  dns_suffix              = "${var.dns_suffix}"
  zone_id                 = "${module.infra.zone_id}"
}

module "rds" {
  source = "../modules/rds"

  rds_db_username    = "${var.rds_db_username}"
  rds_instance_class = "${var.rds_instance_class}"
  rds_instance_count = "${var.rds_instance_count}"

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_cidr           = "${var.vpc_cidr}"
  vpc_id             = "${module.infra.vpc_id}"

  tags = "${local.actual_tags}"
}

module "certs" {
  source = "../modules/certs"

  subdomains = ["plane"]
  env_name   = "${var.env_name}"
  dns_suffix = "${var.dns_suffix}"

  ssl_cert           = "${var.ssl_cert}"
  ssl_private_key    = "${var.ssl_private_key}"
  ssl_ca_cert        = "${var.ssl_ca_cert}"
  ssl_ca_private_key = "${var.ssl_ca_private_key}"
}

/**********
* Outputs *
***********/

output "iaas" {
  value = "aws"
}

output "region" {
  value = "${var.region}"
}

output "azs" {
  value = "${var.availability_zones}"
}

output "dns_zone_id" {
  value = "${module.infra.zone_id}"
}

output "env_dns_zone_name_servers" {
  value = "${module.infra.name_servers}"
}

output "vms_security_group_id" {
  value = "${module.infra.vms_security_group_id}"
}

output "public_subnet_ids" {
  value = "${module.infra.public_subnet_ids}"
}

output "public_subnets" {
  value = "${module.infra.public_subnet_ids}"
}

output "public_subnet_availability_zones" {
  value = "${module.infra.public_subnet_availability_zones}"
}

output "public_subnet_cidrs" {
  value = "${module.infra.public_subnet_cidrs}"
}

output "infrastructure_subnet_ids" {
  value = "${module.infra.infrastructure_subnet_ids}"
}

output "infrastructure_subnets" {
  value = "${module.infra.infrastructure_subnets}"
}

output "infrastructure_subnet_availability_zones" {
  value = "${module.infra.infrastructure_subnet_availability_zones}"
}

output "infrastructure_subnet_cidrs" {
  value = "${module.infra.infrastructure_subnet_cidrs}"
}

output "infrastructure_subnet_gateways" {
  value = "${module.infra.infrastructure_subnet_gateways}"
}

output "vpc_id" {
  value = "${module.infra.vpc_id}"
}

output "network_name" {
  value = "${module.infra.vpc_id}"
}

/**************
* Ops Manager *
***************/
output "ops_manager_bucket" {
  value = "${module.ops_manager.bucket}"
}

output "ops_manager_public_ip" {
  value = "${module.ops_manager.public_ip}"
}

output "ops_manager_dns" {
  value = "${module.ops_manager.dns}"
}

output "optional_ops_manager_dns" {
  value = "${module.ops_manager.optional_dns}"
}

output "ops_manager_iam_instance_profile_name" {
  value = "${module.ops_manager.ops_manager_iam_instance_profile_name}"
}

output "ops_manager_iam_user_name" {
  value = "${module.ops_manager.ops_manager_iam_user_name}"
}

output "ops_manager_iam_user_access_key" {
  value = "${module.ops_manager.ops_manager_iam_user_access_key}"
}

output "ops_manager_iam_user_secret_key" {
  value     = "${module.ops_manager.ops_manager_iam_user_secret_key}"
  sensitive = true
}

output "ops_manager_security_group_id" {
  value = "${module.ops_manager.security_group_id}"
}

output "ops_manager_private_ip" {
  value = "${module.ops_manager.ops_manager_private_ip}"
}

output "ops_manager_ssh_private_key" {
  sensitive = true
  value     = "${module.ops_manager.ssh_private_key}"
}

output "ops_manager_ssh_public_key_name" {
  value = "${module.ops_manager.ssh_public_key_name}"
}

output "ops_manager_ssh_public_key" {
  value = "${module.ops_manager.ssh_public_key}"
}

/******
* RDS *
*******/
output "rds_address" {
  value = "${module.rds.rds_address}"
}

output "rds_port" {
  value = "${module.rds.rds_port}"
}

output "rds_username" {
  value = "${module.rds.rds_username}"
}

output "rds_password" {
  sensitive = true
  value     = "${module.rds.rds_password}"
}

/******
* SSL *
*******/
output "ssl_cert" {
  sensitive = true
  value     = "${module.certs.ssl_cert}"
}

output "ssl_private_key" {
  sensitive = true
  value     = "${module.certs.ssl_private_key}"
}

/****************
* Control Plane *
*****************/
output "control_plane_domain" {
  value = "${module.control_plane.domain}"
}

output "control_plane_lb_target_groups" {
  value = "${module.control_plane.lb_target_groups}"
}

output "control_plane_subnet_ids" {
  value = "${module.control_plane.subnet_ids}"
}

output "control_plane_subnet_gateways" {
  value = "${module.control_plane.subnet_gateways}"
}

output "control_plane_subnet_cidrs" {
  value = "${module.control_plane.subnet_cidrs}"
}

output "control_plane_subnet_availability_zones" {
  value = "${module.control_plane.subnet_availability_zones}"
}