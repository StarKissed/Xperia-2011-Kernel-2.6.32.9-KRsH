#!/sbin/sh
#

turbo.mode=`/sbin/ics-or-jb.sh`

if [ "$turbo.mode" == "jb" ]; then
    mount -o remount,rw /
    echo "[TURBO] Running App2SD fix for Jellybean" >>boot.log
    # App2SD fix for Jellybean (thanks to LSS4181)
    rm -r /mnt/secure/asec
    mkdir /mnt/secure/asec
    mv /mnt/secure/.android_secure /mnt/secure/asec
    mount -o bind /sdcard/.android_secure /mnt/secure/asec
    # nothing else to do, remount root
    mount -o remount,ro /
fi

if [ "$turbo.mode" == "ics" ]; then
    # Required for some older ICS ROM's
    echo "[TURBO] Setting rwxrwxrwx on /data/dalvik-cache for ICS" >>boot.log
    chmod -R 777 /data/dalvik-cache
fi
