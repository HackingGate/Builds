#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

# OpenWrt
find -regextype posix-extended -regex '.*\.(bin|img|json|manifest)' -exec sha256sum -b {} > sha256sums.txt \;
tree -H '.' -h --noreport --charset utf-8 -T ${GITHUB_REPOSITORY} -o index.html
cat github-corner.html >> index.html
sed -i "s~https://your-url~${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}~g" index.html
