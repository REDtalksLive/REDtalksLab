datacenter    = "RTlab-dc-1"
data_dir      = "/opt/consul"
retry_join    = [ ${servers_fqdn} ]
encrypt       = "${gossip_key}"

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
  connect {
    sidecar_service = ${sidecar_config}
  }
}

ports {
  grpc = 8502
}