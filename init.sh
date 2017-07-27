#!/usr/bin/env bash
# Upgrade everything
sudo yum upgrade -y

#Install epel-release (Extra Packages for Enterprise Linux)
sudo yum install epel-release -y

#Install compiler tools
sudo yum install make gcc kernel-devel-`uname -r` -y

#Install NTP (Remember to change selected peers)
sudo yum install ntp -y
sudo systemctl enable ntpd
sudo systemctl start ntpd

#Set Timezone
sudo timedatectl set-timezone America/Los_Angeles

#Disable IPv6
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

#SELINUX to permissive
sudo sed -i -e 's|SELINUX=enforcing|SELINUX=permissive|g' /etc/selinux/config
sudo setenforce Permissive

echo "Init Script Complete"
