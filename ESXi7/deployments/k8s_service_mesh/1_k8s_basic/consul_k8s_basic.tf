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
resource "esxi_guest" "miniKube1" {

    guest_name = "minkube1"
    disk_store = "ds1"
  
    boot_disk_type = "thin"
    boot_disk_size = "35"
  
    memsize            = "4096"
    numvcpus           = "2"
    resource_pool_name = "/"
    power              = "on"
  
#    clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
#    ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
#    ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
    ovf_source        = var.ova_url

    network_interfaces {
        virtual_network = "VM Network"
#        mac_address     = each.value.mac_addr  # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
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

    provisioner "remote-exec" {
        inline = [  
            "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
            "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh",
            "echo ${var.vm_guest_password} | sudo -S service minikube restart",
        ]
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = self.ip_address
        }
    }

}
