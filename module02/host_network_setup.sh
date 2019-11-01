#!/bin/bash -x

vbmg () { VboxManage.exe "$@"; }
export PATH=/mnt/c/Program\ Files/Oracle/VirtualBox:$PATH
vbmg createvm --name VM_ACIT4640_Script1 --ostype RedHat_64 --register
vbmg modifyvm VM_ACIT4640_Script1 --memory 1024 --cpus 1 --nic1 natnetwork --nat-network1 net_4640 --audio none

vbmg createmedium disk --filename storage1 --size 10000 --format VDI
vbmg storagectl VM_ACIT4640_Script1 --name SATA --add sata --bootable on --portcount 2
vbmg storageattach VM_ACIT4640_Script1 --storagectl SATA --port 0 --device 0 --type hdd --medium "storage1.vdi"
vbmg storagectl VM_ACIT4640_Script1 --name IDE --add ide 
vbmg storageattach VM_ACIT4640_Script1 --storagectl IDE --device 0 --port 0 --type hdd --medium emptydrive
vbmg natnetwork add --netname net_4640 --dhcp off --ipv6 off --network 192.168.250.0/24 --enable \
--port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" \
--port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" \
--port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" \
