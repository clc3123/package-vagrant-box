从头打包vagrant box，以precise64为例
====================================

参考资料：http://pyfunc.blogspot.co.uk/2011/11/creating-base-box-from-scratch-for.html

1.新建虚拟机
------------

类型选择ubuntu 64bit，512M内存，vmdk磁盘格式，动态分配最大18G空间
虚拟机建立好之后，在安装系统前，通过virtualbox界面设置下虚拟机：

+   General -> Advanced
    -   关闭共享剪贴板和拖拽
+   System -> Motherboard 
    -   启动顺序将光驱排到第一位，硬盘第二位（因为要加载iso安装系统，系统安装之后再对调回来）
    -   开启IO APIC和UTC时钟
+   System -> Processor
    -   选择双核
    -   开启CPU的PAE/NX
+   Storage
    -   SATA和IDE都开启use host I/O cache
    -   光驱选择加载ubuntu镜像，等下安装
+   Audio 关闭
+   Networks 第一块网卡
    -   开启NAT
    -   (可选)Port Forwarding: SSH TCP host 2222 -> guest 22

2.安装系统
----------

Virtualbox界面双击虚拟机开始安装
选择LVM方式自动分区
默认帐密：vagrant:vagrant
hostname使用precise64devbox

安装成功后会自动重启一下，然后我们先关机，
到虚拟机设置里的System -> Motherboard设置硬盘优先启动
然后到Storage下，让光驱加载VirtualboxGuestAdditions的镜像

因为这时候VM的系统是纯净的，我们可以让Virtualbox克隆一份VM，
然后在克隆出的这份VM上进行后续操作（注意克隆时勾选重新生成网卡mac）

再次启动VM，会不能上网，ping不通外网，
因为在/etc/udev/rules.d/70-persistent-net.rules中会将VM原先的网卡mac绑定到eth0，
而新的网卡mac依顺序只能绑定到eth1，而ifconfig中显示只有eth0是启用的
按这篇文章进行修改
http://splatoperator.com/2012/04/clone-ubuntu-vms-in-virtualbox/

3.设置vagrant账户
-----------------

需要先以vagrant用户登录

1.  在/etc/sudoers.d/下建立vagrant文件，加入：
        vagrant ALL=(ALL) NOPASSWD:ALL
    这样sudo就不用输入密码了

2.  把vagrant_insecure_public_key加入~/.ssh/authorized_keys
        $ mkdir -p ~/.ssh
        $ cd ~/.ssh
        $ wget https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
        $ mv vagrant.pub authorized_keys
        $ chmod 644 authorized_keys
    这样vagrant帐号就可以免密钥登录了

4.设置网易的更新源
------------------

    $ sudo apt-get update
    $ sudo apt-get dist-upgrade

5.安装chef
----------

在此查看安装方法 http://www.opscode.com/chef/install/
    $ curl -L https://www.opscode.com/chef/install.sh | sudo bash

6.安装VirtualboxGuestAdditions
------------------------------

安装依赖并挂载光驱：
    $ sudo apt-get install dkms build-essential linux-headers-`uname -r`
    $ sudo mount /dev/sr0 /mnt
如果之前忘记往光驱加载镜像，其实也可以通过网上下载iso后，直接挂载：
    $ wget -c http://download.virtualbox.org/virtualbox/4.2.10/VBoxGuestAdditions_4.2.10.iso
    $ sudo mount -o loop VBoxGuestAdditions_4.2.10.iso /mnt
执行安装：
    $ cd /mnt
    $ sudo ./VBoxLinuxAdditions.run --nox11
    $ sudo reboot

7.其它
------

将磁盘可写入部分完全清零，稍后打包box时virtualbox压缩磁盘可获得更小的镜像：
    $ dd if=/dev/zero of=/empty bs=1M
    $ rm -f /empty

http://support.apple.com/kb/HT1820
About zeroing data

The information on your hard disk is written in just zeros and ones, known as binary. A special type of file on the disk, called a directory, indicates which groupings of binary digits constitute files. If you erase a disk by doing a quick initialization, the disk's directory is emptied. This is analogous to removing the table of contents from a book but leaving all the other pages intact. Since the system can no longer identify the files in the absence of this table of contents, it ignores them, overwriting them on an ongoing basis as if they were not there. This means that any file on that disk remains in a potentially recoverable state until you fill the disk with new data. You may notice that the Finder references "available" space, not "empty" space. This can help to remind you that a disk is only truly empty when you deliberately make it that way. The "Zero all data" option is one way to do that. Zeroing data takes the erasure process to the next level by converting all binary in the empty portion of the disk to zeros, a state that might be described as digitally blank. This significantly decreases the chance that anyone who obtains your hard drive after it has been initialized will be able to recover your files.

然后可以去Storage下，把光驱对应的那个IDE控制器删除，因为用不到了
貌似也可以把port forwarding去掉，因为到时vagrant打包box会清除已有的端口转发并重新设置
