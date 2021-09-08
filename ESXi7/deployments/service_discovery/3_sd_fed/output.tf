output "DC1_servers" {
    value = { for k, v in esxi_guest.ConsulServersDC1:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}

output "DC2_servers" {
    value = { for k, v in esxi_guest.ConsulServersDC2:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}

output "DC1_clients" {
    value = { for k, v in esxi_guest.ConsulClientsDC1:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}

output "DC2_clients" {
    value = { for k, v in esxi_guest.ConsulClientsDC2:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}
