#!/bin/bash

create_account () {
	useradd -m admin
	echo "admin:P@ssw0rd" | chpasswd
	usermod -aG wheel admin

	cp /tmp/sudoers /etc/sudoers
	chown root:root /etc/sudoers
	chmod 440 /etc/sudoers
}

setup_firewall () {
	firewall-offline-cmd --zone=public --add-service=ssh
	firewall-offline-cmd --zone=public --add-service=http
	firewall-offline-cmd --zone=public --add-service=https
	firewall-offline-cmd --runtime-to-permanent

}

install_packages () {
	echo "Update function"
	yum install epel-release vim git tcpdump curl net-tools bzip2 nginx -y
	yum update -y
}

create_todo_app_user () {
	useradd -m -r todo-app && passwd -l todo-app
	yum install nodejs npm -y
	yum install mongodb-server -y
	systemctl enable mongod && systemctl start mongod
	mkdir /home/admin/.ssh
	cp /tmp/acit_admin_id_rsa /home/admin/.ssh/authorized_keys
}

application_setup () {
	mkdir -p /home/todo-app/app
	git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
	cd /home/todo-app/app && npm install
	cp /tmp/database.js /home/todo-app/app/config/database.js
	chown -R todo-app /home/todo-app/app
}

production_setup () {
	mkdir /etc/nginx
	chmod a+rx /home/todo-app
	yum -y install nginx
	cp /tmp/nginx.conf /etc/nginx/nginx.conf
	systemctl enable nginx && systemctl start nginx
	cp /tmp/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
}

create_account
setup_firewall
install_packages
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
create_todo_app_user
application_setup
production_setup
