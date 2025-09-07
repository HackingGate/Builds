#!/bin/bash

# Exit immediately if a simple command exits with a non-zero status
set -e

OPENWRT_MAJOR_VERSION=`echo ${OPENWRT_VERSION} | grep -E -o '[0-9]+\.[0-9]+'`
TARGET='ath79'
SUBTARGET='tiny'
DEVICE_NAME='tplink_tl-wr703n'

# Workaround to fix ath79 missing wifi
if [[ $OPENWRT_MAJOR_VERSION < '20.02' ]]; then
    TARGET='ar71xx'
    SUBTARGET='tiny'
    DEVICE_NAME='tl-wr703n-v1'
fi

echo "Download OpenWrt Image Builder ${OPENWRT_VERSION}"

# Download imagebuilder for TL-WR703N.
aria2c -c -x4 -s4 https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${TARGET}/${SUBTARGET}/openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst

# Extract & remove used file & cd to the directory
tar -xvf openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst
rm openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64.tar.zst
cd openwrt-imagebuilder-${OPENWRT_VERSION}-${TARGET}-${SUBTARGET}.Linux-x86_64/

# Replace tiny-tp-link.mk
cd target/linux/${TARGET}/image
wget https://github.com/HackingGate/openwrt/raw/openwrt-${OPENWRT_MAJOR_VERSION}-modified-device/target/linux/${TARGET}/image/tiny-tp-link.mk -O tiny-tp-link.mk
cd -

# Replace ar9331_tplink_tl-wr703n_tl-mr10u.dtsi
cd target/linux/${TARGET}/dts
wget https://github.com/HackingGate/openwrt/raw/openwrt-${OPENWRT_MAJOR_VERSION}-modified-device/target/linux/${TARGET}/dts/ar9331_tplink_tl-wr703n_tl-mr10u.dtsi -O ar9331_tplink_tl-wr703n_tl-mr10u.dtsi
cd -

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-mips_24kc_musl/linux-${TARGET}_${SUBTARGET}/linux-*/.config

# Run the final build configuration
make image PROFILE=${DEVICE_NAME} \
PACKAGES="luci"

# Result
cd bin/targets/${TARGET}/tiny/
cat profiles.json | jq
cat sha256sums
