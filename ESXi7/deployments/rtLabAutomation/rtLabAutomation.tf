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
#  Create Consul Servers
##############################################
#
resource "esxi_guest" "rtLabAutomation" {

  guest_name = "rtLabAutomation"
  disk_store = "ds1"

  boot_disk_type = "thin"
  boot_disk_size = "35"

  memsize            = "2048"
  numvcpus           = "2"
  resource_pool_name = "/"
  power              = "on"

  ovf_source = var.ova_url

  network_interfaces {
    virtual_network = "VM Network"
    mac_address     = var.mac_addr # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
    nic_type        = "vmxnet3"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/REDtalksLive/REDtalksLabs.git"
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.rtLabAutomation.ip_address
    }

  }

}