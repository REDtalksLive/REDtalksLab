##############################################
#  Generate Random Server Name IDs
##############################################
#
resource "random_id" "service_chat_db_id" {
  count = length(var.service_chat_database.services)
  keepers = {
    name = var.service_chat_database.services[count.index].name
  }
  byte_length = 8
}

##############################################
#  Create Chat Database Service
##############################################
#
resource "esxi_guest" "ServiceChatDatabase" {
  count = length(var.service_chat_database.services)
#  for_each = var.service_chat_database

  guest_name = "${var.service_chat_database.name_prefix}-${random_id.service_chat_db_id[count.index].keepers.name}-${random_id.service_chat_db_id[count.index].hex}"
  disk_store = "ds1"

  boot_disk_type = "thin"
  boot_disk_size = "12"

  memsize            = "1024"
  numvcpus           = "1"
  resource_pool_name = "/"
  power              = "on"

  #  clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
  #  ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
  #  ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
  ovf_source = var.web_service_ova_url

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

  provisioner "file" {
    source      = "scripts/systemd-setup-consul.sh"
    destination = "/tmp/systemd-setup-consul.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content     = templatefile("${path.module}/scripts/systemd-setup-envoy.sh", { service_id = "${var.service_chat_database.services[count.index].name}-${count.index}" })
    destination = "/tmp/systemd-setup-envoy.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/config_templates/consul_client_sm-envoy.hcl",
      {
        servers_retry_join    = local.servers_retry_join,
        service_id            = "${var.service_chat_database.services[count.index].name}-${count.index}"
        service_name          = var.service_chat_database.services[count.index].name,
        service_port          = var.service_chat_database.services[count.index].port,
        gossip_key            = random_id.gossip_key.b64_std,
        sidecar_config        = var.service_chat_database.services[count.index].sidecar
      }
    )
    destination = "/tmp/consul_client_sm-envoy.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${var.service_chat_database.services[count.index].name}-${count.index}",
      "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/consul_client_sm-envoy.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-*.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh", # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-envoy.sh",  # /setup-systemd.sh <subcommand> <option>
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
