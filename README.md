# REDtalks.Lab
REDtalks.Lab images, deployments, configurations, and workflows open-sourced.

## Images
Reliable Infrastructure as Code patterns depend upon consistent base images. 
You can find the REDtalks.Lab images in: `ESXi7/images/`

Learn more in the `ESXi7/images/README.md`

## Deployments

Leveraging the images created with `packer` we can rapidly deploy infrastructure/architecutre using Terraform.
You can find the REDtalks.Lab terraform definitions in:

`ESXi7/deployments/`

Learn more in the `ESXi7/deployments/README.md`

## Requirements

Local installation of:

* packer
* terraform
* consul
* ovftool

`brew install packer consul terraform` - Install packer (free) macOS

`ovftool` (creates the OVA): https://my.vmware.com/group/vmware/downloads/details?downloadGroup=OVFTOOL441&productId=742
