datacenter    = "RTlab-dc-1"
data_dir      = "/opt/consul"
retry_join    = [ ${servers_retry_join} ]
encrypt       = "${gossip_key}"

verify_incoming = false,
verify_outgoing = true,
verify_server_hostname = true,
ca_file = "/opt/consul/certs/consul-agent-ca.pem",

auto_encrypt = {
  tls = true
}

ports {
  grpc = 8502
}