##############################################
#  ESXI Provider host/login details
##############################################
#
provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}


##############################################
#  Consul LAN Gossip Encryption Key
##############################################
#
provider "random" {}

resource "random_id" "gossip_key" {
  byte_length = 32
}


##############################################
#  Generate certs for RPC
##############################################
#
resource "null_resource" "consul_certs" {

  provisioner "local-exec" {
    command     = "rm *.pem || true"
    working_dir = "./certs"
  }

  provisioner "local-exec" {
    command     = "/usr/bin/consul tls ca create"
    working_dir = "./certs"
  }

  provisioner "local-exec" {
    command     = "/usr/bin/consul tls cert create -dc=RTlab-dc-1 -server"
    working_dir = "./certs"
  }

  provisioner "local-exec" {
    command     = "/usr/bin/consul tls cert create -dc=RTlab-dc-1 -client"
    working_dir = "./certs"
  }

}