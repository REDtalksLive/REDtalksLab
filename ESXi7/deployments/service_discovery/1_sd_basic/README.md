# Service Discovery: Basic

This REDtalks.lab consists of 3 Consul Servers and 5 consul clients (3 web services, 2 app services) registered in the Consul Services Catalog.

## Use

This terraform deployment requires the packer image created in `images/hashistack/ESXi/`

Refer to the README.md in that same diretory for instructions.

One you have the image in a director, or on via a HTTP server, you can execute the terraform deployment.

First, add your ESXi server details to the `terraform.tfvars` file, and then execute:

`terraform init`

`terraform plan`

`terraform apply`