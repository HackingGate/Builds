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
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=104/CONFIG_TARGET_ROOTFS_PARTSIZE=32768/' .config

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-aarch64_generic_musl/linux-${TARGET}_${SUBTARGET}/linux-*/.config

# Run the final build configuration
make image PROFILE=${DEVICE_NAME} \
PACKAGES="base-files ca-bundle dnsmasq dropbear e2fsprogs firewall4 fstools \
kmod-gpio-button-hotplug kmod-nft-offload libc libgcc libustream-mbedtls logd \
mkf2fs mtd netifd nftables odhcp6c odhcpd-ipv6only opkg partx-utils ppp \
ppp-mod-pppoe procd-ujail uboot-envtools uci uclient-fetch urandom-seed urngd \
kmod-r8169 luci \
ca-certificates \
-dnsmasq dnsmasq-full \
https-dns-proxy luci-app-https-dns-proxy \
luci-proto-wireguard 6in4 \
luci-app-cloudflared tailscale \
block-mount kmod-fs-ext4 resize2fs \
kmod-usb-storage kmod-usb-storage-uas usbutils \
samba4-server luci-app-samba4 \
aria2 luci-app-aria2 ariang \
luci-app-statistics collectd-mod-cpu collectd-mod-interface collectd-mod-memory collectd-mod-ping collectd-mod-rrdtool collectd-mod-wireless \
luci-app-attendedsysupgrade \
bind-host curl wget tcpdump \
diffutils git map bash tar vim"

# Result
cd bin/targets/${TARGET}/${SUBTARGET}/
cat profiles.json | jq
cat sha256sums
