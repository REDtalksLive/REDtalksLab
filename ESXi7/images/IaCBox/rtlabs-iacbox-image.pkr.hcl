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
  guest_os_type        = "debian10-64"
  network_name         = "VM Network" # For ESXi. Not required for Fusion Playa.
  network_adapter_type = "vmxnet3"
  disk_size            = 8192
  cpus                 = 2
  memory               = 2048


  # Things for Packer to do

  ovftool_options  = ["--overwrite"]
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
#                Base image plus Terraform & Consul                 #
#####################################################################

build {

  name = "rtLabDebianIaCVM"

  source "sources.vmware-iso.rtLabDebianBaseVM" {
    vm_name                 = "rtLabDebianIaCVM"
    display_name            = "rtLabDebianIaCVM"
    remote_output_directory = "/Packer/builds/rtLabDebianIaCVM" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabDebianIaCVM"
    output_directory        = "./output/rtLabDebianIaCVM/"
  }

  provisioner "file" {
    source      = "./tools/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle"
    destination = "/var/tmp/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle"
  }

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "chmod +x /var/tmp/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle",
      "/var/tmp/VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle --eulas-agreed",
      "/usr/bin/sh -c \"/usr/bin/curl -fsSL https://apt.releases.hashicorp.com/gpg | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add -\"",
      "sleep 20",
      "/usr/bin/apt-add-repository -yu \"deb [ trusted=yes arch=amd64 ] https://apt.releases.hashicorp.com $(lsb_release -cs) main\"",
      "sleep 10",
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install consul terraform packer jq nfs-common",
      "mkdir /mnt/rtlabnfs",
      "echo \"nas.redtalks.lab:/volume1/Shared /mnt/rtlabnfs nfs defaults,user,relatime,rw 0 0\" >> /etc/fstab"
    ]
  }

}
