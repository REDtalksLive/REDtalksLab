##############################################
#  Create Consul Servers
##############################################
#
resource "esxi_guest" "ConsulServers" {

  count = var.servers.count

  guest_name = "${var.servers.dc}-${var.servers.name_prefix}-${count.index}"
  disk_store = "ds1"

  boot_disk_type = "thin"
  boot_disk_size = "35"

  memsize            = "1024"
  numvcpus           = "1"
  resource_pool_name = "/"
  power              = "on"

  #    clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
  #    ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
  #    ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
  ovf_source = var.server_ova_url

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

}


##############################################
#  Required data for consul config files
##############################################
#
locals {
  servers_retry_join = join(", ", [for k, v in esxi_guest.ConsulServers : format("%q", v.ip_address)])
}


##############################################
#  Configure Consul Servers - Create Cluster
##############################################
#
resource "null_resource" "consul_cluster_config" {
  depends_on = [
    esxi_guest.ConsulServers
  ]

  count = length(esxi_guest.ConsulServers)

  provisioner "file" {
    source      = "scripts/systemd-setup-consul.sh"
    destination = "/tmp/systemd-setup-consul.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/RTlab-dc-1-server-consul-0.pem"
    destination = "/tmp/RTlab-dc-1-server-consul-0.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/RTlab-dc-1-server-consul-0-key.pem"
    destination = "/tmp/RTlab-dc-1-server-consul-0-key.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/config_templates/consul_server_sm-envoy.hcl",
      {
        servers_retry_join  = local.servers_retry_join,
        server_count        = var.servers.count,
        gossip_key          = random_id.gossip_key.b64_std
      }
    )
    destination = "/tmp/consul_server_sd-basic.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${var.servers.dc}-${var.servers.name_prefix}-${count.index}",
      "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/consul_server_sd-basic.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-consul.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh", # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S service consul restart",
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulServers[count.index].ip_address
    }
  }

}
