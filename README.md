# alpine-hetzner



# Usage
Create an alpine image with the [default](/default.json) configuration:
```bash
$ docker run -it --rm -e "HCLOUD_TOKEN=<YourTokenHere>" alpine-on-hetzner:latest
```

There are a number of optional docker mounts you can use:
* `/manifests` contains the output manifests from the run.
* `/cache` used for caching the `apk-tools` package locally between runs.
* `/configs` (WILL) used for providing custom configuration to builds, such as extra packages.

# What's in the finished snapshot?
See the [default.json](/default.json) config for a list of packages that will be installed into the snapshot if run without any arguments.

[playbook.yml](/playbook.yml) contains the entire ansible playbook used for generating the snapshot.

# How it works
The docker image comes with packer and ansible pre-installed (check labels for versions), and builds the [alpine.pkr.hcl](/alpine.pkr.hcl) build against your Hetzner Cloud project using your provided API key. The Packer build will boot a server in rescue mode, then format and install Alpine Linux onto the primary drive of the server. Once done, the server will be saved as a snapshot and shut down. You can then create Alpine Linux servers using the finished snapshot.


# Launching the server
Servers built from the snapshot won't be immediately accessible, but can be configured using the Hetzner interface. Use the following cloud-init config to enable root access and select an ssh key when creating the server to allow login:
```yaml
#cloud-config
disable_root: false
users:
- name: root
  lock-passwd: false
```