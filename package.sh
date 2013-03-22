#!/bin/bash

date +%F > /home/vagrant/.vagrant_box_build_date
chown vagrant:vagrant /home/vagrant/.vagrant_box_build_date
chmod 0444 /home/vagrant/.vagrant_box_build_date

echo "deb http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ precise-backports main restricted universe multiverse\ndeb-src http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse\ndeb-src http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse\ndeb-src http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse\ndeb-src http://mirrors.163.com/ubuntu/ precise-backports main restricted universe multiverse" > /etc/apt/sources.list
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install vim tree

VBOX_VERSION="4.2.10"
apt-get -y install dkms
wget -P /tmp http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop /tmp/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run --nox11
umount /mnt
rm /tmp/VBoxGuestAdditions_$VBOX_VERSION.iso

echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

apt-get -y install nfs-common

mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
wget --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

curl -L https://www.opscode.com/chef/install.sh | bash

apt-get -y --purge autoremove
apt-get clean

dd if=/dev/zero of=/empty bs=1M
rm -f /empty

dd if=/dev/zero of=/boot/empty bs=1M
rm -f /boot/empty

echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

exit
