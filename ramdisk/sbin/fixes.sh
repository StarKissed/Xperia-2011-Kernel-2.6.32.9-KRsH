#!/sbin/busybox sh
# App2SD Fix (thanks to LSS4181)

if [ $(/sbin/ics-or-jb.sh) == "jb" ]
then
    mount -o remount,rw /
    # App2SD fix for Jellybean
    rm -r /mnt/secure/asec
    mkdir /mnt/secure/asec
    mount -o bind /sdcard/.android_secure /mnt/secure/asec
    mv /mnt/secure/.android_secure /mnt/secure/asec
    mount -o remount,ro /
fi
