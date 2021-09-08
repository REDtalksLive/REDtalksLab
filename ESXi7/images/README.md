# REDtalks.Lab Images

## Summary

This is where a summary goes.

## Images

1. Vanilla Debian Image `HashiStack/`
2. HashiStack Image - Consul, Vault, Nomad  - `HashiStack/`
3. Lab Automation Image - Consul, Terraform  - `IaCBox/`
4. Minikube  - `Minikube/`

## Use

Enter the relevant variables into the `*.auto.pkrvars.hcl` file. NOTE: there are example files in each directory identified by the extension, `.example`.

Execute:

`packer build .`

The OVA file will appear in a directory prefixed with `output-`, e.g. `output-rtlLabBaseVM`

## Details

### 1. HashiStack

Debian 10.10 ISO install with the following additions:

Debian installer packages: 
* ssh-server
* web-server

Additional packages:
* sudo
* wget
* curl
* open-vm-tools
* software-properties-common
* gnupg2
* git
* consul
* vault
* nomad

The HashiStack Packer template creates three `.OVA`s:

`rtLabDebianBaseVM.ova` - Plain Debian 10.10 OVA from the Debian ISO.

`rtLabDebianHashiStackVM.ova` - As above with Consul, Nomad, and Vault installed

`rtLabDebianHashiStackCtsVM.ova` - As above with Consul-Terraform-Sync installed


### 2. IaCbox

The IaCbox exists to run terraform deployments remotely. Why? Try building them over a VPN - ofvtool opens up 12+ OVA import streams across your VPN if you don't...

IaCbox instals the following packages:

* sudo
* wget
* curl
* open-vm-tools
* software-properties-common
* gnupg2
* git
* consul
* terraform
* packer
* jq
* nfs-common
