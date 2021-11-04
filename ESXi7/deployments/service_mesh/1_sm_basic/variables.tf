#
#  See https://www.terraform.io/intro/getting-started/variables.html for more details.
#

#  Change these defaults to fit your needs!

variable "esxi_hostname" {
  type    = string
  default = ""
}

variable "esxi_hostport" {
  type    = string
  default = "22"
}

variable "esxi_hostssl" {
  type    = string
  default = "443"
}

variable "esxi_username" {
  type    = string
  default = ""
}

variable "esxi_password" { # Unspecified will prompt
  type    = string
  default = ""
}

variable "server_ova_url" {
  type    = string
  default = ""
}

variable "web_service_ova_url" {
  type    = string
  default = ""
}

variable "db_service_ova_url" {
  type    = string
  default = ""
}

variable "vm_guest_username" {
  type    = string
  default = ""
}

variable "vm_guest_password" {
  type    = string
  default = ""
}

variable "servers" {
  type = object({
    count       = number
    dc          = string
    name_prefix = string
  })
  default = {
    count = 3
    dc    = "rtlab-dc-1"
    name_prefix = "consul-server-"
  }
}

variable "service_chat_web_frontend" {
  type = object({
    name_prefix = string
    services = list(object({
      name = string
      meta = string
      port = number
      sidecar = string
    }))
  })
}

variable "service_chat_api" {
  type = object({
    name_prefix = string
    services = list(object({
      name = string
      meta = string
      port = number
      sidecar = string
    }))
  })
}

variable "service_chat_database" {
  type = object({
    name_prefix = string
    services = list(object({
      name = string
      meta = string
      port = number
      sidecar = string
    }))
  })
}

variable "ingress_gateway_1" {
  type = object({
    name    = string
  })
}