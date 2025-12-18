variable "image_name" {
  type        = string
  default     = "alpine-custom"
  description = "Name of the output image"
}

variable "image_description" {
  type        = string
  default     = "Custom Alpine image built with Packer"
  description = "Description of the output image"
}

variable "source_image" {
  type        = string
  default     = "images:alpine/3.20"
  description = "Source image to use (e.g., images:alpine/3.20, images:alpine/3.19)"
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

source "incus" "alpine" {
  image           = var.source_image
  output_image    = var.image_name
  container_name  = "packer-alpine-build"
  profile         = var.profile
  virtual_machine = var.virtual_machine

  publish_properties = {
    description = var.image_description
  }
}

build {
  sources = ["source.incus.alpine"]

  provisioner "shell" {
    inline = [
      "apk update",
      "apk upgrade",
      "apk add --no-cache ${join(" ", var.install_packages)}",
      "rm -rf /var/cache/apk/*"
    ]
  }
}
