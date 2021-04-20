#!/bin/bash

# Exit immediately if a simple command exits with a non-zero status
set -e

OPENWRT_MAJOR_VERSION=`echo ${OPENWRT_VERSION} | grep -E -o '[0-9]+\.[0-9]+'`
TARGET='ath79'
DEVICE_NAME='tl-wr703n'

# Workaround to fix ath79 missing wifi
if [[ $OPENWRT_MAJOR_VERSION < '20.02' ]]; then
    TARGET='ar71xx'
    DEVICE_NAME='tl-wr703n-v1'
fi

echo "Download OpenWrt Image Builder ${OPENWRT_VERSION}"

# Download imagebuilder for WR703N.
aria2c -c -x4 -s4 https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/tiny/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-tiny.Linux-x86_64.tar.xz

# Extract & remove used file & cd to the directory
tar -xvf openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-tiny.Linux-x86_64.tar.xz
rm openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-tiny.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-tiny.Linux-x86_64/

# Replace tiny-tp-link.mk
cd target/linux/${TARGET}/image
wget https://github.com/HackingGate/openwrt/raw/openwrt-${OPENWRT_MAJOR_VERSION}-modified-device/target/linux/${TARGET}/image/tiny-tp-link.mk -O tiny-tp-link.mk
cd -

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-mips_24kc_musl/linux-${TARGET}_tiny/linux-*/.config

# Run the final build configuration
make image PROFILE=${DEVICE_NAME} \
PACKAGES="luci"

# Result
cd bin/targets/${TARGET}/tiny/
cat profiles.json | jq
cat sha256sums
