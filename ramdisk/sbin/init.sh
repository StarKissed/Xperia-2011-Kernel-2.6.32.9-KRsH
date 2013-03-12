#!/sbin/busybox sh
_PATH="$PATH"
export PATH=/sbin
export ANDROID_CACHE=/cache

cd /
busybox echo "[TURBO] Stage 1 begins" >>boot.log
busybox date >>boot.log
#set -x
#exec >>boot.log 2>&1
busybox rm /init

# device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev
busybox mount -t tmpfs -o size=10M,mode=0755 tmpfs /dev
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys
busybox mkdir -m 755 -p /tmp
busybox mount -t tmpfs -o size=10M,mode=0755 tmpfs /tmp

# create device nodes
busybox mknod -m 600 $BOOTREC_CACHE_NODE
busybox mknod -m 600 $BOOTREC_EVENT_NODE
busybox mknod -m 666 /dev/null c 1 3
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 /dev/block/mmcblk0p1 b 179 1
busybox mknod -m 600 /dev/block/mmcblk0p2 b 179 2

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 $BOOTREC_CACHE /cache

# fixing CPU clocks to avoid issues in recovery
busybox echo 1024000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo 122000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq

# make links
busybox mkdir /sbin/internal
busybox ln -s /sbin/recoverz /sbin/internal/reboot
busybox ln -s /sbin/recoverz /sbin/sh

if [ ! -e /cache/recovery/boot ]; then
    # trigger blue LED
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 255 > $BOOTREC_LED_BLUE
    # trigger superquick vibration
    busybox echo 80 > $BOOTREC_VIBRATOR

    # keycheck
    busybox cat $BOOTREC_EVENT > /dev/keycheck&
    busybox sleep 2

    # LED off
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 0 > $BOOTREC_LED_BLUE
fi

busybox echo 200 > $BOOTREC_LED_RED
busybox echo 200 > $BOOTREC_LED_GREEN
busybox echo 200 > $BOOTREC_LED_BLUE

# default ramdisk
load_image=/sbin/ramdisk-twrp.cpio

# mount sdcard to load settings and such
#busybox mkdir /sdcard
#busybox mount -o errors=remount-ro /dev/block/mmcblk0p1 /sdcard

# sdcard error check
#if [ -e /cache/dorepair.prop ]; then
#    busybox rm -f /cache/dorepair.prop
#fi
#sdcard_test=`busybox mount | busybox grep '/sdcard'`
#sdcard_test2=`busybox mount | busybox grep '/sdcard' | busybox sed "s/(ro,//g"`
#if [ "$sdcard_test" != "$sdcard_test2" ]; then
#    busybox mkdir /cache/recovery
#    busybox touch /cache/recovery/boot
#    busybox echo "repair=sdcard" > /cache/dorepair.prop
#fi

#busybox umount -l /sdcard

busybox mkdir /sd-ext

# check for ext4 partition
rm /cache/enterbootmenu.prop
sdxt=`busybox blkid | busybox grep mmcblk0p2 | busybox sed s/.*TYPE=\"//g | busybox sed s/\"//g`
if [ "$sdxt" != "ext4" ]; then
    busybox mkdir /cache/recovery
    busybox touch /cache/recovery/boot
    busybox echo "reason=noext4" > /cache/enterbootmenu.prop
else
    busybox mount /dev/block/mmcblk0p2 /sd-ext
    # fresh turbo check
    if [ ! -e /sd-ext/turbo/version ]; then
        # Boot Menu has never run, force it
        busybox mkdir /cache/recovery
        busybox touch /cache/recovery/boot
    fi
fi

# ensure slot folders exist
busybox mkdir /sd-ext/turbo/system2
busybox mkdir /sd-ext/turbo/userdata2
busybox mkdir /sd-ext/turbo/system3
busybox mkdir /sd-ext/turbo/userdata3
busybox mkdir /sd-ext/turbo/system4
busybox mkdir /sd-ext/turbo/userdata4

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo "[TURBO] Entering Boot Menu..." >>boot.log
	busybox rm /cache/recovery/boot
    busybox touch /tmp/bootrec
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

