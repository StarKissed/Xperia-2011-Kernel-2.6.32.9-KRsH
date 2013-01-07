#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

busybox cd /
busybox date >>boot.txt
exec >>boot.txt 2>&1
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t yaffs2 ${BOOTREC_CACHE} /cache

# fixing CPU clocks to avoid issues in recovery
busybox echo 1024000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
busybox echo 122000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq


# trigger blue LED
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 255 > ${BOOTREC_LED_BLUE}

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 2

# android ramdisk (jb is default)
load_image=/sbin/ramdisk-jb.cpio

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox echo 'BOOTMENU' >>boot.txt
	busybox rm /cache/recovery/boot
	# trigger blue led
	busybox echo 255 > ${BOOTREC_LED_RED}
	busybox echo 255 > ${BOOTREC_LED_GREEN}
	busybox echo 255 > ${BOOTREC_LED_BLUE}
    # start aroma bootmenu
    busybox mkdir /sdcard
    busybox mkdir /tmp
    busybox mount /dev/block/mmcblk0p1 /sdcard
    /sbin/adbd&/sbin/aroma 1 0 "/sbin/aroma-res.zip"
    # copy repair log to sdcard if requested
    if [ -e /tmp/turbo_repair.ready2copy ]
    then
        busybox rm /tmp/turbo_repair.ready2copy
        busybox mv /tmp/turbo_repair.log /sdcard/turbo_repair.log
    fi
    busybox sync
    busybox umount /dev/block/mmcblk0p1
    rm -rf /sdcard
    #if [ ! -e /tmp/bootrec ]
    #then
    #    reboot
    #fi
fi

if [ -e /tmp/bootrec ]
    # recovery ramdisk
    rm /tmp/bootrec
    rm -rf /tmp
	load_image=/sbin/recovery-twrp.cpio
	echo 0 > /sys/module/msm_fb/parameters/align_buffer
else
    rm -rf /tmp
	busybox echo 'ANDROID BOOT' >>boot.txt
	# poweroff LED
	busybox echo 0 > ${BOOTREC_LED_RED}
	busybox echo 0 > ${BOOTREC_LED_GREEN}
	busybox echo 0 > ${BOOTREC_LED_BLUE}
	echo 1 > /sys/module/msm_fb/parameters/align_buffer
fi

# kill the keycheck process
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox cpio -i < ${load_image}

busybox umount /cache
busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
busybox date >>boot.txt
export PATH="${_PATH}"
exec /init
