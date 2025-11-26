#!/bin/bash
# Provisioning script for the VM
set -ex

# Wait for cloud-init to complete
cloud-init status --wait

# Install required packages for Guest Additions
apt-get update
apt-get install -y build-essential dkms "linux-headers-$(uname -r)"

# Install VirtualBox Guest Additions
mkdir -p /tmp/vbox
mount -o loop /home/vagrant/VBoxGuestAdditions.iso /tmp/vbox
/tmp/vbox/VBoxLinuxAdditions.run --nox11 || true
umount /tmp/vbox
rm -f /home/vagrant/VBoxGuestAdditions.iso
rmdir /tmp/vbox

# Install Vagrant insecure public key
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget -q https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Optimize SSH for faster connections
cat >> /etc/ssh/sshd_config <<EOF
UseDNS no
GSSAPIAuthentication no
EOF

# Remove development packages (no longer needed after Guest Additions built)
apt-get -y purge build-essential dkms
dpkg --list | awk '{ print $2 }' | grep -- '-dev\(:[a-z0-9]\+\)\?$' | xargs -r apt-get -y purge || true

# Remove old kernels (keep current)
dpkg --list | awk '{ print $2 }' | grep 'linux-headers' | grep -v "$(uname -r)" | xargs -r apt-get -y purge || true
dpkg --list | awk '{ print $2 }' | grep 'linux-image-.*-generic' | grep -v "$(uname -r)" | xargs -r apt-get -y purge || true
dpkg --list | awk '{ print $2 }' | grep 'linux-modules-.*-generic' | grep -v "$(uname -r)" | xargs -r apt-get -y purge || true

# Remove documentation
dpkg --list | awk '{ print $2 }' | grep -- '-doc$' | xargs -r apt-get -y purge || true
rm -rf /usr/share/doc/*

# Cleanup packages
apt-get -y autoremove
apt-get -y clean
rm -rf /var/lib/apt/lists/*

# Truncate logs
find /var/log -type f -exec truncate --size=0 {} \;

# Reset machine-id for unique ID on first boot
truncate -s 0 /etc/machine-id
if [ -f /var/lib/dbus/machine-id ]; then
  truncate -s 0 /var/lib/dbus/machine-id
fi

# Clear temp files
rm -rf /tmp/* /var/tmp/*

# Force new random seed on boot
rm -f /var/lib/systemd/random-seed

# Clear shell history
rm -f /root/.bash_history /home/vagrant/.bash_history
export HISTSIZE=0

# Zero out free space to reduce box size
dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
rm -f /EMPTY
sync
