#!/bin/bash
  
  #Search for config files, if they don't exist, copy the default ones
  if [ ! -f /config/apache.conf ]; then
    echo "copying apache.conf"
    cp /root/apache.conf /config/apache.conf
  else
    echo "apache.conf already exists"
  fi
  
  if [ ! -f /config/zm.conf ]; then
    echo "copying zm.conf"
    cp /root/zm.conf /config/zm.conf
  else
    echo "zm.conf already exists"
  fi
  
  # Copy mysql database if it doesn't exit
  if [ ! -d /config/mysql/mysql ]; then
    echo "moving mysql to config folder"
    rm -r /config/mysql
    cp -p -R /var/lib/mysql /config/
  else
    echo "using existing mysql database"
  fi
  
  # Copy data folder if it doesn't exist
  if [ ! -d /config/data ]; then
    echo "moving data folder to config folder"
    mkdir /config/data
    cp -R -p /usr/share/zoneminder /config/data/
    rm /config/data/zoneminder/images
    rm /config/data/zoneminder/events
    rm /config/data/zoneminder/temp
    mkdir /config/data/zoneminder/images
    mkdir /config/data/zoneminder/events
    mkdir /config/data/zoneminder/temp
  else
    echo "using existing data directory"
  fi
  
  if [ ! -d /config/perl5 ]; then
    echo "moving perl data folder to config folder"
    mkdir /config/perl5
    cp -R -p /usr/share/perl5/ZoneMinder /config/perl5/
  else
    echo "using existing perl data directory"
  fi

  
  echo "creating symbolink links"
  rm -r /usr/share/zoneminder
  rm -r /var/lib/mysql
  rm -r /etc/zm
  rm -r /usr/share/perl5/ZoneMinder
  ln -s /config/data/zoneminder /usr/share/zoneminder
  ln -s /config/mysql /var/lib/mysql
  ln -s /config /etc/zm
  ln -s /config/perl5/ZoneMinder /usr/share/perl5/ZoneMinder
  chown -R mysql:mysql /var/lib/mysql
  chmod -R go+rw /config
  
  #Get docker env timezone and set system timezone
  echo "setting the correct local time"
  echo $TZ > /etc/timezone
  export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
  dpkg-reconfigure tzdata
  
  #fix memory issue
  echo "increasing shared memory"
  umount /dev/shm
  mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${MEM:-4096M} tmpfs /dev/shm
  
  echo "starting services"
  service mysql start
  service apache2 start
  service zoneminder start
