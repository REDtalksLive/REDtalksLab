datacenter        = "${dc}"
data_dir          = "/opt/consul"
client_addr       = "0.0.0.0"
server            = true
encrypt           = "${gossip_key}"
ui_config         = {
  enabled           = true
}
bootstrap_expect  = ${server_count}
retry_join        = [ ${servers_fqdn} ]

retry_join_wan = [ ${wan_join_servers} ]

verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
ca_file = "/opt/consul/certs/consul-agent-ca.pem"
cert_file = "/opt/consul/certs/${dc}-server-consul-0.pem"
key_file = "/opt/consul/certs/${dc}-server-consul-0-key.pem"

auto_encrypt {
  allow_tls = true
}

