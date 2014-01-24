package-vagrant-box
===================

自动化打包vagrant box。

必须使用0.5.0以上版本的packer。

使用方法：

    $ git clone git@github.com:clc3123/package-vagrant-box.git
    $ cd package-vagrant-box/ubuntu-12.04.3-server-amd64/
    $ ./build-image.sh
    
生成的vagrant box在`package-vagrant-box/outputs/`里。

其它系统的打包配置，可以用gem `veewee-to-packer`把veewee repo中的template转换一下，然后用`$ packer fix`修正以更新配置格式。

以前手工打包box的说明在<https://github.com/clc3123/package-vagrant-box/blob/master/docs/readme.md>。
