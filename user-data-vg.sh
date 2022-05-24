#!/bin/bash
set -eu

yum update -y
yum install nvme-cli util-linux  -y
echo ##BEGIN LIST OF NVME
nvme list
echo ##END LIST OF NVME

declare -r disks=($(nvme list | grep Instance | cut -f 1 -d ' '))
if (( ${#disks[@]} )); then
    for i in "${disks[@]}"
    do
        echo "Creating PV $i"
        pvcreate $i
    done


    echo "Creating VG=VGInstance $disks"
    vgcreate VGInstance $disks
fi

# We use the kubelet flag --protect-kernel-defaults=true, this requires us to modify kernel parameters:
cat > /etc/sysctl.d/90-kubelet.conf << EOF
vm.overcommit_memory=1
kernel.panic=10
kernel.panic_on_oops=1
EOF
sysctl -p /etc/sysctl.d/90-kubelet.conf