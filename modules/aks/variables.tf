variable "resource_group_name" {}

variable "location" {
  default = "centralus"
}

variable "env" {
  default = "dev"
}
variable "prefix" {
  default = "orgname"
}

//add kubernetes version variable
variable "kubernetes_version" {
  default = "1.26.0"
}

//add aks vm size variable
variable "vm_size" {
  default = "Standard_D2s_v3"
}
