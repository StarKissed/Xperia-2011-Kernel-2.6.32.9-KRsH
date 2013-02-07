#!/sbin/busybox sh

if [[ ! -f /system/lib/modules/bcm4329.ko ]] ||
       [[ $(ls -l /system/lib/modules/bcm4329.ko | awk '{print $5}') -ne $(ls -l /modules/bcm4329.ko | awk '{print $5}') ]]; then
          mount -o remount,rw system
          rm /system/lib/modules/bcm4329.ko
          cp /modules/bcm4329.ko /system/lib/modules/
          mount -o remount,ro system
fi