##############################################
#  Generate Random Server Name IDs
##############################################
#
resource "random_id" "server_name" {
  count = length(var.service_settings.services)
  keepers = {
    name = var.service_settings.services[count.index].name
  }
  byte_length = 8
}

##############################################
#  Create Consul Client Virtual Machines
##############################################
#
resource "esxi_guest" "ConsulClients" {
  count = length(var.service_settings.services) # change this to for_each.

  guest_name = "${var.service_settings.name_prefix}-${random_id.server_name[count.index].keepers.name}-${random_id.server_name[count.index].hex}"
  disk_store = "ds1"

  boot_disk_type = "thin"
  boot_disk_size = "35"

  memsize            = "1024"
  numvcpus           = "1"
  resource_pool_name = "/"
  power              = "on"

  #  clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
  #  ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
  #  ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
  ovf_source = var.ova_url

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

  provisioner "file" {
    source      = "scripts/systemd-setup.sh"
    destination = "/tmp/systemd-setup.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content     = templatefile("${path.module}/config_templates/consul_client_sd-basic.hcl",
      {
        servers_fqdn = local.servers_retry_join,
        service_name = var.service_settings.services[count.index].name
        service_meta = var.service_settings.services[count.index].meta
      })
    destination = "/tmp/consul_client_sd-basic.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${var.service_settings.name_prefix}-${random_id.server_name[count.index].keepers.name}-${random_id.server_name[count.index].hex}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/consul_client_sd-basic.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh", # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S service consul restart",
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

}