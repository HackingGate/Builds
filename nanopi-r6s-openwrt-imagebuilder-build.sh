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

# Configure rootfs partition size (1GB = 1024MB)
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=104/CONFIG_TARGET_ROOTFS_PARTSIZE=256/' .config

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-aarch64_generic_musl/linux-${TARGET}_${SUBTARGET}/linux-*/.config

# Create custom files directory structure for filesystem expansion
mkdir -p files/etc/uci-defaults

# Download the filesystem expansion script directly to uci-defaults
curl -o files/etc/uci-defaults/99-expand-rootfs https://gist.githubusercontent.com/HackingGate/98f80db3645a3c383ea4fa179aaa4e25/raw/f2c27da2bbb53a35556100367b03f9b650766bd8/expand_rootfs.sh

# Make the script executable
chmod +x files/etc/uci-defaults/99-expand-rootfs

# Run the final build configuration
make -j$(nproc) image PROFILE=${DEVICE_NAME} \
PACKAGES="base-files dropbear libc logd mtd opkg procd-ujail uboot-envtools uci urandom-seed urngd \
ca-bundle ca-certificates libustream-mbedtls \
-dnsmasq dnsmasq-full odhcp6c odhcpd-ipv6only ppp ppp-mod-pppoe 6in4 https-dns-proxy luci-proto-wireguard \
kmod-fs-ext4 kmod-gpio-button-hotplug kmod-r8169 kmod-usb-storage kmod-usb-storage-uas kernel \
block-mount e2fsprogs mkf2fs partx-utils resize2fs util-linux \
luci luci-app-aria2 luci-app-attendedsysupgrade luci-app-cloudflared luci-app-https-dns-proxy luci-app-samba4 luci-app-statistics \
collectd-mod-ping collectd-mod-wireless \
aria2 ariang samba4-server tailscale \
bash bind-host curl diffutils git map tar tcpdump usbutils vim"

# Result
cd bin/targets/${TARGET}/${SUBTARGET}/
cat profiles.json | jq
cat sha256sums
