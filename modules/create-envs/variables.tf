#variable "resource_group_name" {}

variable "location" {
  default = "eastus"
}


#variable "env" {
#  default = "dev"
#}
variable "prefix" {
  default = "orgname"
}
#variable "github_org" {}
#variable "github_repo" {}

variable "admin_email" {}
variable "app_service_plan_tier" {
  default = "F1"
}


variable "envs" {
  default = ["dev", "stg", "uat"]
}

variable "mandatory_tags" {
  type        = map(any)
  description = "the map of labels to associate with every resource that supports tags"
}
