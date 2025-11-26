# Packer Vagrant base box example

A minimal example to create and test a Vagrant base box for VirtualBox based on Ubuntu server 24.04.3 LTS with cloud-init.

## Usage

1. Install packer and vagrant from hashicorp directly
2. Run `packer build ubuntu-24.04.pkr.hcl"
3. Wait about 20 minutes
4. go into the `test` directory and run `test-vm.sh`

You can clean up the vm that is created with `vagrant destroy`
