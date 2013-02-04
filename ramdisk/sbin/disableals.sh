#!/sbin/sh


if [ -e /data/als_disabled ]; then
    echo 0 > /sys/devices/i2c-0/0-0040/leds/lcd-backlight/als/enable
fi