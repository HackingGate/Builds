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

# Replace image files with custom 32GB eMMC configuration
cd target/linux/${TARGET}/image
wget https://github.com/HackingGate/openwrt/raw/openwrt-${OPENWRT_MAJOR_VERSION}-modified-device/target/linux/${TARGET}/image/Makefile -O Makefile
wget https://github.com/HackingGate/openwrt/raw/openwrt-${OPENWRT_MAJOR_VERSION}-modified-device/target/linux/${TARGET}/image/armv8.mk -O armv8.mk
cd -

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-aarch64_generic_musl/linux-${TARGET}_${SUBTARGET}/linux-*/.config

# Run the final build configuration
make image PROFILE=${DEVICE_NAME} \
PACKAGES="luci ca-bundle ca-certificates \
-dnsmasq dnsmasq-full \
https-dns-proxy luci-app-https-dns-proxy \
luci-app-wireguard luci-proto-wireguard 6in4 \
ddns-scripts ddns-scripts-cloudflare luci-app-ddns \
luci-app-cloudflared tailscale \
block-mount e2fsprogs kmod-fs-ext4 resize2fs \
kmod-usb-storage kmod-usb-storage-uas usbutils \
samba4-server luci-app-samba4 \
aria2 luci-app-aria2 ariang \
luci-app-statistics collectd-mod-cpu collectd-mod-interface collectd-mod-memory collectd-mod-ping collectd-mod-rrdtool collectd-mod-wireless \
auc luci-app-attendedsysupgrade \
kmod-r8169 \
bind-host curl wget tcpdump \
diffutils git map bash tar vim"

# Result
cd bin/targets/${TARGET}/${SUBTARGET}/
cat profiles.json | jq
cat sha256sums
