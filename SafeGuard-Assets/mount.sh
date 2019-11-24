#! /bin/bash

#This script mounts the storage drive at /storage
#Prerequisit: Only 2 Drives in the system, smaller SSD mounted as boot
#And a larger HDD to be used as storage (with nothing important on it)

local printCyan=$'\e[1;36m'
local printWhite=$'\e[0m'


storageDevName=$(lsblk -io KNAME,TYPE,SIZE | grep disk | sed 's/G//' | awk '$3 > 900 {print $1}')
storageUUID=blkid /dev/${storageDevName}1 -s UUID -o value
if [[-z ${storageUUID} ]]; then
	echo "Invalid Mount drive..."
	echo "Please mount drive manually"
	echo "Exiting..."
	exit 1
fi
#test echo
echo "awk output:    ${printCyan}${storageDevName}${printWhite}"
echo "UUID:    ${printCyan}${storageUUID}${printWhite}"

umount /dev/${storageDevName}

echo "/dev/${storageDevName} will be Deleted Permanently!"
echo "10 Seconds to change your mind..."
sleep 10 #last chance

echo "Starting..."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/${storageDevName} && succesfulPrint "Partitioning"
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default end - entire disk
  w # write the partition table
  q # done
EOF
mkfs.ext4 /dev/${storageDevName}1 && succesfulPrint "Formatting"
mkdir /storage
mount UUID=${storageUUID} -o defaults /storage && succesfulPrint "Mounting"
exit 0



succesfulPrint(){
local printGreen=$'\e[1;32m'
local printWhite=$'\e[0m'
	echo -e "=================================================================="
	echo -e "                    $1 ....${green}Success${white}                  "
	echo -e "=================================================================="
}