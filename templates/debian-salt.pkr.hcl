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
}
