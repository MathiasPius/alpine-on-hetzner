# alpine-hetzner
Tool for building cloud-init ready Alpine snapshots on Hetzner Cloud.

You can either run it as a docker container or as a regular packer build (see [entrypoint.sh](/entrypoint.sh) for hints on how), but this latter method is not officially supported.

# Examples

## Create an alpine image with the [default](/default.json) configuration
Running this will create an `alpine` snapshot within your Hetzner Cloud project, ready to use for creating new servers. See the [launching a server](#launching-a-server) section for how to test it!
```shell
docker run -it --rm -e "HCLOUD_TOKEN=<YourTokenHere>" alpine-on-hetzner:latest
```

## Default image, with `doas` installed, and `template.local` as default hostname
Configuration values can be overwritten by creating new configuration file with just the changes you want, and supplying the path as an argument when running it. See [Custom Configuration](#custom-configuration) for technical details on how the values are merged.
```shell
mkdir -p configs
echo '{ 
  "packages": { "doas": "=6.8.1-r7" },
  "hostname": "template.local"
}' > configs/my-override.json


export HCLOUD_TOKEN=myHetznerCloudToken
docker run -it --rm                     \
    -e "HCLOUD_TOKEN"                   \
    -v "$(pwd)/configs:/configs"        \
    alpine-on-hetzner:latest default.json /configs/my-override.json
```

There are a number of optional docker mounts you can use:
* `/manifests` contains the output manifests from the run.
* `/cache` used for caching the `apk-tools` package locally between runs.
* `/configs` used for providing [custom configuration files](#custom-configuration) to builds.

# Custom Configuration
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
The package will be appended to `packages` array, like so, immediately before the packer build runs:
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
[alpine.pkr.hcl](/alpine.pkr.hcl) contains the packer build configuration which uses the playbook above via the [Ansible Provisioner](https://www.packer.io/plugins/provisioners/ansible/ansible)

# How it works
The docker image comes with packer, ansible and jq pre-installed (check labels for versions), and builds the [alpine.pkr.hcl](/alpine.pkr.hcl) build against your Hetzner Cloud project using your provided API key. The Packer build will boot a server in rescue mode, then format and install Alpine Linux onto the primary drive of the server. Once done, the server will be saved as a snapshot and shut down. You can then create Alpine Linux servers using the finished snapshot.

# Launching a server
Servers built from the snapshot won't be immediately accessible because the root user is locked by default, but can be configured using the Hetzner interface. Use the following cloud-init config to enable root access and select an ssh key when creating the server to allow login:
```yaml
#cloud-config
disable_root: false
users:
- name: root
  lock-passwd: false
```

# Development
I have a number of ideas I would like to explore:

* Re-using or expanding this tool to provision Alpine Linux on dedicated servers, but maintaining the same configuration interface. I've previously done a less refined version fo this project for dedicated servers [here](https://github.com/MathiasPius/hetzner-zfs-host)
* Splitting up configuration files so you can mix-and-match a little more. Would also allow optional *hardened* configurations for example which you could opt into for stricter security.
* Creating configuration files for older versions of Alpine Linux.
* Pipelining alpine-on-hetzner docker image builds and perhaps more importantly testing that they work.
* Add more customization abilities to the configuration file. Being able to enable openrc services with a simple array for example would be simple to implement and very useful.