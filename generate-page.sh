#!/bin/sh

# Exit immediately if a simple command exits with a non-zero status
set -e

git config --add remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git fetch origin gh-pages
git checkout gh-pages
# OpenWrt
sha256sum -b */*.+(bin|img|json|manifest) > sha256sums.txt
tree -H '.' -h --noreport --charset utf-8 -T ${GITHUB_REPOSITORY} -o index.html
cat github-corner.html >> index.html
sed -i "s~https://your-url~${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}~g" index.html
