#!/bin/sh

export PACKER_CACHE_DIR=/cache/.cache
export PACKER_CONFIG_DIR=/cache/.config
export PACKER_ANSIBLE_DIR=/cache/.ansible

# Combine all the configuration paths passed as arguments.
jq -s 'reduce .[] as $item ({}; . * $item)' "$@" > config.json

echo "Combined configuration:"
cat config.json


echo "Starting Packer Build"
/usr/bin/packer build          \
    -var-file="config.json"    \
    .