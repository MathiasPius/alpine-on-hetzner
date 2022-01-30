#!/bin/sh

export PACKER_CACHE_DIR=/cache/.cache
export PACKER_CONFIG_DIR=/cache/.config
export PACKER_ANSIBLE_DIR=/cache/.ansible

# Combine all the configuration paths passed as arguments.
jq -s 'reduce .[] as $item ({}; . * $item)' "$@" > config.json

/usr/bin/packer build          \
    -var-file="config.json"    \
    .