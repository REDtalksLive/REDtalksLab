#####################################################################
# Base image w/ HashiCorp GPG key installed for APT Package Manager #
#####################################################################

# Because "You know nothing, John Snow": https://www.packer.io/docs/builders/vmware/iso

source "vmware-iso" "rtLabDebianBaseVM" {

  # ESXi Server that will perform the build/export

  remote_type      = "esx5"
  remote_host      = var.esxi_host
  remote_username  = var.esxi_username
  remote_password  = var.esxi_password
  remote_datastore = "ds1"
  # remote_cache_directory  = "/Packer/cache/" Sharing the cache dir will create a file lock error on parallel builds. 
  vnc_over_websocket  = true  # Required for ESXi VNC w/ vmware-iso builder.
  insecure_connection = true  # Required for ESXi VNC w/ vmware-iso builder.
  format              = "ova" # "ovf", "vmx"  # Always builds OVA/OVF locally. Ignores `remote_output_directory`


  # Properties of the VM we're building

  version              = "19"
  guest_os_type        = "debian11-64"
  network_name         = "VM Network" # For ESXi. Not required for Fusion Playa.
  network_adapter_type = "vmxnet3"
  disk_size            = 8192
  cpus                 = 1
  memory               = 2048


  # Things for Packer to do

  ovftool_options  = ["--overwrite", "--noImageFiles"]
  http_directory   = "http_preseed"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_sha256
  ssh_username     = var.guest_username
  ssh_password     = var.guest_password
  shutdown_command = "echo ${var.guest_password} | sudo -S shutdown -h now"
  vmx_data = {
    "annotation" = "open-vm-tools git"
  }

  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname={{ .Name }} <wait>",
    "netcfg/get_domain=redtalks.lab <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "grub-installer/bootdev=/dev/sda <wait>",
    "<enter><wait>"
  ]
}



#####################################################################
# Base image w/ HashiCorp GPG key installed for APT Package Manager #
#####################################################################

build {

  name = "rtLabDebianBaseVM"

  source "sources.vmware-iso.rtLabDebianBaseVM" {
    vm_name                 = "rtLabDebianBaseVM"
    display_name            = "rtLabDebianBaseVM"
    remote_output_directory = "/Packer/builds/rtLabDebianBaseVM" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabDebianBaseVM"
    output_directory        = "./output/rtLabDebianBaseVM/"
  }

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install ca-certificates"
    ]

  }

}



#####################################################################
#        Base image plus Consul, Vault, Nomad, CTS, and Envoy       #
#####################################################################

build {

  name = "rtLabDebianHashiStackVM"

  source "sources.vmware-iso.rtLabDebianBaseVM" {
    vm_name                 = "rtLabDebianHashiStackVM"
    display_name            = "rtLabDebianHashiStackVM"
    remote_output_directory = "/Packer/builds/rtLabDebianHashiStackVM" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabDebianHashiStackVM"
    output_directory        = "./output/rtLabDebianHashiStackVM/"
  }

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/sh -c \"/usr/bin/curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add - \"",
      "sleep 20",
      "/usr/bin/apt-add-repository -yu \"deb [ trusted=yes arch=amd64 ] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sleep 10",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install consul vault nomad consul-terraform-sync",
      "/usr/bin/apt-get -y install apt-transport-https ca-certificates",
      "/usr/bin/curl -1sLf 'https://deb.dl.getenvoy.io/public/setup.deb.sh' | /usr/bin/bash",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install getenvoy-envoy=1.18.2.p0.gd362e79-1p75.g76c310e"
    ]
  }

}

#####################################################################
#                    REDtalks.lab/chat - Database                   #
#                   HashiStack image plus MongoDB                   #
#####################################################################

build {

  name = "rtLabChatDatabase"

  source "sources.vmware-iso.rtLabDebianBaseVM" {
    vm_name                 = "rtLabChatDatabase"
    display_name            = "rtLabChatDatabase"
    remote_output_directory = "/Packer/builds/rtLabChatDatabase" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabChatDatabase"
    output_directory        = "./output/rtLabChatDatabase/"
  }

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/sh -c \"/usr/bin/curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add -\"",
      "sleep 20",
      "/usr/bin/apt-add-repository -yu \"deb [ trusted=yes arch=amd64 ] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sleep 10",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install consul vault nomad consul-terraform-sync",
      "/usr/bin/apt-get -y install apt-transport-https ca-certificates",
      "/usr/bin/curl -1sLf 'https://deb.dl.getenvoy.io/public/setup.deb.sh' | /usr/bin/bash",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install getenvoy-envoy=1.18.2.p0.gd362e79-1p75.g76c310e",
      "/usr/bin/sh -c \"/usr/bin/wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add -\"",
      "/usr/bin/echo \"deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main\" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "apt-get update",
      "apt-get install -y mongodb-org"
    ]
  }

}

#####################################################################
#              REDtalks.lab/chat - Front-end API & UI               #
#                   HashiStack image plus NodeJS                    #
#####################################################################

build {

  name = "rtLabChatFrontend"

  source "sources.vmware-iso.rtLabDebianBaseVM" {
    vm_name                 = "rtLabChatFrontend"
    display_name            = "rtLabChatFrontend"
    remote_output_directory = "/Packer/builds/rtLabChatFrontend" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabChatFrontend"
    output_directory        = "./output/rtLabChatFrontend/"
  }
#TODO: Add Nodejs and NPM
#TODO: Add git clone of rtlab_chat repo
#TODO: Add systemctl to auto-start

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/sh -c \"/usr/bin/curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add -\"",
      "sleep 20",
      "/usr/bin/apt-add-repository -yu \"deb [ trusted=yes arch=amd64 ] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sleep 10",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install consul vault nomad consul-terraform-sync",
      "/usr/bin/apt-get -y install apt-transport-https ca-certificates",
      "/usr/bin/curl -1sLf 'https://deb.dl.getenvoy.io/public/setup.deb.sh' | /usr/bin/bash",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install getenvoy-envoy=1.18.2.p0.gd362e79-1p75.g76c310e",
      "/usr/bin/curl -fsSL https://deb.nodesource.com/setup_12.x | /usr/bin/bash -",
      "/usr/bin/apt-get -y install nodejs"
    ]
  }

}