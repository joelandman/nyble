#!/bin/sh
# ramdisk images

[ -z "$root" ] && root=$(getarg root=)

rootfstype=$(getarg rootfstype=)

if [ -n "$rootfstype" ]; then
  if [ $rootfstype = "ramdisk" ]; then
        info "booting ramdisk:"
        rootok=1
        root="ram"
  fi
fi