rec_image=/sbin/ramdisk-twrp.cpio

if [ -e /tmp/bootrec ]
then
    busybox rm /tmp/bootrec
    load_image=$rec_image
    busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
else
    # Prepare for normal boot
	busybox echo '[TURBO] Booting Android...' >>boot.log
    # Slot select
    if   [ -e /cache/multiboot1 ]
    then
        # Slot 1 (one time only)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot1mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (One-time only)' >>boot.log
    elif [ -e /cache/multiboot2 ]
    then
        # Slot 2 (one time only)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot2mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (One-time only)' >>boot.log
    elif [ -e /cache/multiboot3 ]
    then
        # Slot 3 (one time only)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot3mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (One-time only)' >>boot.log
    elif [ -e /cache/multiboot4 ]
    then
        # Slot 4 (one time only)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot4mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (One-time only)' >>boot.log
    elif [ -e /sd-ext/turbo/defaultboot_2 ]
    then
        # Slot 2 (default)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot2mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 2 (Default)' >>boot.log
    elif [ -e /sd-ext/turbo/defaultboot_3 ]
    then
        # Slot 3 (default)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot3mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 3 (Default)' >>boot.log
    elif [ -e /sd-ext/turbo/defaultboot_4 ]
    then
        # Slot 4 (default)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot4mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Slot 4 (Default)' >>boot.log
    else
        # Internal/Slot 1 (default)
        mode=$(busybox grep -F "mode=" /sd-ext/turbo/slot1mode.prop | busybox sed "s/mode=//g")
        busybox echo '[TURBO] Booting Internal/Slot 1 (Default)' >>boot.log
    fi
    if [ "$mode" == "" ]
    then
        busybox echo '[TURBO] Error - mode is not valid! Entering Recovery.' >>boot.log
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=$rec_image
    elif [ "$mode" == "JB-AOSP" ]
    then
        busybox echo 1 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-jb.cpio
        busybox echo '[TURBO] Mode is JB-AOSP' >>boot.log
    elif [ "$mode" == "ICS-AOSP" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics.cpio
        busybox echo '[TURBO] Mode is ICS-AOSP' >>boot.log
    elif [ "$mode" == "ICS-Stock" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-ics-stock.cpio
        busybox echo '[TURBO] Mode is ICS-Stock' >>boot.log
    elif [ "$mode" == "GB-Stock" ]
    then
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=/sbin/ramdisk-gb-stock.cpio
        busybox echo '[TURBO] Mode is GB-Stock' >>boot.log
    else
        busybox echo '[TURBO] Error - mode ('$mode') is not valid! Entering Recovery.' >>boot.log
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
        load_image=$rec_image
    fi
fi

busybox echo 0 > $BOOTREC_LED_RED
busybox echo 0 > $BOOTREC_LED_GREEN
busybox echo 0 > $BOOTREC_LED_BLUE

# unpack the ramdisk
busybox cpio -d -i -F ${load_image}

# make links
cd /sbin
./init_links.sh
cd ..

busybox echo 200 > $BOOTREC_LED_RED
busybox echo 200 > $BOOTREC_LED_GREEN
busybox echo 200 > $BOOTREC_LED_BLUE

#busybox cp /boot.log /cache/turboboot_last.log

busybox umount -l /cache
busybox umount -l /proc
busybox umount -l /sys
busybox umount -l /tmp
busybox umount -l /sd-ext
busybox rm -rf /sd-ext
busybox umount -l /sdcard
busybox rm -rf /sdcard

busybox echo 0 > $BOOTREC_LED_RED
busybox echo 0 > $BOOTREC_LED_GREEN
busybox echo 0 > $BOOTREC_LED_BLUE

busybox rm -rf /cache
busybox rm -rf /dev/*
busybox echo "[TURBO] Stage 1 finished" >>boot.log
busybox date >>boot.log
export PATH="${_PATH}"

exec /init
