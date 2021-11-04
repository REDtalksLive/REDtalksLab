output "servers" {
  value = { for k, v in esxi_guest.ConsulServers :
    k => {
      name = "${v.guest_name}"
      ip   = "${v.ip_address}",
    }
  }
}

output "ServiceChatWebFrontend" {
  value = { for k, v in esxi_guest.ServiceChatWebFrontend :
    k => {
      name = "${v.guest_name}"
      ip   = "${v.ip_address}",
    }
  }
}

output "ServiceChatApi" {
  value = { for k, v in esxi_guest.ServiceChatApi :
    k => {
      name = "${v.guest_name}"
      ip   = "${v.ip_address}",
    }
  }
}

output "ServiceChatDatabase" {
  value = { for k, v in esxi_guest.ServiceChatDatabase :
    k => {
      name = "${v.guest_name}"
      ip   = "${v.ip_address}",
    }
  }
}

output "ingress_gateway_ip" {
  value = esxi_guest.ConsulIngressGateway1.ip_address
}