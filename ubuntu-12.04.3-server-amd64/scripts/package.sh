#!/bin/bash

sleep 5

done_msg()
{
  echo "=================================================="
  echo "DONE $1"
  echo "=================================================="
}

FILE_SERVER="http://192.168.1.100:8000"
VBOX_GA_VERSION="4.3.2"
VBOX_GA_FILENAME="VBoxGuestAdditions_4.3.2.iso"
CHEF_VERSION="11.8.2"
CHEF_FILENAME="chef_11.8.2-1.ubuntu.12.04_amd64.deb"

DOWNLOADS="/run/downloads"
mkdir $DOWNLOADS

apt-get update
done_msg "apt-get update"

apt-get -y upgrade
done_msg "apt-get upgrade"

apt-get -y install build-essential dkms nfs-common
done_msg "installing build-essential dkms nfs-common"

wget -O ${DOWNLOADS}/${VBOX_GA_FILENAME} ${FILE_SERVER}/${VBOX_GA_FILENAME}
mkdir -p /mnt/vboxga
mount -o loop ${DOWNLOADS}/${VBOX_GA_FILENAME} /mnt/vboxga
sh /mnt/vboxga/VBoxLinuxAdditions.run
sleep 5
umount /mnt/vboxga
sleep 5
rm -rf /mnt/vboxga
done_msg "installing virtualbox guest additions"

wget -O ${DOWNLOADS}/${CHEF_FILENAME} ${FILE_SERVER}/${CHEF_FILENAME}
dpkg -i ${DOWNLOADS}/${CHEF_FILENAME}
done_msg "installing chef-client"

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
apt-get -y clean
done_msg "cleaning up deb packages"

rm -rf /var/lib/dhcp/*
done_msg "cleaning up dhcp leases"

rm -f  /root/.bash_history
rm -f  /root/.viminfo
rm -rf /root/.cache/
rm -f  /home/vagrant/.bash_history
rm -f  /home/vagrant/.viminfo
rm -rf /home/vagrant/.cache/
rm -rf /tmp/*
rm -rf ${DOWNLOADS}
done_msg "dumping trash"

cat > /home/vagrant/.vagrant_box_meta.yml <<METAYML
packaging_date: $(date +%F)
os_version: $(lsb_release -ds)
chef_client_version: ${CHEF_VERSION}
virtualbox_guest_additions_version: ${VBOX_GA_VERSION}
METAYML
chown vagrant:vagrant /home/vagrant/.vagrant_box_meta.yml
chmod 0444 /home/vagrant/.vagrant_box_meta.yml
done_msg "saving /home/vagrant/.vagrant_box_meta.yml"

dd if=/dev/zero of=/empty bs=1M
rm -f /empty
done_msg "zeroing data on disk"

sleep 5

exit 0
