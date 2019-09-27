#!/bin/bash

ENKEY='$6$SUoKVSv0g2g.jsmr$dEcgGetnRx19x70NM3A4b2vqyBLq12kGX4Y77sWf/HcnlSr0CV.EOxgkPrbpNDaG9VYCb.SwVREAQPKoQEWYe1'

echo "Configuring User";
adduser admin;
echo "admin:password" | chpasswd;
echo 'admin:' | chpasswd -e;
usermod -aG wheel admin;
useradd -m -r todo-app && passwd -l todo-app

echo "Installing packages";
yum -y install epel-release vim git tcpdump curl net-tools bzip2
yum -y update

echo "SSH Key Authorization";
mkdir /home/admin/.ssh/
curl "https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub" >> /home/admin/.ssh/authorized_keys.pop
sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers


echo "Firewall Setup";
firewall-cmd --zone=public --list-all
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --runtime-to-permanent

echo "Disable SELinux";
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

echo "install node and mongodb";
yum -y install nodejs npm
yum -y install mongodb-server
echo "starting mongod";
systemctl enable mongod && systemctl start mongod

su - todo-app -c  "mkdir ~/app"
cd /home/todo-app/app
su todo-app -c "git clone https://github.com/timoguic/ACIT4640-todo-app.git"
su todo-app -c "npm install"

cp -f database.js config/database.js;
curl -s localhost:8080/api/todos | jq

echo "install nginx";
yum -y install nginx
echo "start nginx";

systemctl enable nginx;
systemctl start nginx;

cp -f todoapp.service /lib/systemd/system;
systemctl daemon-reload

echo "DONE!"