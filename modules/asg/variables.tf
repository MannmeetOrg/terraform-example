variable "name" {}
variable "instance_type" {}
variable "subnet_ids" {}
variable "vpc_id" {}
variable "env" {}
variable "bastion_nodes" {}
variable "allow_port" {}
variable "allow_sg_cidr" {}
variable "capacity" {
default = []
}
variable "asg" {}
variable "vault_token" {}
variable "zone_id" {}
variable "dns_name" {}
variable "listener_arn" {}
variable "lb_rule_priority" {}