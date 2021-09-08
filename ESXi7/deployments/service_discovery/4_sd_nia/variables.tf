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

variable "ova_url" {
  type    = string
  default = ""
}

variable "ova_url_cts" {
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

variable "server_settings" {
  type = map(object({
    product     = string
    mode        = string
    config      = string
    name        = string
    mac_addr    = string
  }))
  default = {}
}

variable "client_settings" {
  type = map(object({
    product     = string
    mode        = string
    config      = string
    name        = string
    service     = string
  }))
  default = {}
}

variable "nia_settings" {
  type = map(object({
    product     = string
    mode        = string
    config      = string
    name        = string
    service     = string
  }))
  default = {}
}