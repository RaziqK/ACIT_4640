#!/bin/bash

NET_NAME="net_4640"
VM_NAME="VM_ACIT4640"
PXE_NAME="PXE_4640"

clean_all () {
	vbmg natnetwork remove --netname "$NET_NAME"
	vbmg unregistervm "$VM_NAME" --delete
}

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

create_network () {
	vbmg natnetwork add --netname "$NET_NAME" \
		--network 192.168.250.0/24 \
		--dhcp off \
		--enable \
		--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
		--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
		--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
		--port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
}

create_vm () {
	vbmg createvm --name "$VM_NAME" --ostype "RedHat_64" --register
	vbmg modifyvm "$VM_NAME" --memory 2048 --nic1 natnetwork \
		--cableconnected1 on \
		--nat-network1 "$NET_NAME" \
		--audio none

	SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
	VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
	VM_DIR=$(dirname "$VBOX_FILE")
	
	vbmg createmedium disk --filename "$VM_DIR"/"$VM_NAME".vdi \
		--format VDI \
		--size 10000

	vbmg storagectl "$VM_NAME" --name "Controller1" --add sata \
		--bootable on

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--port 0 --device 0 \
		--type hdd \
		--medium "$VM_DIR"/"$VM_NAME".vdi

	vbmg storageattach "$VM_NAME" --storagectl "Controller1" \
		--type dvddrive --medium emptydrive \
		--port 1 --device 0
	
	vbmg modifyvm "$VM_NAME" \
	--boot1 disk \
	--boot2 net

}

start_pxe () {
	# Add Pxe to natnetwork
	vbmg modifyvm "$PXE_NAME" --nic1 natnetwork
    vbmg startvm "$PXE_NAME"
    while /bin/true; do
        ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else    
                echo "PXE Started!"
                break
        fi
    done

	#Copy files into pxe server from ubuntu 
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chown admin /var/www/lighttpd
	scp -i ~/.ssh/acit_admin_id_rsa -P 50222 -r vm_setup admin@localhost:/var/www/lighttpd
	scp -i ~/.ssh/acit_admin_id_rsa -P 50222 ks.cfg admin@localhost:/var/www/lighttpd
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chown -R lighttpd:wheel /var/www/lighttpd
	ssh -i ~/.ssh/acit_admin_id_rsa -p 50222 admin@localhost sudo chown -R admin:admin /var/www/lighttpd/vm_setup
	#Kickstart file
	#Copy files to /var/www/lighttpd/
	#app_setup
	#app_setup config files
	

}

start_vm () {
	vbmg startvm "$VM_NAME"
}
	
	


clean_all
create_network
create_vm
start_pxe
start_vm