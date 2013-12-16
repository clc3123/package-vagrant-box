# 打包vagrant precise64 devbox

参考资料 <http://pyfunc.blogspot.co.uk/2011/11/creating-base-box-from-scratch-for.html>

## 1.新建虚拟机

类型选择ubuntu 64bit，512M内存，vmdk磁盘格式，动态分配最大18G空间

虚拟机建立好之后，在安装系统前，通过virtualbox界面设置下虚拟机：

+   General -> Advanced

    -   关闭共享剪贴板和拖拽

+   System -> Motherboard 

    -   内存设为512M，今后要改可通过vagrantfile设置

    -   启动顺序，光驱排到第一位，硬盘第二位（光驱加载iso安装系统，之后再设置仅启动硬盘）

    -   Chipset选择PIIX3就可以了

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

安装成功后会自动重启一下，然后我们先关机，到虚拟机设置里的 `System -> Motherboard` 设置仅硬盘启动；另外在 `storage` 下，可以把光驱（及其控制器）删除，用不到了。

因为这时候VM的系统是纯净的，我们可以让Virtualbox克隆一份VM，然后在克隆出的这份VM上进行后续操作（注意克隆时勾选重新生成网卡mac）

## 3. 执行package.sh

先设置一个共享文件目录，务必勾选上read-only和auto-mount，把VBoxGuestAdditions和Chef等需要翻墙下载的大文件放进去。

然后启动系统后，执行：

    $ sudo su -
    $ curl package.sh.bitbucketurl | bash

脚本主要做一些vagrant打包前的设置，下面是一些要点的说明：

1.  为vagrant用户设置sudo免输密码

2.  将vagrant源码中的公钥加入vagrant用户的ssh受信任公钥列表

3.  启动克隆出的VM，会发现不能上网，ping不通外网。

    查看 `/etc/udev/rules.d/70-persistent-net.rules` ，原来我们唯一启用的eth0已被使用旧mac地址的网卡占用，而使用新mac地址的网卡依顺序只能绑定到eth1，因此无法上网。

    按这篇文章进行修改

    +   <http://splatoperator.com/2012/04/clone-ubuntu-vms-in-virtualbox/>
    +   <http://splatoperator.com/2012/11/prevent-virtual-machines-from-saving-network-interface-udev-rules/>

4.  在此查看chef安装方法 <http://www.opscode.com/chef/install/>

        $ curl -L https://www.opscode.com/chef/install.sh | sudo bash

    由于chef安装包下载要翻墙，所以推荐下载好了之后，再用dpkg安装。

5.  安装VirtualboxGuestAdditions <http://www.virtualbox.org/manual/ch04.html>

        $ sudo mount -o loop VBoxGuestAdditions_4.2.10.iso /mnt

6.  安装nfs-common，vagrant在osx、linux下通过nfs来共享目录

7.  将磁盘可写入部分完全清零，稍后打包box时virtualbox压缩磁盘可获得更小的镜像：

        $ dd if=/dev/zero of=/empty bs=1M
        $ rm -f /empty

    About zeroing data <http://support.apple.com/kb/HT1820>

    The information on your hard disk is written in just zeros and ones, known as binary. A special type of file on the disk, called a directory, indicates which groupings of binary digits constitute files. If you erase a disk by doing a quick initialization, the disk's directory is emptied. This is analogous to removing the table of contents from a book but leaving all the other pages intact. Since the system can no longer identify the files in the absence of this table of contents, it ignores them, overwriting them on an ongoing basis as if they were not there. This means that any file on that disk remains in a potentially recoverable state until you fill the disk with new data. You may notice that the Finder references "available" space, not "empty" space. This can help to remind you that a disk is only truly empty when you deliberately make it that way. The "Zero all data" option is one way to do that. Zeroing data takes the erasure process to the next level by converting all binary in the empty portion of the disk to zeros, a state that might be described as digitally blank. This significantly decreases the chance that anyone who obtains your hard drive after it has been initialized will be able to recover your files.

接下来关机，去设置中，将共享目录删除。
