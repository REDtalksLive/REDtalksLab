##############################################
#  Create Consul Ingress Gateway
##############################################
#
resource "esxi_guest" "ConsulIngressGateway1" {

  depends_on = [
    esxi_guest.ConsulServers # Makre sure servers are ready for the `consul config write` commands run on the gateway
  ]

  guest_name = var.ingress_gateway_1.name
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
  ovf_source = var.server_ova_url

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
      host     = esxi_guest.ConsulIngressGateway1.ip_address
    }
  }

  provisioner "file" {
    content = templatefile("scripts/systemd-setup-ingress-gateway.sh",
      {
        consul_dc = "RTlab-dc-1",
    })
    destination = "/tmp/systemd-setup-ingress-gateway.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulIngressGateway1.ip_address
    }
  }

  provisioner "file" {
    source      = "./certs/consul-agent-ca.pem"
    destination = "/tmp/consul-agent-ca.pem"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulIngressGateway1.ip_address
    }
  }

  provisioner "file" {
    content = templatefile("${path.module}/config_templates/consul_ingress_gateway.hcl",
      {
        servers_retry_join  = local.servers_retry_join,
        service_id          = var.ingress_gateway_1.name,
        gossip_key          = random_id.gossip_key.b64_std,
        consul_dc           = "RTlab-dc-1"
      }
    )
    destination = "/tmp/consul_ingress_gateway.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulIngressGateway1.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${var.ingress_gateway_1.name}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/consul_ingress_gateway.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S mkdir /opt/consul/certs",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/*.pem /opt/consul/certs/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /opt/consul/",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup-*.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-consul.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup-ingress-gateway.sh", # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S service consul restart",
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = esxi_guest.ConsulIngressGateway1.ip_address
    }
  }

}