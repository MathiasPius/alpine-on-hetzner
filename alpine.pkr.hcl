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
variable "extlinux_modules" {}

locals {
  password = sha1(uuidv4())
  timestamp = formatdate("DD-MM-YY.hh-mm-ss", timestamp())
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
      "alpine.pius.dev/alpine-repositories" = join("-", var.alpine_repositories)
    }
  }

  provisioner "ansible" {
    playbook_file = "playbook.yml"
    extra_arguments = ["--extra-vars", "@default.json", "--extra-vars", "root_password=${bcrypt(local.password)}"]
  }

  post-processor "manifest" {
    output = "/manifests/${build.PackerRunUUID}.json"
    strip_path = true
    custom_data = merge({
      "root_password": local.password,
      "alpine.pius.dev/alpine-version": var.alpine_version,
      "alpine.pius.dev/run-id": build.PackerRunUUID
    }, zipmap(
      formatlist("alpine.pius.dev/%s-version", keys(var.packages)),
      values(var.packages)
    ))
  }
}