#!/usr/bin/env bash
set -eux -o pipefail
vagrant box add ../ubuntu-24.04-virtualbox.box --name ubuntu-24.04-virtualbox-packer-test --force
vagrant up --provider virtualbox


