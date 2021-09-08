datacenter        = "RTlab-dc-1"
data_dir          = "/opt/consul"
client_addr       = "0.0.0.0"   # UI Access
server            = true
node_name         = "${server_name}"
ui_config         = {
  enabled           = true
}
bootstrap_expect  = ${server_count}
retry_join        = [ ${servers_retry_join} ]
