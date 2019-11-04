#!/bin/bash



setup_firewall () {
	firewall-cmd --zone=public --add-service=ssh
	firewall-cmd --zone=public --add-service=http
	firewall-cmd --zone=public --add-service=https
	firewall-cmd --runtime-to-permanent

}

install_packages () {
	echo "Update function"
	yum update -y
}

create_todo_app_user () {
	useradd -m -r todo-app && passwd -l todo-app
	systemctl enable mongod && systemctl start mongod
}

application_setup () {
	sudo -u todo-app --mkdir /home/todo-app/app
	git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app
	npm install --prefix /home/todo-app/app
	sed -r -i 's/CHANGEME/acit4640/g' /home/todo-app/app/config/database.js
	sudo chown -R todo-app /home/todo-app/app
}

production_setup () {
	mkdir /etc/nginx
	chmod a+rx /home/todo-app
	cp -f /home/admin/nginx.conf /etc/nginx/nginx.conf
	systemctl enable nginx && systemctl start nginx
	cp -f /home/admin/todoapp.service /lib/systemd/system
	systemctl daemon-reload
	systemctl enable todoapp
	systemctl start todoapp
}

setup_firewall
install_packages
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config
create_todo_app_user
application_setup
production_setup
