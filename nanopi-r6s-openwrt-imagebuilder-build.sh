#!/bin/bash

# Exit immediately if a simple command exits with a non-zero status
set -e

OPENWRT_MAJOR_VERSION=`echo ${OPENWRT_VERSION} | grep -E -o '[0-9]+\.[0-9]+'`
TARGET='rockchip'
SUBTARGET='armv8'
DEVICE_NAME='friendlyarm_nanopi-r6s'

echo "Download OpenWrt Image Builder ${OPENWRT_VERSION}"

# Download imagebuilder for NanoPi R6S.
aria2c -c -x4 -s4 https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst

# Extract & remove used file & cd to the directory
tar -xvf openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst
rm openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst
cd openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64/

# Configure partition sizes for faster builds
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=16/CONFIG_TARGET_KERNEL_PARTSIZE=128/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=104/CONFIG_TARGET_ROOTFS_PARTSIZE=512/' .config

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-aarch64_generic_musl/linux-${TARGET}_${SUBTARGET}/linux-*/.config

# Create custom files directory structure for filesystem expansion
mkdir -p files/etc/uci-defaults

# Create the official OpenWrt root partition expansion script
cat << "EOF" > files/etc/uci-defaults/70-rootpt-resize
if [ ! -e /etc/rootpt-resize ] \
&& type parted > /dev/null \
&& lock -n /var/lock/root-resize
then
ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e \
'$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
ROOT_DISK="/dev/$(basename "${ROOT_BLK%/*}")"
ROOT_PART="${ROOT_BLK##*[^0-9]}"
parted -f -s "${ROOT_DISK}" \
resizepart "${ROOT_PART}" 100%
mount_root done
touch /etc/rootpt-resize
 
if [ -e /boot/cmdline.txt ]
then 
NEW_UUID=`blkid ${ROOT_DISK}p${ROOT_PART} | sed -n 's/.*PARTUUID="\([^"]*\)".*/\1/p'`
sed -i "s/PARTUUID=[^ ]*/PARTUUID=${NEW_UUID}/" /boot/cmdline.txt
fi
 
reboot
fi
exit 1
EOF

# Create the official OpenWrt root filesystem expansion script
cat << "EOF" > files/etc/uci-defaults/80-rootfs-resize
if [ ! -e /etc/rootfs-resize ] \
&& [ -e /etc/rootpt-resize ] \
&& type losetup > /dev/null \
&& type resize2fs > /dev/null \
&& lock -n /var/lock/root-resize
then
ROOT_BLK="$(readlink -f /sys/dev/block/"$(awk -e \
'$9=="/dev/root"{print $3}' /proc/self/mountinfo)")"
ROOT_DEV="/dev/${ROOT_BLK##*/}"
LOOP_DEV="$(awk -e '$5=="/overlay"{print $9}' \
/proc/self/mountinfo)"
if [ -z "${LOOP_DEV}" ]
then
LOOP_DEV="$(losetup -f)"
losetup "${LOOP_DEV}" "${ROOT_DEV}"
fi
resize2fs -f "${LOOP_DEV}"
mount_root done
touch /etc/rootfs-resize
reboot
fi
exit 1
EOF

# Create sysupgrade.conf to preserve expansion scripts across firmware upgrades
cat << "EOF" > files/etc/sysupgrade.conf
/etc/uci-defaults/70-rootpt-resize
/etc/uci-defaults/80-rootfs-resize
EOF

# Run the final build configuration
# https://openwrt.org/docs/guide-user/additional-software/imagebuilder
#  The list of currently installed packages on your device can be obtained with the following command:
# echo $(opkg list-installed | sed -e "s/\s.*$//")
make -j$(nproc) image \
PROFILE=${DEVICE_NAME} \
FILES="files" \
PACKAGES="base-files dropbear libc logd mtd opkg procd-ujail uboot-envtools uci urandom-seed urngd \
ca-bundle ca-certificates libustream-mbedtls \
-dnsmasq dnsmasq-full odhcp6c odhcpd-ipv6only ppp ppp-mod-pppoe 6in4 https-dns-proxy luci-proto-wireguard \
kmod-fs-ext4 kmod-gpio-button-hotplug kmod-r8169 kmod-usb-storage kmod-usb-storage-uas kernel \
block-mount e2fsprogs mkf2fs partx-utils resize2fs f2fs-tools fdisk lsblk losetup blockdev parted blkid \
luci luci-app-aria2 luci-app-attendedsysupgrade luci-app-cloudflared luci-app-https-dns-proxy luci-app-samba4 luci-app-statistics \
collectd-mod-ping collectd-mod-wireless \
aria2 ariang samba4-server tailscale \
bash bind-host curl diffutils git map tar tcpdump usbutils vim"

# Result
cd bin/targets/${TARGET}/${SUBTARGET}/
cat profiles.json | jq
cat sha256sums
