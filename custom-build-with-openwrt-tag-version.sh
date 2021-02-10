#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

echo "Cloning OpenWrt ${OPENWRT_TAG}"
git clone --branch ${OPENWRT_TAG} https://github.com/openwrt/openwrt.git
cd openwrt
./scripts/feeds update
./scripts/feeds install

# Add tl-wr703n-v1-16m defination
echo '
define Device/tl-wr703n-v1
  $(Device/tplink-16mlzma)
  DEVICE_TITLE := TP-LINK TL-WR703N v1
  DEVICE_PACKAGES := kmod-usb-core kmod-usb2
  BOARDNAME := TL-WR703N
  DEVICE_PROFILE := TLWR703
  TPLINK_HWID := 0x07030101
  CONSOLE := ttyATH0,115200
  IMAGE/factory.bin := append-rootfs | mktplinkfw factory -C US
endef
TARGET_DEVICES += tl-wr703n-v1
' >> target/linux/ar71xx/image/generic-tp-link.mk

# Download .config
wget https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/ar71xx/generic/config.buildinfo -O config.buildinfo
rm -rf .config*
mv config.buildinfo .config

make defconfig

# Remove other devices
sed -i '/CONFIG_TARGET_DEVICE_*/d' .config

# Select tl-wr703n-v1 only
echo '
CONFIG_TARGET_BOARD="ar71xx"
CONFIG_TARGET_SUBTARGET="generic"
CONFIG_TARGET_ar71xx_generic_DEVICE_tl-wr703n-v1=y
CONFIG_TARGET_PROFILE="DEVICE_tl-wr703n-v1"
' >> .config

make defconfig
