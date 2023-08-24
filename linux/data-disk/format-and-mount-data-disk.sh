#!/usr/bin/env bash

MOUNT_POINT="/backup";

# Assumes data disk is attached via SCSI controller to LUN0
DATA_DISK_DEV=$(readlink -f /dev/disk/azure/scsi1/lun0);
echo "Data disk is located at device: $DATA_DISK_DEV";

# Generate a UUID for use in labeling the partition
UUID=$(uuidgen);

# Use sfdisk (the scriptable version of fdisk from util-linux) to:
# Create a GPT partition table
echo "label: gpt" | sudo sfdisk $DATA_DISK_DEV;
# Create a single partition that takes up the entire disk labeled with the UUID
echo "uuid=$UUID" | sudo sfdisk $DATA_DISK_DEV;

# Assign the new partition device to this variable
PARTITION_DEV="${DATA_DISK_DEV}1";

# Sleep to allow new partition devices to be scanned
sleep 10;
while [ ! -e $PARTITION_DEV ];
  do
    echo "Partition device not yet initialized. Sleeping...";
    sleep 10;
done

# Format the partition with an ext4 filesystem
sudo mkfs.ext4 $PARTITION_DEV;

# Create the mountpoint
sudo mkdir $MOUNT_POINT;

# Mount the new filesystem
sudo mount -t ext4 -o rw $PARTITION_DEV $MOUNT_POINT;

# Get the file system UUID
FS_UUID=$(sudo blkid -s UUID -o value $PARTITION_DEV);

# Modify /etc/fstab by appending a line for this filesystem and mount point
FSTAB_ADDITION="UUID=$FS_UUID $MOUNT_POINT ext4 rw 0 0";
echo "Adding line to /etc/fstab: \"${FSTAB_ADDITION}\"";
sudo echo $FSTAB_ADDITION | sudo tee -a /etc/fstab > /dev/null;
