
variable "project_id" { type = string }

variable "region" { type = string }

variable "name" { type = string } # prefix for every resource, e.g. "iris-dev"



variable "nodes_cidr" { type = string } # primary range: nodes

variable "pods_cidr" { type = string } # secondary range: pods

variable "services_cidr" { type = string } # secondary range: services




variable "node_service_account" { type = string } # created by the bootstrap

