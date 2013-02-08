#!/sbin/sh

if [ ! -L /system/lib/modules/bcm4329.ko ]; then
          mount -o remount,rw system
          rm -rf /system/lib/modules/bcm4329.ko
          ln -s /modules/bcm4329.ko /system/lib/modules/bcm4329.ko
          mount -o remount,ro system
fi