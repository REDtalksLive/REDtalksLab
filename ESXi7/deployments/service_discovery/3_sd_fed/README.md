# Service Discovery: Federated

Builing on top of the 'Consul Service Discovery: Encrypt' Lab we will now enable Federation. To learn more about Consul Federation, navigate here:

* https://www.consul.io/docs/k8s/installation/multi-cluster
* https://learn.hashicorp.com/tutorials/consul/federation-gossip-wan

This REDtalks.lab consists of 6 Consul Servers (3 per Consul DC) and 6 consul clients (2 web services and 1 app service per Consul DC).

We use a common Gossip key across the two Consul DCs generated using the `consul keygen` command.

For HTTP and RPC encryption we will deploy separate TLS certificates per Consul DC.


## Use

This terraform deployment requires the packer image created in `images/hashistack/ESXi/`

Refer to the README.md in that same diretory for instructions.

One you have the image in a directory, or on via a HTTP server, you can execute the terraform deployment.

First, add your ESXi server details to the `terraform.tfvars` file, and then execute:

`terraform init`

`terraform plan`

`terraform apply`