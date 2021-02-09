#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

echo "Cloning OpenWrt ${OPENWRT_TAG}"
git clone --branch ${OPENWRT_TAG} https://github.com/openwrt/openwrt.git
cd openwrt
./scripts/feeds update
./scripts/feeds install