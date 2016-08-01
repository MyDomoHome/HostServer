#!/bin/bash
# pour installer centos 7.2 ==> Adding initcall_blacklist=clocksource_done_booting to GRUB_CMDLINE_LINUX in /etc/default/grub and then grub2-mkconfig -o /etc/grub2.cfg fix this bug (https://bugs.centos.org/view.php?id=9860)
clear
#configuration de l'utilisateur
echo "Select This server name :"
read -p 'Computer Name: ' servar
echo "Select This server domaine or worgroup :"
read -p 'Domaine/Worgroup Name: ' domvar
echo "Select your username :"
read -p 'Username: ' uservar
echo "Select your password :"
read -sp 'Password: ' passvar

echo "Select Your IP :"
read -p 'IP ADD: ' ipvar
read -p 'Mask: ' ipmaskvar
read -p 'Gateway: ' ipgatewayvar
read -p 'DNS1: ' ipdns1var
read -p 'DNS2: ' ipdns2var
#
echo  "$servar.$domvar" > /etc/hostname
echo
read -p "Do you want to add this user as a new host user? (Y)es or (N)o : " yn 
    case $yn in
        Yes|y|Y|yes ) adduser $uservar ; echo -e "$passvar\n$passvar\n" | passwd $uservar; echo $uservar "ajouté";;
        No|n|N|no ) ;;
    esac
#done
#
#
#MONTAGE des disques
newdisk=true
while $newdisk ; do
	read -p "Do you want to add Disk? (Y)es or (N)o : " ynDk
    case $ynDk in
        Yes|y|Y|yes ) fdisk -l | more
				read -p "Which partition (/dev/sdb1 ... ) ? : " partvar
				read -p "Mount directory (/mnt/HDD1 ... ) ? : " dirtvar
				mkdir -p $dirtvar
				echo '$partvar       $dirtvar                    auto    defaults        0 0' >> /etc/fstab 
				mount -a ;;
#				break;;
        No|n|N|no ) newdisk=false ; break;;
    esac
done 
#
#
#paramétrage du bridge réseau
#
#
NicName=$(dmesg | grep "NIC Link")
NicName=${NicName#*: }
NicName=${NicName% NIC*}
NicUID=$(uuidgen $NicName)
#
#
echo "TYPE=Bridge" > /etc/sysconfig/network-scripts/ifcfg-br0
echo "BOOTPROTO=none" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "DEVICE=br0" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "ONBOOT=yes" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "IPADDR=$ipvar" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "NETMASK=$ipmaskvar" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "GATEWAY=$ipgatewayvar" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "DNS1=$ipdns1var" >> /etc/sysconfig/network-scripts/ifcfg-br0
echo "DNS2=$ipdns2var" >> /etc/sysconfig/network-scripts/ifcfg-br0
#
#mv /etc/sysconfig/network-scripts/ifcfg-$NicName /etc/sysconfig/network-scripts/ifcfg-$NicName.bak
echo "HWADDR=E8:39:35:EE:1E:9B" > "/etc/sysconfig/network-scripts/ifcfg-$NicName"
echo "TYPE=Ethernet" >> "/etc/sysconfig/network-scripts/ifcfg-$NicName"
echo 'NAME="eth0"' >> "/etc/sysconfig/network-scripts/ifcfg-$NicName"
echo "UUID=$NicUID" >> "/etc/sysconfig/network-scripts/ifcfg-$NicName"
echo "ONBOOT=yes" >> "/etc/sysconfig/network-scripts/ifcfg-$NicName"
echo "BRIDGE=br0" >> "/etc/sysconfig/network-scripts/ifcfg-$NicName"
#
#desactivation de la securité selinux pour kvm
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#
#DOCKER
yum update -y
curl -fsSL https://get.docker.com/ | sh
systemctl enable docker.service
systemctl start docker.service
usermod -aG docker $uservar
yum install epel-release -y
yum install -y python-pip -y
pip install docker-compose
yum upgrade python* -y
pip install --upgrade backports.ssl_match_hostname

curl https://raw.githubusercontent.com/MyDomoHome/HostServer/master/docker-compose.yml > docker-compose.yml
docker-compose up

#
#
#
#docker load --input
#
#docker run --restart=always -d --name Samba -p 137:137 -p 139:139 -p 445:445 -v /mnt:/mnt -d mydomohome/docker-samba -n -s "public;/mnt;yes;no;yes" -w "<$domvar>"
#docker run --restart=always -d --name MySQL -p 3306:3306 -e MYSQL_ROOT_PASSWORD=$passvar -v /mnt/3TO/DockerData/MySQL/config:/etc/mysql/conf.d -v /mnt/3TO/DockerData/MySQL/Data:/var/lib/mysql mydomohome/docker-mysql
#docker run --restart=always -d --name Transmission -p 12345:12345 -p 12345:12345/udp -p 9091:9091 -e ADMIN_PASS=$passvar -v /mnt/1TO/Download:/var/lib/transmission-daemon/downloads mydomohome/docker-transmission
#docker run --restart=always -d --name SickRage -p 8081:8081 -h SickRage -v /mnt/3TO/DockerData/SickRage:/config -v /mnt/1TO/Download:/downloads -v /mnt/1TO/Multimedia/SeriesTV:/tv -v /etc/localtime:/etc/localtime:ro mydomohome/docker-sickrage
#docker run --restart=always -d --name tvheadend -p 9981:9981 -p 9982:9982 -p 5500:5500 --privileged=true -v /mnt/3TO/DockerData/tvheadend/config:/config -v /mnt/3TO/DockerData/tvheadend/recordings:/recordings -v /etc/localtime:/etc/localtime:ro mydomohome/docker-tvheadend
#docker run --restart=always -d --name=Zoneminder -p 8082:80 --privileged=true -v /mnt/3TO/DockerData/ZM/config:/config:rw -v /etc/localtime:/etc/localtime:ro mydomohome/docker-zoneminder
##docker run --restart=always -d -p 8080:8080 --name=Domoticz -v /mnt/3TO/DockerData/Domoticz/config:/config -v /etc/localtime:/etc/localtime:ro --device=<device_id> sdesbure/domoticz
#
##docker run -v /mnt/3TO/DockerData/OpenVPN:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://vpn.mydomohome.eu
##docker run -v /mnt/3TO/DockerData/OpenVPN:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
#docker run -v /mnt/3TO/DockerData/OpenVPN:/etc/openvpn -d -p 1194:1194/udp --privileged kylemanna/openvpn
##docker run -v /mnt/3TO/DockerData/OpenVPN:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full Kevin nopass
##docker run -v /mnt/3TO/DockerData/OpenVPN:/etc/openvpn --rm -it kylemanna/openvpn ovpn_getclient Kevin > /mnt/3TO/Kevin.ovpn
#
#KVM-QEMU
#yum -y install qemu-kvm libvirt bridge-utils
#sed -i 's/#LIBVIRTD_ARGS/LIBVIRTD_ARGS/g' /etc/sysconfig/libvirtd
#sed -i 's/#listen_tls/listen_tls/g' /etc/libvirt/libvirtd.conf
#sed -i 's/#listen_tcp/listen_tcp/g' /etc/libvirt/libvirtd.conf
#sed -i 's/#auth_tcp/auth_tcp/g' /etc/libvirt/libvirtd.conf
#sed -i 's/#vnc_listen/vnc_listen/g' /etc/libvirt/qemu.conf		
#
#
#SSH
sed -i 's/#PermitRootLogin yes/PermitRootLogin no\nAllowUsers '$uservar'/g' /etc/ssh/sshd_config

