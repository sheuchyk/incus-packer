variable "image_name" {
  type        = string
  default     = "debian-salt"
  description = "Name of the output image"
}

variable "image_description" {
  type        = string
  default     = "Debian image provisioned with Salt"
  description = "Description of the output image"
}

variable "source_image" {
  type        = string
  default     = "images:debian/12"
  description = "Source image to use (e.g., images:debian/12, images:debian/11)"
}

variable "virtual_machine" {
  type        = bool
  default     = false
  description = "Build as virtual machine instead of container"
}

variable "profile" {
  type        = string
  default     = "default"
  description = "Incus profile to use"
}

variable "static_ip" {
  type        = string
  default     = "172.16.0.33/16"
  description = "Static IP address with CIDR notation"
}

variable "gateway" {
  type        = string
  default     = "172.16.0.2"
  description = "Default gateway"
}

source "incus" "debian" {
  image           = var.source_image
  output_image    = var.image_name
  container_name  = "packer-debian-salt-build"
  profile         = var.profile
  virtual_machine = var.virtual_machine

  publish_properties = {
    description = var.image_description
  }
}

build {
  sources = ["source.incus.debian"]

  provisioner "shell" {
    inline = [
      "ip addr add ${var.static_ip} dev eth0",
      "ip link set eth0 up",
      "ip route add default via ${var.gateway}",
      "cp /etc/resolv.conf /etc/resolv.conf.bak || true",
      "echo 'nameserver 172.16.0.241' > /etc/resolv.conf",
      "echo 'nameserver 172.16.0.242' >> /etc/resolv.conf"
    ]
  }

  # Install Salt from official repository
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y curl gnupg",
      "mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | gpg --dearmor -o /etc/apt/keyrings/salt-archive-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.gpg] https://packages.broadcom.com/artifactory/saltproject-deb stable main' > /etc/apt/sources.list.d/salt.list",
      "apt-get update",
      "apt-get install -y salt-minion"
    ]
  }

  # Copy Salt states and pillar
  provisioner "file" {
    source      = "../salt/states/"
    destination = "/srv/salt/states/"
  }

  provisioner "file" {
    source      = "../salt/pillar/"
    destination = "/srv/salt/pillar/"
  }

  # Copy temporary masterless config for build
  provisioner "file" {
    source      = "../salt/minion.build"
    destination = "/etc/salt/minion"
  }

  # Run Salt in masterless mode
  provisioner "shell" {
    inline = [
      "salt-call --local state.apply"
    ]
  }

  # Remove minion config (will be configured at deploy time)
  provisioner "shell" {
    inline = [
      "rm -f /etc/salt/minion"
    ]
  }

  # Cleanup
  provisioner "shell" {
    inline = [
      "apt-get clean",
      "rm -rf /srv/salt /var/cache/salt /var/log/salt",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }
  provisioner "shell" {
    inline = [
      "ip route del default via ${var.gateway} || true",
      "ip addr flush dev eth0",
      "mv /etc/resolv.conf.bak /etc/resolv.conf || rm -f /etc/resolv.conf"
    ]
  }
}
