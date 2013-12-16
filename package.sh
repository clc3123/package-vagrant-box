#!/bin/bash

VBOX_VERSION="4.3.4"
VBOX_SHARED_FOLDER=$(mount | grep vboxsf | awk 'print $3')
CHEF_VERSION="11.8.2"

echo > /home/vagrant/.vagrant_box_meta.yml <<METAYML
packaging_date: $(date +%F)
os_version: $(lsb_release -ds)
chef_client_version: ${CHEF_VERSION}
virtualbox_guest_additions_version: ${VBOX_VERSION}
METAYML
chown vagrant:vagrant /home/vagrant/.vagrant_box_meta.yml
chmod 0444 /home/vagrant/.vagrant_box_meta.yml
echo "DONE saving /home/vagrant/.vagrant_box_meta.yml"

echo > /etc/apt/sources.list <<SOURCE
deb http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
SOURCE
apt-get -y update
apt-get -y dist-upgrade
echo "DONE apt-get update & dist-upgrade"

apt-get -y install build-essential vim-nox tree byobu htop nfs-common
echo "DONE installing build-essential vim-nox tree byobu htop nfs-common"

apt-get -y install dkms
mount -o loop ${VBOX_SHARED_FOLDER}/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
/mnt/VBoxLinuxAdditions.run --nox11
umount /mnt
echo "DONE installing virtualbox guest additions ${VBOX_VERSION}"

echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant
echo "DONE setting vagrant as sudoer with nopasswd privilege"

if ! grep vagrant /home/vagrant/.ssh/authorized_keys > /dev/null 2>&1
then
  mkdir -p /home/vagrant/.ssh
  chmod 0700 /home/vagrant/.ssh
  wget --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
fi
echo "DONE trusting vagrant ssh pubkey"

dpkg -i ${VBOX_SHARED_FOLDER}/chef_${CHEF_VERSION}-1.ubuntu.12.04_amd64.deb
echo "Done installing chef-client ${CHEF_VERSION}"

umount ${VBOX_SHARED_FOLDER}
rm -rf ${VBOX_SHARED_FOLDER}
echo "DONE removing virtualbox shared folder"

apt-get -y --purge autoremove
apt-get --purge clean
echo "DONE cleaning up apt things"

rm /var/lib/dhcp/*
echo "DONE cleaning up dhcp leases"

rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm /lib/udev/rules.d/75-persistent-net-generator.rules
rm -rf /dev/.udev/
echo "DONE cleaning up udev rules"

rm /root/.bash_history
rm /root/.viminfo
rm /home/vagrant/.bash_history
rm /home/vagrant/.viminfo
rm -rf /home/vagrant/.byobu
rm -rf /home/vagrant/.cache
echo "DONE removing runtime user info"

dd if=/dev/zero of=/empty bs=1M
rm -f /empty
dd if=/dev/zero of=/boot/empty bs=1M
rm -f /boot/empty
echo "DONE zeroing data on disk"

exit
