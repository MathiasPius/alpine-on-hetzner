# alpine-hetzner



# Usage
Create an alpine image with the [default](/default.json) configuration:
```bash
$ docker run -it --rm -e "HCLOUD_TOKEN=<YourTokenHere>" alpine-on-hetzner:latest
```

There are a number of optional docker mounts you can use:
* `/manifests` contains the output manifests from the run.
* `/cache` used for caching the `apk-tools` package locally between runs.
* `/configs` used for providing [custom configuration](#configuration) to builds, such as extra packages.

# Configuration
Any command arguments passed to the docker run invocation will be treated as paths to configuration files to merge into a single combined configuration file which is then fed into the packer build.

The merge is a "deep merge", meaning you can only *add to* or *change* the configuration file not remove from it. If you want to remove a package from the default.json configuration for example you will have to create a copy of it without the package in question and use that as the basis for your build.

## Adding a custom package to your image
In order to add a custom package, like `nginx` for example, you can create the following config file `configs/nginx.json` in your local directory:
```json
{ "packages": { "nginx": "" } }
```
<sup><sub>`packages` is a map where the keys are package names and the value is the version selector. The map is passed directly to an `apk add` command, see [this link](https://wiki.alpinelinux.org/wiki/Package_management#Holding_a_specific_package_back) for version-pinning syntax.</sub></sup>

When the container is then run like so:
```shell
docker run -it --rm                     \
    -e "HCLOUD_TOKEN"                   \
    -v "$(pwd)/configs:/configs"        \
    alpine-on-hetzner:latest default.json /configs/nginx.json
```
The package will be appended to `packages` array, like os:
```json
{
  (...)
  "packages": {
    "openssh": "=8.8_p1-r1",
    "syslinux": "=6.04_pre1-r9",
    "linux-virt": "=5.15.16-r0",
    "cloud-init": "@community=21.4-r0",
    "nginx": ""
  }
}
```


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