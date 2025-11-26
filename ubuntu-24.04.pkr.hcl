packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# Ubuntu server iso is the better choice here, you can always install a desktop later
variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}

variable "headless" {
  type    = bool
  default = false
}

source "virtualbox-iso" "ubuntu" {
  guest_os_type        = "Ubuntu_64"
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  headless             = var.headless

  ssh_username         = "vagrant"
  ssh_password         = "vagrant"
  ssh_timeout          = "30m"
  ssh_handshake_attempts = 100

  cpus   = 2
  memory = 4096
  disk_size = 25000

  guest_additions_mode = "upload"
  guest_additions_path = "VBoxGuestAdditions.iso"

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],
    ["modifyvm", "{{.Name}}", "--usb", "off"],
  ]

  #may need to increase this if your computer is slow to start virtualbox
  boot_wait = "5s"

  #this enables cloud-init by booting manually from the GRUB CLI
  #the magic jinja templates are populated by packer
  boot_command = [
    "c",
    "<wait>",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
  ]

  http_directory   = "http"
  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = "scripts/setup.sh"
  }

  post-processor "vagrant" {
    output = "ubuntu-24.04-{{.Provider}}.box"
  }
}
