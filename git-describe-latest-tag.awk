#!/usr/bin/awk -f

# https://stackoverflow.com/a/29138871/4063462
BEGIN {
  FS = "[ /^]+"
  while ("git ls-remote " ARGV[1] "| sort -Vk2" | getline) {
    tag = $3
  }
  printf "%s", tag
}
