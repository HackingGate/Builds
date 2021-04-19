#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

echo "Download OpenWrt Image Builder ${OPENWRT_VERSION}"

# Download imagebuilder for WR703N.
aria2c -c -x4 -s4 https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/ath79/tiny/openwrt-imagebuilder-${OPENWRT_VERSION}-ath79-tiny.Linux-x86_64.tar.xz

# Extract & remove used file & cd to the directory
tar -xvf openwrt-imagebuilder-${OPENWRT_VERSION}-ath79-tiny.Linux-x86_64.tar.xz
rm openwrt-imagebuilder-${OPENWRT_VERSION}-ath79-tiny.Linux-x86_64.tar.xz
cd openwrt-imagebuilder-${OPENWRT_VERSION}-ath79-tiny.Linux-x86_64/

# Replace tiny-tp-link.mk
cd target/linux/ath79/image
wget https://github.com/HackingGate/openwrt/raw/openwrt-21.02-modified-device/target/linux/ath79/image/tiny-tp-link.mk -O tiny-tp-link.mk
cd -

# Use https
sed -i 's/http:/https:/g' .config repositories.conf

# Make all kernel modules built-in
sed -i -e "s/=m/=y/g" build_dir/target-mips_24kc_musl/linux-ath79_tiny/linux-*/.config

# Run the final build configuration
make image PROFILE=tplink_tl-wr703n \
PACKAGES="ca-bundle ca-certificates libustream-openssl ppp ppp-mod-pppoe \
uhttpd uhttpd-mod-ubus libiwinfo-lua luci-base luci-app-firewall luci-mod-admin-full luci-theme-bootstrap luci \
-wpad-mini -wpad-basic wpad-openssl curl wget tcpdump \
-dnsmasq dnsmasq-full"

# Result
cd bin/targets/ath79/tiny/
cat profiles.json | jq
cat sha256sums
