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

  provisioner "local-exec" {
    command     = "/usr/bin/consul tls cert create -dc=RTlab-dc-2 -server"
    working_dir = "./certs"
  }

  provisioner "local-exec" {
    command     = "/usr/bin/consul tls cert create -dc=RTlab-dc-2 -client"
    working_dir = "./certs"
  }

}

##############################################
#  Using DNS entries for Consul server addrs
##############################################
#
data "dns_a_record_set" "dc1_resolved" {
  for_each = var.dc1_server_settings
  host = "${each.value.name}.redtalks.lab"
}

data "dns_a_record_set" "dc2_resolved" {
  for_each = var.dc2_server_settings
  host = "${each.value.name}.redtalks.lab"
}

##############################################
#  Required data for consul config files
##############################################
#
locals {
  dc1_servers_fqdn = "${join(", ", [ for k, v in data.dns_a_record_set.dc1_resolved: format("%q", v.id) ] )}"
  dc1_server_count = "${length(data.dns_a_record_set.dc1_resolved)}"
  
  dc2_servers_fqdn = "${join(", ", [ for k, v in data.dns_a_record_set.dc2_resolved: format("%q", v.id) ] )}"
  dc2_server_count = "${length(data.dns_a_record_set.dc2_resolved)}"
}

##############################################
#  Create Consul Servers for DC 1
##############################################
#
resource "esxi_guest" "ConsulServersDC1" {
  for_each = var.dc1_server_settings

  guest_name = each.value.name
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
  ovf_source        = var.ova_url

  network_interfaces {
    virtual_network = "VM Network"
    mac_address     = each.value.mac_addr  # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
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
    source      = "./certs/consul-agent-ca.pem"
    destination  = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/${each.value.dc}-server-consul-0.pem"
    destination  = "/tmp/${each.value.dc}-server-consul-0.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
      }
  }

  provisioner "file" {
    source      = "./certs/${each.value.dc}-server-consul-0-key.pem"
    destination  = "/tmp/${each.value.dc}-server-consul-0-key.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl",
      {
        servers_fqdn = local.dc1_servers_fqdn,
        wan_join_servers = "${local.dc1_servers_fqdn}, ${local.dc2_servers_fqdn}",
        server_count = local.dc1_server_count,
        gossip_key = random_id.gossip_key.b64_std,
        dc = each.value.dc
      })
    destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
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
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
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

##############################################
#  Create Consul Servers for DC 2
##############################################
#
resource "esxi_guest" "ConsulServersDC2" {
  for_each = var.dc2_server_settings

  guest_name = each.value.name
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
  ovf_source        = var.ova_url

  network_interfaces {
    virtual_network = "VM Network"
    mac_address     = each.value.mac_addr  # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
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
    source      = "./certs/consul-agent-ca.pem"
    destination  = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/${each.value.dc}-server-consul-0.pem"
    destination  = "/tmp/${each.value.dc}-server-consul-0.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/${each.value.dc}-server-consul-0-key.pem"
    destination  = "/tmp/${each.value.dc}-server-consul-0-key.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl",
      {
        servers_fqdn = local.dc2_servers_fqdn,
        wan_join_servers = "${local.dc1_servers_fqdn}, ${local.dc2_servers_fqdn}",
        server_count = local.dc2_server_count,
        gossip_key = random_id.gossip_key.b64_std,
        dc = each.value.dc
      })
    destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
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
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
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

##############################################
#  Create Consul Clients for DC1
##############################################
#
resource "esxi_guest" "ConsulClientsDC1" {
  for_each = var.dc1_client_settings

  guest_name = each.value.name
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
  ovf_source        = var.ova_url

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
    source      = "./certs/consul-agent-ca.pem"
    destination  = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl",
      {
        servers_fqdn = local.dc1_servers_fqdn,
        service_id = each.value.name,
        service_name = each.value.service,
        gossip_key = random_id.gossip_key.b64_std,
        dc = each.value.dc
      })
    destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
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
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${each.value.name}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
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

##############################################
#  Create Consul Clients for DC2
##############################################
#
resource "esxi_guest" "ConsulClientsDC2" {
  for_each = var.dc2_client_settings

  guest_name = each.value.name
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
  ovf_source        = var.ova_url

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
    source      = "./certs/consul-agent-ca.pem"
    destination  = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl",
      {
        servers_fqdn = local.dc2_servers_fqdn,
        service_id = each.value.name,
        service_name = each.value.service,
        gossip_key = random_id.gossip_key.b64_std,
        dc = each.value.dc
      })
    destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
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
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${each.value.name}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
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
