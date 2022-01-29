#!/bin/sh

export PACKER_CACHE_DIR=/cache/.cache
export PACKER_CONFIG_DIR=/cache/.config
export PACKER_ANSIBLE_DIR=/cache/.ansible

/usr/bin/packer build           \
    -var-file="default.json"    \
    .