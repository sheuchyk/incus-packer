variable "image_name" {
  type        = string
  default     = "ubuntu-salt"
  description = "Name of the output image"
}

variable "image_description" {
  type        = string
  default     = "Ubuntu image provisioned with Salt"
  description = "Description of the output image"
}

variable "source_image" {
  type        = string
  default     = "images:ubuntu/24.04"
  description = "Source image to use (e.g., images:ubuntu/24.04, images:ubuntu/22.04)"
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

source "incus" "ubuntu" {
  image           = var.source_image
  output_image    = var.image_name
  container_name  = "packer-ubuntu-salt-build"
  profile         = var.profile
  virtual_machine = var.virtual_machine

  publish_properties = {
    description = var.image_description
  }
}

build {
  sources = ["source.incus.ubuntu"]

  # Install Salt
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y curl",
      "curl -fsSL https://bootstrap.saltproject.io -o install_salt.sh",
      "sh install_salt.sh -P",
      "rm install_salt.sh"
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

  # Cleanup Salt (optional - remove if you want Salt to remain installed)
  provisioner "shell" {
    inline = [
      "apt-get purge -y salt-minion salt-common",
      "apt-get autoremove -y",
      "apt-get clean",
      "rm -rf /srv/salt /var/cache/salt /var/log/salt",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }
}
