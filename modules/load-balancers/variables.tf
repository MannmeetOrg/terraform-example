variable "name" {}
variable "vpc_id" {}
variable "env" {}
variable "allow_port" {}
variable "internal" {
  default = null
}
variable "lb_subnet_ids" {
  default = []
}
variable "allow_lb_sg_cidr" {
  default = []
}
variable "zone_id" {}
variable "listener_port" {}
variable "listener_protocol" {}
variable "ssl_policy" {}
variable "acm_https_arn" {}