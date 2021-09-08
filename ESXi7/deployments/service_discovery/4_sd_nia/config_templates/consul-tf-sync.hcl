# Global Config Options
log_level = "info"

buffer_period {
  min = "5s"
  max = "20s"
}

# Consul Config Options
consul {
  address = "localhost:8500"
}

# Terraform Driver Options 
driver "terraform" {
  log = true
  path = "/opt/consul-tf-sync/"
  working_dir = "/opt/consul-tf-sync/"
}


## Consul Terraform Sync Task Definitions

task {
  name        = "taskinator"
  source      = "findkim/print/cts"
  version     = "0.1.0"
  services    = ["web", "api"]
}

