# Service Mesh: Federated

Building on top of the *Service Mesh: Basic* lab we wil now enable Service Mesh Federation (two seperate Consul datacenters talking to each other).

To learn more about consul wan feredation navigate here: https://learn.hashicorp.com/tutorials/consul/federation-gossip-wan

This REDtalks.lab consists of 6 Consul Servers (3 servers in each Consul DC) and 12 consul clients (2 web services, 2 api service, and 2 app services per consul DC). Both the Web Services and the API Services are configured with the App Services as their upstreams.

Controlled/configured by the Consul control-plane, the envoy proxy acts as the mTLS dataplane for service to service communication.


## Use

This terraform deployment requires the packer image created in `images/ESXi7/debianConsulMeshEnvoy/`

Refer to the README.md in that same diretory for instructions.

One you have the image in a director, or on via a HTTP server, you can execute the terraform deployment.

First, add your ESXi server details to the `terraform.tfvars` file, and then execute:

`terraform init`

`terraform plan`

`terraform apply`