output "DC1_servers" {
    value = { for k, v in esxi_guest.ConsulServersDC1:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}"
        }
    }
}

output "DC2_servers" {
    value = { for k, v in esxi_guest.ConsulServersDC2:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}"
        }
    }
}

output "DC1_clients" {
    value = { for k, v in esxi_guest.ConsulClientsDC1:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}"
        }
    }
}

output "DC2_clients" {
    value = { for k, v in esxi_guest.ConsulClientsDC2:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}"
        }
    }
}

output "Mesh_Gateway1" {
  value = {
    name = "${esxi_guest.ConsulMeshGateway1.guest_name}" 
    ip = "${esxi_guest.ConsulMeshGateway1.ip_address}"
  }
}

output "Mesh_Gateway2" {
  value = {
    name = "${esxi_guest.ConsulMeshGateway2.guest_name}" 
    ip = "${esxi_guest.ConsulMeshGateway2.ip_address}"
  }
}
