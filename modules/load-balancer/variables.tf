variable "name" {}
variable "vpc_id" {}
variable "env" {}
variable "internal" {
  default = null
}
variable "lb_subnet_ids" {
  default = []
}
variable "allow_lb_sg_cidr" {
  default = []
}
variable "listener_port" {}
variable "listener_protocol" {}
variable "ssl_policy" {}
variable "acm_https_arn" {}
variable "laod_balancer_type" {}
variable "load-balancer" {}