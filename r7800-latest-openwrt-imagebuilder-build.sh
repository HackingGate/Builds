#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

VERSION=`./git-describe-latest-openwrt-tag.awk`
echo "Download OpenWrt Image Builder $VERSION"

# Download imagebuilder for R7800.
aria2c -c -x4 -s4 https://downloads.openwrt.org/releases/${VERSION}/targets/ipq806x/generic/openwrt-imagebuilder-${VERSION}-ipq806x-generic.Linux-x86_64.tar.xz

# Extract & remove used file & cd to the directory
tar -xvf openwrt-imagebuilder-${VERSION}-ipq806x-generic.Linux-x86_64.tar.xz
rm openwrt-imagebuilder-${VERSION}-ipq806x-generic.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-${VERSION}-ipq806x-generic.Linux-x86_64/

# Use https when making image
sed -i 's/http:/https:/g' repositories.conf

Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-arm_cortex-a15+neon-vfpv4_musl_eabi/linux-ipq806x_generic/linux-*/.config

# Run the final build configuration
make image PROFILE=netgear_r7800 \
PACKAGES="ca-bundle ca-certificates libustream-openssl -ppp -ppp-mod-pppoe \
uhttpd uhttpd-mod-ubus libiwinfo-lua luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap \
-wpad-mini -wpad-basic wpad-openssl usbutils block-mount e2fsprogs samba4-server luci-app-samba4 \
aria2 luci-app-aria2 ariang stubby curl wget tcpdump kmod-fs-ext4 kmod-usb-storage kmod-usb-storage-uas"

# list result
ls $PWD/bin/targets/ipq806x/generic