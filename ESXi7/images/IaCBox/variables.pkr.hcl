#####################################################################
# Base image w/ HashiCorp GPG key installed for APT Package Manager #
#####################################################################

variable "esxi_host" {
  type    = string
  default = ""
}

variable "esxi_username" {
  type    = string
  default = ""
}

variable "esxi_password" {
  type    = string
  default = ""
}

variable "guest_username" {
  type    = string
  default = ""
}

variable "guest_password" {
  type    = string
  default = ""
}

variable "iso_url" {
  type    = string
  default = ""
}

variable "iso_sha256" {
  type    = string
  default = ""
}
