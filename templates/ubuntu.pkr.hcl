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
  type        = list(string)
  default     = ["default"]
  description = "Incus profiles to use"
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
      "ip addr add ${var.static_ip} dev eth0",
      "ip link set eth0 up",
      "ip route add default via ${var.gateway}",
      "cp /etc/resolv.conf /etc/resolv.conf.bak || true",
      "echo 'nameserver 172.16.0.241' > /etc/resolv.conf",
      "echo 'nameserver 172.16.0.242' >> /etc/resolv.conf"
    ]
  }

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
  provisioner "shell" {
    inline = [
      "ip route del default via ${var.gateway} || true",
      "ip addr flush dev eth0",
      "mv /etc/resolv.conf.bak /etc/resolv.conf || rm -f /etc/resolv.conf"
    ]
  }
}
