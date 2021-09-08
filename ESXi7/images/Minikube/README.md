# Packer Builder for OVA creation on ESXi 7

REDtalks.lab base Virtual Machine
* Debian 10.10.0
* Webserver
* OpenSSH
* Minikube
* Helm
* kubectl

## Requirements

`brew install packer` - Install packer (free) macOS


## Use

### Option A - Auto Vars

Enter the relevant variables into the `*.auto.pkrvars.hcl` file. 

Execute:

`packer build .`

The OVA file will appear in the directory `./output`

---
### Option B - Command Flags

If you don't want to use the `*.auto.pkrvars.hcl` file you can provid ethe variable via the command line:

```sh
packer build \
 -var esxi_host=<esx_server_addr> \
 -var esxi_user=<user_name> \
 -var esxi_password=<password> \
 consul-base-image.pkr.hcl 
```

### Option C - Environment Variables

```sh
export esxi_host=<esx_server_addr>
export esxi_user=<user_name>
export esxi_password=<password>
packer build .
```