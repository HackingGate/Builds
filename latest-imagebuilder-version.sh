#!/bin/bash

# Exit immediately if a simple command exits with a non-zero status
set -e

OPENWRT_VERSION=`curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[]["name"]' | grep ${3} | head -1 | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+($|-rc[0-9]+$)'`
IMAGEBUILDER_HTTP_CODE=`curl -s -o /dev/null --head -w "%{http_code}" https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${1}/${2}/openwrt-imagebuilder-${OPENWRT_VERSION}-${1}-${2}.Linux-x86_64.tar.xz`
if [[ "$IMAGEBUILDER_HTTP_CODE" != 200 ]]; then
    echo "Not found for https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${1}/${2}/openwrt-imagebuilder-${OPENWRT_VERSION}-${1}-${2}.Linux-x86_64.tar.xz"
    # Use previous version if imagebuilder not yet available
    OPENWRT_VERSION=`curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[1]["name"]' | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+($|-rc[0-9]+$)'`
    echo "Use previous version ${OPENWRT_VERSION} instead"
fi

echo ${OPENWRT_VERSION}
