#!/bin/bash

# Exit immediately if a simple command exits with a non-zero status
set -e

OPENWRT_VERSION=`git ls-remote --tags https://github.com/openwrt/openwrt | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+($|-rc[0-9]+$)' | tail -1`
IMAGEBUILDER_HTTP_CODE=`curl -s -o /dev/null --head -w "%{http_code}" https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${1}/${2}/openwrt-imagebuilder-${OPENWRT_VERSION}-${1}-${2}.Linux-x86_64.tar.xz`
if [[ "$IMAGEBUILDER_HTTP_CODE" != 200 ]]; then
    # Use previous version if imagebuilder not yet available
    OPENWRT_VERSION=`git ls-remote --tags https://github.com/openwrt/openwrt | grep -E -o '[0-9]+\.[0-9]+\.[0-9]+($|-rc[0-9]+$)' | tail -2 | head -1`
fi

echo ${OPENWRT_VERSION}
