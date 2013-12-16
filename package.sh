#!/bin/bash

VBOX_VERSION="4.3.4"
VBOX_SHARED_FOLDER=$(mount | grep vboxsf | awk '{print $3}')
CHEF_VERSION="11.8.2"

done_echo()
{
  echo "================================================================================"
  echo $1
  echo "================================================================================"
}

cat > /home/vagrant/.vagrant_box_meta.yml <<METAYML
packaging_date: $(date +%F)
os_version: $(lsb_release -ds)
chef_client_version: ${CHEF_VERSION}
virtualbox_guest_additions_version: ${VBOX_VERSION}
METAYML
chown vagrant:vagrant /home/vagrant/.vagrant_box_meta.yml
chmod 0444 /home/vagrant/.vagrant_box_meta.yml
done_echo "DONE saving /home/vagrant/.vagrant_box_meta.yml"

cat > /etc/apt/sources.list <<SOURCE
deb http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
SOURCE
apt-get -y update
apt-get -y dist-upgrade
done_echo "DONE apt-get update & dist-upgrade"

apt-get -y install build-essential vim-nox tree byobu htop nfs-common
done_echo "DONE installing build-essential vim-nox tree byobu htop nfs-common"

apt-get -y install dkms
if ! (which VBoxControl && VBoxControl version | grep "\b${VBOX_VERSION}r")
then
  mount -o loop ${VBOX_SHARED_FOLDER}/VBoxGuestAdditions_${VBOX_VERSION}.iso /mnt
  /mnt/VBoxLinuxAdditions.run --nox11
  umount /mnt
fi
done_echo "DONE installing virtualbox guest additions ${VBOX_VERSION}"

echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant
done_echo "DONE setting vagrant as sudoer with nopasswd privilege"

if ! grep vagrant /home/vagrant/.ssh/authorized_keys > /dev/null 2>&1
then
  mkdir -p /home/vagrant/.ssh
  chmod 0700 /home/vagrant/.ssh
  wget --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
  chmod 0600 /home/vagrant/.ssh/authorized_keys
  chown -R vagrant:vagrant /home/vagrant/.ssh
fi
done_echo "DONE trusting vagrant ssh pubkey"

if ! (which chef-client && chef-client -v | grep "\b${CHEF_VERSION}\b")
then
  dpkg -i ${VBOX_SHARED_FOLDER}/chef_${CHEF_VERSION}-1.ubuntu.12.04_amd64.deb
fi
done_echo "DONE installing chef-client ${CHEF_VERSION}"

umount ${VBOX_SHARED_FOLDER}
rm -rf ${VBOX_SHARED_FOLDER}
done_echo "DONE removing virtualbox shared folder"

apt-get -y --purge autoremove
apt-get --purge clean
done_echo "DONE cleaning up apt things"

rm -f /var/lib/dhcp/*
done_echo "DONE cleaning up dhcp leases"

if [ ! -d /etc/udev/rules.d/70-persistent-net.rules ]
then
  rm -f /etc/udev/rules.d/70-persistent-net.rules
  mkdir /etc/udev/rules.d/70-persistent-net.rules
fi
rm -f /lib/udev/rules.d/75-persistent-net-generator.rules
rm -rf /dev/.udev/
done_echo "DONE cleaning up udev rules"

rm -f /root/.bash_history
rm -f /root/.viminfo
rm -f /home/vagrant/.bash_history
rm -f /home/vagrant/.viminfo
rm -rf /home/vagrant/.byobu
rm -rf /home/vagrant/.cache
done_echo "DONE removing runtime user info"

dd if=/dev/zero of=/empty bs=1M
rm -f /empty
dd if=/dev/zero of=/boot/empty bs=1M
rm -f /boot/empty
done_echo "DONE zeroing data on disk"

exit
