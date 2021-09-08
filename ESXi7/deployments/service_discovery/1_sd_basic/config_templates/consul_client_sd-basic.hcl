datacenter    = "RTlab-dc-1"
data_dir      = "/opt/consul"
retry_join    = [ ${servers_fqdn} ]

service {
  name          = "${service_name}"
  meta          = ${service_meta}
}