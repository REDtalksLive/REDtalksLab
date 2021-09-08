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

##############################################
#  Required data for consul config files
##############################################
#
locals {
    servers_fqdn = "${join(", ", [ for k, v in data.dns_a_record_set.resolved: format("%q", v.id) ] )}"
    server_count = "${length(data.dns_a_record_set.resolved)}"
}

##############################################
#  Using DNS entries for Consul server addrs
##############################################
#
data "dns_a_record_set" "resolved" {
    for_each = var.server_settings
    host = "${each.value.name}.redtalks.lab"
}

##############################################
#  Create Consul Servers
##############################################
#
resource "esxi_guest" "ConsulServers" {
    for_each = var.server_settings

    guest_name = each.value.name
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
    ovf_source        = var.ova_url

    network_interfaces {
        virtual_network = "VM Network"
        mac_address     = each.value.mac_addr  # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
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
        source      = "./certs/RTlab-dc-1-server-consul-0.pem"
        destination  = "/tmp/RTlab-dc-1-server-consul-0.pem"
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = self.ip_address
        }
    }

    provisioner "file" {
        source      = "./certs/RTlab-dc-1-server-consul-0-key.pem"
        destination  = "/tmp/RTlab-dc-1-server-consul-0-key.pem"
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = self.ip_address
        }
    }

    provisioner "file" {
        content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl", { servers_fqdn = local.servers_fqdn, server_count = local.server_count, gossip_key = random_id.gossip_key.b64_std })
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
            "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-consul.sh",
            "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh",
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
#  Create Consul Clients
##############################################
#
resource "esxi_guest" "ConsulClients" {
  for_each = var.client_settings

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
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl", { servers_fqdn = local.servers_fqdn, service_id = each.value.name, service_name = each.value.service, gossip_key = random_id.gossip_key.b64_std })
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
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-consul.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh",   # /setup-systemd.sh <subcommand> <option>
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
#  Create Consul NIA Server
##############################################
#
resource "esxi_guest" "ConsulNIA" {

  guest_name = var.nia_settings.client1.name
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
  ovf_source        = var.ova_url_cts

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
    source      = "scripts/systemd-setup-consul-tf-sync.sh"
    destination = "/tmp/systemd-setup-consul-tf-sync.sh"
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
    content      = templatefile("${path.module}/config_templates/${var.nia_settings.client1.product}_${var.nia_settings.client1.mode}_${var.nia_settings.client1.config}.hcl", { servers_fqdn = local.servers_fqdn, service_id = var.nia_settings.client1.name, service_name = var.nia_settings.client1.service, gossip_key = random_id.gossip_key.b64_std })
    destination  = "/tmp/${var.nia_settings.client1.product}_${var.nia_settings.client1.mode}_${var.nia_settings.client1.config}.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/consul-tf-sync.hcl", { nia_settings = var.nia_settings.cts1 })
    destination  = "/tmp/consul-tf-sync.hcl"
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
      "echo ${var.vm_guest_password} | sudo -S mkdir /etc/consul-tf-sync.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul-tf-sync",
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${var.nia_settings.client1.name}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${var.nia_settings.client1.product}_${var.nia_settings.client1.mode}_${var.nia_settings.client1.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/consul-tf-sync.hcl /etc/consul-tf-sync.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul-tf-sync.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul-tf-sync",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-consul.sh",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-consul-tf-sync.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh",   # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul-tf-sync.sh",   # /setup-systemd.sh <subcommand> <option>
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

}