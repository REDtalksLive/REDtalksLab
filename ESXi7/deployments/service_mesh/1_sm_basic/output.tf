output "servers" {
    value = { for k, v in esxi_guest.ConsulServers:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}

output "clients" {
    value = { for k, v in esxi_guest.ConsulClients:
        k => {
            name = "${v.guest_name}" 
            ip = "${v.ip_address}",
        }
    }
}

output "ingress_gateway_ip" {
  value = esxi_guest.ConsulIngressGateway1.ip_address
}