# Service Discovery: Encrypt

Builing on top of the 'Consul Service Discovery: Basic' Lab we will now enable Encryption. To learn more about Consul Encryption, navigate here: https://www.consul.io/docs/security

This REDtalks.lab consists of 3 Consul Servers and 5 consul clients (3 web services, 2 app services) registered in the Consul Services Catalog using control-plane Encryption.

There are two separate encryption systems, one for gossip traffic and one for HTTP + RPC.

For LAN Gossip we generate a key using the `consul keygen` command.

For HTTP and RPC encryption we will deploy TLS certificates.


## Use

This terraform deployment requires the packer image created in `images/hashistack/ESXi/`

Refer to the README.md in that same diretory for instructions.

One you have the image in a director, or on via a HTTP server, you can execute the terraform deployment.

First, add your ESXi server details to the `terraform.tfvars` file, and then execute:

`terraform init`

`terraform plan`

`terraform apply`