#! /bin/bash

#This script mounts the storage drive at /storage
#Prerequisit: Only 2 Drives in the system, smaller SSD mounted as boot
#And a larger HDD to be used as storage (with nothing important on it)

printCyan=$'\e[1;36m'
printWhite=$'\e[0m'


storageDevName=$(lsblk -bio SIZE,KNAME,TYPE | grep disk | sort -nr | head -1 | awk '{ print $2 }')
#if [[ -z "$storageDevName" ]]; then
#	echo "Invalid Mount drive..."
#	echo "Please mount drive manually"
#	echo "Exiting..."
#	exit 1
#fi
umount /dev/"${storageDevName}"
wipefs /dev/"${storageDevName}"

echo "/dev/${storageDevName} will be Deleted Permanently!"
echo "10 Seconds to change your mind..."
sleep 10 #last chance

echo "Starting..."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/"${storageDevName}" # the sed sanitizes the comments in the input it sends to fdisk
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default end - entire disk
  w # write the partition table
  q # done
EOF
mkfs.ext4 "/dev/${storageDevName}1"
storageUUID=$(blkid "/dev/${storageDevName}1" -s UUID -o value)
echo "UUID:    ${printCyan}${storageUUID}${printWhite}"
mkdir /storage
tee -a /etc/fstab << EOF
UUID=${storageUUID} /storage ext4 defaults 1
EOF
if mount -a; then
  exit 0
else
  exit 1
fi
