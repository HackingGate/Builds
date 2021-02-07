#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

TAG=`./git-describe-latest-tag.awk https://github.com/openwrt/openwrt`
echo "Cloning OpenWrt $TAG"
git clone --branch $TAG https://github.com/openwrt/openwrt.git
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a