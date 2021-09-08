# Service Discovery: Network Infrastructure Automation (NIA)

Builing on top of the 'Consul Service Discovery: Encrypt' Lab we will now enable Network Infrastructure Automation (NIA). To learn more about Consul NIA, navigate here: https://www.consul.io/docs/nia

This REDtalks.lab consists of 3 Consul Servers, 5 consul clients (3 web services, 2 app services), 1 Consul-Terraform-Sync server, and some network infrastructure in need of automation.


## Use

This terraform deployment requires the packer image created in `images/hashistack/ESXi/`

Refer to the README.md in that same diretory for instructions.

One you have the image in a director, or on via a HTTP server, you can execute the terraform deployment.

First, add your ESXi server details to the `terraform.tfvars` file, and then execute:

`terraform init`

`terraform plan`

`terraform apply`