#####################################################################
# Base image w/ HashiCorp GPG key installed for APT Package Manager #
#####################################################################

# Because "You know nothing, John Snow": https://www.packer.io/docs/builders/vmware/iso

source "vmware-iso" "rtLabDebianMinikubeBaseVM" {

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
  disk_size            = 20480
  cpus                 = 2
  memory               = 4096


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
    "vhv.enable" = "TRUE"
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

  name = "rtLabDebianMinikubeBaseVM"

  source "sources.vmware-iso.rtLabDebianMinikubeBaseVM" {
    vm_name                 = "rtLabDebianMinikubeBaseVM"
    display_name            = "rtLabDebianMinikubeBaseVM"
    remote_output_directory = "/Packer/builds/rtLabDebianMinikubeBaseVM" # format="ova" ignores `remote_output_directory`
    remote_cache_directory  = "/Packer/cache/rtLabDebianMinikubeBaseVM"
    output_directory        = "./output/rtLabDebianMinikubeBaseVM/"
  }


#### Install minikube

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/apt-get -y update",
      "/usr/bin/apt-get -y install --no-install-recommends qemu-system libvirt-clients libvirt-daemon-system dnsmasq",   # KVM2 https://wiki.debian.org/KVM#Installation
      "/usr/sbin/adduser debian libvirt",
      "echo \"LIBVIRT_DEFAULT_URI='qemu:///system'\" >> /etc/profile",
      "/usr/bin/curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb",
      "/usr/bin/dpkg -i minikube_latest_amd64.deb"
    ]
  }


#### Install helm

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "/usr/bin/sh -c \"/usr/bin/curl https://baltocdn.com/helm/signing.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 /usr/bin/apt-key add -\"",
      "apt-get install apt-transport-https --yes",
      "echo \"deb https://baltocdn.com/helm/stable/debian/ all main\" | tee /etc/apt/sources.list.d/helm-stable-debian.list",
      "apt-get update",
      "apt-get install helm"
    ]
  }


#### Install kubectl

  provisioner "shell" {
    execute_command = "echo '${var.guest_password}' | {{.Vars}} sudo -S '{{.Path}}'"
    inline = [
      "apt-get update",
      "apt-get install -y apt-transport-https ca-certificates curl",
      "curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main\" | tee /etc/apt/sources.list.d/kubernetes.list",
      "apt-get update",
      "apt-get install -y kubectl"
    ]
  }

}
