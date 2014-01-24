#!/bin/bash

sleep 10

done_msg()
{
  echo "=================================================="
  echo "DONE $1"
  echo "=================================================="
}

KERNEL_VERSION="3.8.0.35.35"

FILE_SERVER="http://192.168.1.100:8000"
VBOX_GA_VERSION="4.3.2"
VBOX_GA_FILENAME="VBoxGuestAdditions_4.3.2.iso"
CHEF_VERSION="11.8.2"
CHEF_FILENAME="chef_11.8.2-1.ubuntu.12.04_amd64.deb"
DOWNLOADS="/run/downloads"

cat > /etc/apt/preferences.d/kernel <<PIN
Package: linux-generic-lts-raring linux-headers-generic-lts-raring linux-image-generic-lts-raring
Pin: version ${KERNEL_VERSION}
Pin-Priority: 1000
PIN
done_msg "pinning kernel version"

cat > /etc/apt/sources.list <<SOURCE
deb http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ precise-security main restricted universe multiverse
SOURCE
apt-get update
done_msg "apt-get update"

apt-get -y dist-upgrade
done_msg "apt-get dist-upgrade"

apt-get -y purge linux-headers-3.8.0-29 linux-headers-3.8.0-29-generic linux-image-3.8.0-29-generic
done_msg "purging old kernel"

apt-get -y install build-essential dkms nfs-common
done_msg "installing build-essential dkms nfs-common"

mkdir $DOWNLOADS
done_msg "creating downloads directory"

wget -O ${DOWNLOADS}/${VBOX_GA_FILENAME} ${FILE_SERVER}/${VBOX_GA_FILENAME}
mkdir -p /mnt/vboxga
mount -o loop ${DOWNLOADS}/${VBOX_GA_FILENAME} /mnt/vboxga
sh /mnt/vboxga/VBoxLinuxAdditions.run
sleep 10
umount /mnt/vboxga
sleep 10
rm -rf /mnt/vboxga
done_msg "installing virtualbox guest additions"

wget -O ${DOWNLOADS}/${CHEF_FILENAME} ${FILE_SERVER}/${CHEF_FILENAME}
dpkg -i ${DOWNLOADS}/${CHEF_FILENAME}
done_msg "installing chef-client"

rm -rf ${DOWNLOADS}
done_msg "removing downloads directory"

echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant
done_msg "setting vagrant as nopassword sudoer"

mkdir /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
wget --no-check-certificate -O /home/vagrant/.ssh/authorized_keys 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
done_msg "trusting vagrant ssh pubkey"

sed -i -e '/^# ignore KVM virtual interfaces$/i\# ignore VirtualBox virtual interfaces\nENV{MATCHADDR}=="08:00:27:*", GOTO="persistent_net_generator_end"' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /etc/udev/rules.d/70-persistent-cd.rules
rm -rf /dev/.udev/
done_msg "modifying & cleaning udev rules"

apt-get -y --purge autoremove
apt-get -y --purge clean
done_msg "cleaning up deb packages"

rm -f /var/lib/dhcp/*
done_msg "cleaning up dhcp leases"

rm -f  /root/.bash_history
rm -f  /root/.viminfo
rm -rf /root/.cache/
rm -f  /home/vagrant/.bash_history
rm -f  /home/vagrant/.viminfo
rm -rf /home/vagrant/.cache/
rm -rf /tmp/*
done_msg "removing trash"

cat > /home/vagrant/.vagrant_box_meta.yml <<METAYML
packaging_date: $(date +%F)
os_version: $(lsb_release -ds)
kernel_version; ${KERNEL_VERSION}
chef_client_version: ${CHEF_VERSION}
virtualbox_guest_additions_version: ${VBOX_GA_VERSION}
METAYML
chown vagrant:vagrant /home/vagrant/.vagrant_box_meta.yml
chmod 0444 /home/vagrant/.vagrant_box_meta.yml
done_msg "saving /home/vagrant/.vagrant_box_meta.yml"

dd if=/dev/zero of=/empty bs=1M
rm -f /empty
done_msg "zeroing data on disk"

exit 0
