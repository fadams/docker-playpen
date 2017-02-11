
https://groups.google.com/forum/#!topic/docker-user/TGvzjR4afzI


#sudo apt-get install p7zip-full p7zip-rar #[On Debian/Ubuntu systems]
#sudo yum install p7zip p7zip-plugins      #[On CentOS/RHEL systems]
#sudo apt-get install -y squashfs-tools
#sudo apt-get install cloop-utils



# Make archlinux image
curl -O http://mirror.bytemark.co.uk/archlinux/iso/2017.02.01/arch/x86_64/airootfs.sfs
sudo unsquashfs -f -d airootfs/ airootfs.sfs
sudo tar -C airootfs -c . | docker import - arch

docker run --rm -it arch /bin/bash



# Make tinycore image
curl -O http://tinycorelinux.net/7.x/x86/release/Core-current.iso

7z x Core-current.iso -ocore
mkdir corefs
cd corefs
zcat ../core/boot/core.gz | cpio -ivd
cd ..

sudo tar -C corefs -c . | docker import - core



chmod +r usr/bin/sudo usr/sbin/visudo
tar -zcpf ../rootfs.tar.gz *
cd .. 


docker import rootfs.tar.gz core

docker run --rm -it core /bin/ash


