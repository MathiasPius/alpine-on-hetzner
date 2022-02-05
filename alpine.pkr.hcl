# Please see default.json for default values for these
variable "apk_tools_url" {}
variable "apk_tools_arch" {}
variable "apk_tools_version" {}
variable "apk_tools_checksum" {}

variable "alpine_version" {}
variable "alpine_mirror" {}
variable "alpine_repositories" {}

variable "boot_size" {}
variable "root_size" {}
variable "hostname" {}

variable "packages" {}
variable "services" {}
variable "nameservers" {}
variable "extlinux_modules" {}
variable "kernel_features" {}
variable "kernel_modules" {}
variable "default_kernel_opts" {}

locals {
  timestamp = formatdate("DD-MM-YY.hh-mm-ss", timestamp())
  snapshot_id = sha1(uuidv4())
}

source "hcloud" "alpine" {
  location      = "fsn1"
  server_type   = "cx11"
  image         = "ubuntu-20.04"
  rescue        = "linux64"
  ssh_username  = "root"
}

build {
  name = "alpine"

  source "source.hcloud.alpine" {
    snapshot_name = "alpine"
    snapshot_labels = {
      "alpine.pius.dev/timestamp"           = local.timestamp
      "alpine.pius.dev/alpine-version"      = var.alpine_version
      "alpine.pius.dev/snapshot-id"         = local.snapshot_id
    }
  }

  provisioner "ansible" {
    playbook_file = "playbook.yml"
    extra_arguments = ["--extra-vars", "@config.json"]
  }

  post-processor "manifest" {
    output = "/manifests/${build.PackerRunUUID}.json"
    strip_path = true
    custom_data = merge({
      "alpine.pius.dev/alpine-version": var.alpine_version,
      "alpine.pius.dev/packer-run-id":  build.PackerRunUUID,
      "alpine.pius.dev/snapshot-id":    local.snapshot_id
    }, zipmap(
      formatlist("alpine.pius.dev/%s-version", keys(var.packages)),
      values(var.packages)
    ))
  }
}