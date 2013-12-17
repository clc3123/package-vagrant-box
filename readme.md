# 打包vagrant precise64 devbox

参考资料 <http://pyfunc.blogspot.co.uk/2011/11/creating-base-box-from-scratch-for.html>

## 1.新建虚拟机

类型选择ubuntu 64bit，512M内存，vmdk磁盘格式，动态分配最大12G空间(分多少自己定)

虚拟机建立好之后，在安装系统前，通过virtualbox界面设置下虚拟机：

+   General -> Advanced

    -   关闭共享剪贴板和拖拽

+   System -> Motherboard 

    -   内存设为512M，今后要改可通过vagrantfile设置

    -   启动顺序，光驱排到第一位，硬盘第二位（光驱加载iso安装系统，之后再设置仅启动硬盘）

    -   Chipset选择PIIX3就可以了

    -   EFI不用开了

    -   开启IO APIC和UTC时钟

+   System -> Processor

    -   选择双核

    -   开启CPU的PAE/NX

+   System -> Acceleration

    硬件虚拟化两个都勾选上

+   Storage

    -   确保有一个SATA或IDE的光驱，没有的话就添加一个，并加载ubuntu镜像，等下安装

    -   为SATA或IDE Controller开启use host I/O cache

+   Audio

    关闭

+   Networks

    暂时先设置第一块网卡界面就够了，其它通过vagrant来添加

    -   开启NAT

    -   (可选)Port Forwarding: SSH TCP host 2222 -> guest 22

## 2.安装系统

Virtualbox界面双击虚拟机开始安装：

+   选择LVM方式自动分区

+   默认帐密：vagrant:vagrant

+   hostname使用precise64devbox，当然这个之后也能用vagrantfile设置

安装成功后会自动重启一下，这里要进行一个重要的设置，以保证之后克隆出的VM能够正常上网：

    $ sudo su -
    # vi /lib/udev/rules.d/75-persistent-net-generator.rules

找到 `# ignore * virtual interfaces` 这部分配置，在这部分的尾部加上：

    # ignore VirtualBox virtual interfaces
    ENV{MATCHADDR}=="08:00:27:*", GOTO="persistent_net_generator_end"

注，Virtualbox生成的MAC地址都是 `08:00:27:*` 这个结构。接下来删除已生成的udev规则：
    
    # rm -f /etc/udev/rules.d/70-persistent-net.rules

这样设置的原因可参考以下文章：

1.  <http://www.envision-systems.com.au/blog/2012/09/21/fix-eth0-network-interface-when-cloning-redhat-centos-or-scientific-virtual-machines-using-oracle-virtualbox-or-vmware/>

    However if you clone a VMWare or Oracle VirtualBox VM, you’ll notice that it kills your network interfaces throwing errors like the one listed below:

        $ ifup eth0
        Device eth0 does not seem to be present, delaying initialisation

    What’s happening here is that when you clone your VM, VirtualBox and VMWare apply a new MAC Address to your network interfaces but they don’t update the linux configuration files to mirror these changes and so the kernel firstly can’t find or start the interface that matches it’s configuration (with the old MAC Address) and it finds a new interface (the new MAC Address) that it has no configuration information for. The result is that your networking service can only start the loopback networking interface and eth0 is dead.

2.  <https://www.virtualbox.org/ticket/660>

3.  启动克隆出的VM，会发现不能上网，ping不通外网。

    查看 `/etc/udev/rules.d/70-persistent-net.rules` ，原来我们唯一启用的eth0已被使用旧mac地址的网卡占用，而使用新mac地址的网卡依顺序只能绑定到eth1，因此无法上网。

    按这篇文章进行修改

    +   <http://splatoperator.com/2012/04/clone-ubuntu-vms-in-virtualbox/>
    +   <http://splatoperator.com/2012/11/prevent-virtual-machines-from-saving-network-interface-udev-rules/>

然后我们关机，到虚拟机设置里的 `System -> Motherboard` 设置好硬盘优先启动；另外在 `storage` 下，可以把光驱（及其控制器）删除，用不到了。

因为这时候VM的系统是纯净的，我们可以让Virtualbox克隆一份VM。

保留好原先的VM作为以后定期生成vagrant box的base，然后在克隆出的这份VM上进行后续操作（注意克隆时勾选重新生成网卡mac）

## 3. 执行package.sh

先设置一个共享文件目录，务必勾选上read-only和auto-mount，把VBoxGuestAdditions和Chef等需要翻墙下载的大文件放进去。

然后启动系统后，执行：

    $ sudo su -
    $ curl package.sh.bitbucketurl | bash

脚本主要做一些vagrant打包前的设置，下面是一些要点的说明：

1.  为vagrant用户设置sudo免输密码

2.  将vagrant源码中的公钥加入vagrant用户的ssh受信任公钥列表

3.  在此查看chef安装方法 <http://www.opscode.com/chef/install/>

        $ curl -L https://www.opscode.com/chef/install.sh | sudo bash

    由于chef安装包下载要翻墙，所以推荐下载好了之后，再用dpkg安装。

4.  安装VirtualboxGuestAdditions <http://www.virtualbox.org/manual/ch04.html>

        $ sudo mount -o loop VBoxGuestAdditions_4.2.10.iso /mnt

5.  安装nfs-common，vagrant在osx、linux下通过nfs来共享目录

6.  将磁盘可写入部分完全清零，稍后打包box时virtualbox压缩磁盘可获得更小的镜像：

        $ dd if=/dev/zero of=/empty bs=1M
        $ rm -f /empty

    About zeroing data <http://support.apple.com/kb/HT1820>

    The information on your hard disk is written in just zeros and ones, known as binary. A special type of file on the disk, called a directory, indicates which groupings of binary digits constitute files. If you erase a disk by doing a quick initialization, the disk's directory is emptied. This is analogous to removing the table of contents from a book but leaving all the other pages intact. Since the system can no longer identify the files in the absence of this table of contents, it ignores them, overwriting them on an ongoing basis as if they were not there. This means that any file on that disk remains in a potentially recoverable state until you fill the disk with new data. You may notice that the Finder references "available" space, not "empty" space. This can help to remind you that a disk is only truly empty when you deliberately make it that way. The "Zero all data" option is one way to do that. Zeroing data takes the erasure process to the next level by converting all binary in the empty portion of the disk to zeros, a state that might be described as digitally blank. This significantly decreases the chance that anyone who obtains your hard drive after it has been initialized will be able to recover your files.

接下来关机，去设置中，将共享目录删除。

然后我们就可以用vagant package命令对VM进行打包操作了，完工！
