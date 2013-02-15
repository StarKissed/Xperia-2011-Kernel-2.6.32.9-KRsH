#!/sbin/sh
#

mount -o remount,rw /

#set -x
#exec >>/boot.log 2>&1

turbo.mode=`/sbin/ics-or-jb.sh`

if [ "$turbo.mode" == "jb" ]; then
    echo "[TURBO] Running App2SD fix for Jellybean" >>boot.log
    # App2SD fix for Jellybean (thanks to LSS4181)
    rm -r /mnt/secure/asec
    mkdir /mnt/secure/asec
    mv /mnt/secure/.android_secure /mnt/secure/asec
    mount -o bind /sdcard/.android_secure /mnt/secure/asec
fi

# Required for some ROM's
echo "[TURBO] Setting rwxrwxrwx on /data/dalvik-cache" >>boot.log
chmod -R 777 /data/dalvik-cache

# Stock fixes
if [ -e /turbo_stock-ics ]; then
    echo "[TURBO] Stock ICS ROM detected..." >>boot.log
    if [ -e /data/data/com.android.providers.settings/databases/settings.db ]; then
        echo "    Verifying window/transition animation settings..." >>boot.log
        eval test=`/sbin/sqlite3 -nullvalue 'nullvalue' -column /data/data/com.android.providers.settings/databases/settings.db 'SELECT value FROM system WHERE name="window_animation_scale";'`
        if [ "$test" != "0.0" ]; then
            echo "    Setting window animation scale to 0.0..." >>boot.log
            /sbin/sqlite3 -nullvalue 'nullvalue' -column /data/data/com.android.providers.settings/databases/settings.db 'UPDATE system SET value=0.0 WHERE name="window_animation_scale";'
        else
            echo "    Window animation scale already 0.0" >>boot.log
        fi
        eval test=`/sbin/sqlite3 -nullvalue 'nullvalue' -column /data/data/com.android.providers.settings/databases/settings.db 'SELECT value FROM system WHERE name="transition_animation_scale";'`
        if [ "$test" != "0.0" ]; then
            echo "    Setting transition animation scale to 0.0..." >>boot.log
            /sbin/sqlite3 -nullvalue 'nullvalue' -column /data/data/com.android.providers.settings/databases/settings.db 'UPDATE system SET value=0.0 WHERE name="transition_animation_scale";'
        else
            echo "    Transition animation scale already 0.0" >>boot.log
        fi
    else
        if [ ! -e /data/data/com.android.providers.settings/databases/settings.db ]; then
            echo "    Settings database not found! Show warning..." >>boot.log
            echo "reboot_required=yes" > /reboot_required
            /sbin/aroma 1 0 "/sbin/aroma-res.zip"
        fi
    fi
fi

if [ -e /turbo_stock-gb ]; then
    echo "`getprop ro.product.manufacturer`" > /sys/class/android_usb/android0/iManufacturer
    echo "`getprop ro.semc.product.device`" > /sys/class/android_usb/android0/iProduct
fi

sleep 1
sync

if [ "`getprop init.svc.bootanim`" == "stopped" ]; then
    # Things here will only run when fixes.sh is run the second time (after boot finishes)
    if [ -e /reboot_required ]; then
        reboot
    fi
fi

mount -o remount,ro /
