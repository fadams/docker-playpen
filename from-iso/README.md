# from-iso
Some instructions for creating base images manually for a couple of distros.

In general it's *almost certainly better* to pull an official image, this is very much in the realm of "trying stuff out".

Useful links for figuring out how to do this stuff.

https://docs.docker.com/engine/userguide/eng-image/baseimages/

https://groups.google.com/forum/#!topic/docker-user/TGvzjR4afzI

The key thing to be aware of is that docker import will basically take a tarball that represents the **root filesystem**. That's important to bear in mind as, in general, if you download an iso for a distro that will be something intended to boot which isn't what you need. What you need to do is find where the root filesystem is stored in the iso and unpack that.

To begin with a few tools are nevessary - 7zip allows extraction of iso images without mounting and squashfs-tools allows manipulation of the squashfs filesystem used by many distros.

On Debian/Ubuntu systems
````
sudo apt-get install -y p7zip-full p7zip-rar
sudo apt-get install -y squashfs-tools
````

On CentOS/RHEL systems
````
sudo yum install p7zip p7zip-plugins
sudo yum install squashfs-tools
````

# Make archlinux image
Extracts from squashfs filesystem image.
````
curl -O http://mirror.bytemark.co.uk/archlinux/iso/2017.02.01/arch/x86_64/airootfs.sfs

sudo unsquashfs -f -d airootfs/ airootfs.sfs
sudo tar -C airootfs -c . | docker import - arch

docker run --rm -it arch /bin/bash
````

# Make tinycore image
Extracts root filesystem from iso
````
curl -O http://tinycorelinux.net/7.x/x86/release/Core-current.iso

7z x Core-current.iso -ocore
mkdir corefs
cd corefs
zcat ../core/boot/core.gz | cpio -ivd
cd ..

sudo tar -C corefs -c . | docker import - core

docker run --rm -it core /bin/ash
````
