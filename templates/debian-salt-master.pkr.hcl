variable "image_name" {
  type        = string
  default     = "debian-salt-master"
  description = "Name of the output image"
}

variable "image_description" {
  type        = string
  default     = "Debian 12 image with Salt Master installed"
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

source "incus" "debian" {
  image           = var.source_image
  output_image    = var.image_name
  container_name  = "packer-debian-salt-master-build"
  profile         = var.profile
  virtual_machine = var.virtual_machine

  publish_properties = {
    description = var.image_description
  }
}

build {
  sources = ["source.incus.debian"]

  # Install Salt Master from official repository
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y curl gnupg",
      "mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | gpg --dearmor -o /etc/apt/keyrings/salt-archive-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/salt-archive-keyring.gpg] https://packages.broadcom.com/artifactory/saltproject-deb stable main' > /etc/apt/sources.list.d/salt.list",
      "apt-get update",
      "apt-get install -y salt-master salt-minion"
    ]
  }

  # Configure Salt Master
  provisioner "shell" {
    inline = [
      "mkdir -p /srv/salt /srv/pillar",
      "systemctl enable salt-master",
      "systemctl enable salt-minion"
    ]
  }

  # Copy Salt configuration
  provisioner "file" {
    source      = "../salt/"
    destination = "/srv/salt/"
  }

  provisioner "file" {
    source      = "../salt/minion"
    destination = "/etc/salt/minion"
  }

  # Run Salt in masterless mode
  provisioner "shell" {
    inline = [
      "salt-call --local state.apply"
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
}
