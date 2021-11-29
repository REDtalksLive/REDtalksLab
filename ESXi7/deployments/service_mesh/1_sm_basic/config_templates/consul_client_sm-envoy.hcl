datacenter    = "RTlab-dc-1"
data_dir      = "/opt/consul"
retry_join    = [ ${servers_retry_join} ]
encrypt       = "${gossip_key}"

#bind_addr     = "{{ GetInterfaceIP \"eth0\" }}"
#bind_addr     = "{{ GetPrivateInterfaces | include \"network\" \"192.168.1.0/24\" | attr \"address\" }}"
#bind_addr     = "{{ GetAllInterfaces | include \"name\" \"^eth\" | include \"flags\" \"forwardable|up\" | attr \"address\" }}"

verify_incoming = false,
verify_outgoing = true,
verify_server_hostname = true,
ca_file = "/opt/consul/certs/consul-agent-ca.pem",

auto_encrypt = {
  tls = true
}

service {
  id            = "${service_id}"
  name          = "${service_name}"
  port          = ${service_port}
  connect {
    sidecar_service = ${sidecar_config}
  }
}

ports {
  grpc = 8502
}