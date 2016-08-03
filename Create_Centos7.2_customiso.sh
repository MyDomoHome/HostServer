# This script create a Centos Minimal Unattended ISO   source : https://gist.github.com/skiane/15ac727c6ac32ea5a1ac

# This method is based on excellent article http://pyxlmap.net/technology/software/linux/custom-centos-iso
# 
# This script has be tested with CentOS 7.2 (on the orign server) to install CentOS 7.2 (on the target server)
# TODO:
# * test package update to reduce the update task on the target system. The following command downloads all updates :
#   (cd $CENTOS_CUSTOM_PATH/Packages ; yumdownloader $(for i in *; { echo ${i%%-[0-9]*}; } ) )

# Some global settings :
CENTOS_SOURCE_ISO_URL=http://mirror.in2p3.fr/linux/CentOS/7/isos/x86_64/CentOS-7-x86_64-Minimal-1511.iso
CENTOS_CUSTOM_PATH=/data/build
ISO=/data/centos7.iso
ISO_MOUNTPOINT=/mnt

function cleanup()
{
	umount $ISO_MOUNTPOINT
}

cd
test -f "$(basename $CENTOS_SOURCE_ISO_URL)" || curl -O $CENTOS_SOURCE_ISO_URL

yum -y install rsync yum-utils createrepo genisoimage isomd5sum

mount -o loop,ro ~/"$(basename $CENTOS_SOURCE_ISO_URL)" $ISO_MOUNTPOINT

mkdir -p $CENTOS_CUSTOM_PATH
cd $CENTOS_CUSTOM_PATH || { echo "Cannot cd into build directory" ; exit 1 ; }
rm -rf repodata/*
rsync --exclude=TRANS.TBL -av $ISO_MOUNTPOINT/ .

# Step 2 : add additional RPM in repository

cd $CENTOS_CUSTOM_PATH/Packages
yumdownloader wget 
   (cd $CENTOS_CUSTOM_PATH/Packages ; yumdownloader $(for i in *; { echo ${i%%-[0-9]*}; } ) )

# Step 3

cd $CENTOS_CUSTOM_PATH/repodata
mv ./*minimal-x86_64-comps.xml comps.xml && {
ls | grep -v comps.xml | xargs rm -rf
}

# Step 5

cd $CENTOS_CUSTOM_PATH
discinfo=$(head -1 .discinfo)
#createrepo -u "media://$discinfo" -g repodata/comps.xml $CENTOS_CUSTOM_PATH || { cleanup ; exit 1 ; }
createrepo -g repodata/comps.xml $CENTOS_CUSTOM_PATH || { cleanup ; exit 1 ; }

# Step 6

# Get Keyboard and Timezone for current host
read -r _ _ ZONE _ <<< "$(timedatectl | grep -i 'time zone' | egrep '\w/\w' )"
read -r _ _ LAYOUT <<< "$(localectl |grep -i layout )"


cat > $CENTOS_CUSTOM_PATH/ks.cfg << KSEOF
# Tell anaconda we're doing a fresh install and not an upgrade
install
url --url=http://mirror.centos.org/centos/7.2.1511/os/x86_64/

sshpw --username=root toor --plaintext

text
reboot --eject
# Use the cdrom for the package install
cdrom
lang fr_FR.UTF-8
#keyboard $LAYOUT XXX FIXME
keyboard --vckeymap=fr --xlayouts=fr

skipx
# You'll need a DHCP server on the network for the new install to be reachable via SSH
network --bootproto dhcp --onboot=yes
# Set the root password below !! Remember to change this once the install has completed !!
rootpw --plaintext toor
# Enable iptables, but allow SSH from anywhere
firewall --service=ssh
authconfig --enableshadow --passalgo=sha512
selinux --enforcing
#timezone --utc $ZONE
timezone --utc Europe/Paris
logging --level=debug
# Storage partitioning and formatting is below. We use LVM here.
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel
# Defines the repo we created
repo --name="CentOS7" --baseurl=file:///mnt/source --cost=100

# The below line installs the bare minimum WITH docs. If you don't want the docs, coment it out and uncomment the line below it.
%packages
@^minimal
@core
kexec-tools

%end

#######################################################################################

# Copy needed files to /root/postinstall
%post --nochroot
#!/bin/sh

set -x -v
exec 1>/mnt/sysimage/root/kickstart-stage1.log 2>&1

echo "==> copying files from internet..."
cd /mnt/sysimage/root
wget https://raw.githubusercontent.com/MyDomoHome/HostServer/master/install.sh 
chmod +x install.sh

%end

%post
#!/bin/sh

set -x -v
exec 1>/root/kickstart-stage2.log 2>&1

cd /root/
cp /mnt/sysimage/root/install.sh /root/install.sh

%end

KSEOF

# Inside the isolinux directory is a file named “isolinux.cfg”. Edit it and add the statement shown below.

sed -i -e '
s,timeout 600,timeout 60,
s,append initrd=initrd.img.*$,append initrd=initrd.img inst.sshd inst.stage2=hd:LABEL=CentOS7 ks=cdrom:/ks.cfg net.ifnames=0 biosdevname=0 initcall_blacklist=clocksource_done_booting,' $CENTOS_CUSTOM_PATH/isolinux/isolinux.cfg 


cd $CENTOS_CUSTOM_PATH

mkisofs -r -R -J -T -v -no-emul-boot \
-boot-load-size 4 \
-boot-info-table \
-V "CentOS7" \
-p "MyDomoHome" \
-A "CentOS7" \
-b isolinux/isolinux.bin \
-c isolinux/boot.cat \
-x "lost+found" \
--joliet-long \
-o $ISO .


implantisomd5 $ISO

cleanup