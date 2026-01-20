variable "image_name" {
  type        = string
  default     = "ubuntu-custom"
  description = "Name of the output image"
}

variable "image_description" {
  type        = string
  default     = "Custom Ubuntu image built with Packer"
  description = "Description of the output image"
}

variable "source_image" {
  type        = string
  default     = "images:ubuntu/24.04"
  description = "Source image to use (e.g., images:ubuntu/24.04, images:ubuntu/22.04)"
}

variable "install_packages" {
  type        = list(string)
  default     = ["curl", "wget", "vim"]
  description = "List of packages to install"
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
  container_name  = "packer-ubuntu-build"
  profile         = var.profile
  virtual_machine = var.virtual_machine

  publish_properties = {
    description = var.image_description
  }
}

build {
  sources = ["source.incus.ubuntu"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y ${join(" ", var.install_packages)}",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/*"
    ]
  }

  provisioner "shell" {
    scripts = [
      "../scripts/common.sh"
    ]
  }
}
