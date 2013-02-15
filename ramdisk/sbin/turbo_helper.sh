#!/sbin/sh

#set -x
#exec >>/turbo_helper.log 2>&1

checkfresh()
{
    if [ ! -e /turbo/version ]; then
        # delete old settings
        rm -rf /turbo/*
        uname -r > /turbo/version;
        echo "icon=@slot1" > /turbo/slot1.prop
        echo "text=Slot 1" >> /turbo/slot1.prop
        echo "mode=JB-AOSP" > /turbo/slot1mode.prop
        echo "icon=@slot2" > /turbo/slot2.prop
        echo "text=Slot 2" >> /turbo/slot2.prop
        echo "mode=JB-AOSP" > /turbo/slot2mode.prop
        echo "icon=@slot3" > /turbo/slot3.prop
        echo "text=Slot 3" >> /turbo/slot3.prop
        echo "mode=JB-AOSP" > /turbo/slot3mode.prop
        echo "icon=@slot4" > /turbo/slot4.prop
        echo "text=Slot 4" >> /turbo/slot4.prop
        echo "mode=JB-AOSP" > /turbo/slot4mode.prop
        echo "1";
    else
        echo "0";
    fi     
}

checkoldimages()
{
    if [ -e /sdcard/system2.ext2.img ]   ||
       [ -e /sdcard/userdata2.ext2.img ] ||
       [ -e /sdcard/system3.ext2.img ]   ||
       [ -e /sdcard/userdata3.ext2.img ]; then
        echo "1";
    else
        echo "0";
    fi     
}

moveoldimages()
{
    mv /sdcard/system2.ext2.img /turbo/
    mv /sdcard/userdata2.ext2.img /turbo/
    mv /sdcard/system3.ext2.img /turbo/
    mv /sdcard/userdata3.ext2.img /turbo/
}

clearslot()
{
    rm -f '/turbo/system'$2'.ext2.img'
    rm -f '/turbo/userdata'$2'.ext2.img'
    echo "icon=@slot$2" > '/turbo/slot'$2'.prop'
    echo "text=Slot $2" >> '/turbo/slot'$2'.prop'
    echo "custom=true" >> '/turbo/slot'$2'.prop'
    echo "mode=JB-AOSP" > '/turbo/slot'$2'mode.prop'
}


checkslot()
{
    if [ ! -e /turbo/system$2.ext2.img ] && [ ! -e /turbo/userdata$2.ext2.img ]; then 
        echo "1";
    else
        echo "0";
    fi
}


checkdefault()
{
    if   [ -e /turbo/defaultboot_2 ]; then
        rm /turbo/defaultboot_1 >> /dev/null 2>&1
        rm /turbo/defaultboot_3 >> /dev/null 2>&1
        rm /turbo/defaultboot_4 >> /dev/null 2>&1
        echo "2";
    elif [ -e /turbo/defaultboot_3 ]; then
        rm /turbo/defaultboot_1 >> /dev/null 2>&1
        rm /turbo/defaultboot_4 >> /dev/null 2>&1
        echo "3";
    elif [ -e /turbo/defaultboot_4 ]; then
        rm /turbo/defaultboot_1 >> /dev/null 2>&1
        echo "4";
    else
        echo "1";
    fi
}


makeimage()
{
    if   [ "$3" == "system" ]; then
        IMGSIZE=$4
        rm /turbo/system$2.ext2.img
        dd if=/dev/zero of=/turbo/system$2.ext2.img bs=1K count=$IMGSIZE
        mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /turbo/system$2.ext2.img
        tune2fs -C 1 -m 0 -f /turbo/system$2.ext2.img
    elif [ "$3" == "userdata" ]; then
        IMGSIZE=$4
        rm /turbo/userdata$2.ext2.img
        dd if=/dev/zero of=/turbo/userdata$2.ext2.img bs=1K count=$IMGSIZE
        mke2fs -b 1024 -I 128 -m 0 -F -E resize=$(( IMGSIZE * 2 )) /turbo/userdata$2.ext2.img
        tune2fs -C 1 -m 0 -f /turbo/userdata$2.ext2.img
    fi
}


copyimage()
{
    mkdir /dest
    if   [ "$3" == "system" ]; then
        mount -t yaffs2 -o ro /dev/block/mtdblock0 /system
        mount -t ext2 -o rw,loop /turbo/system$2.ext2.img /dest
        cp -a /system/* /dest
        umount /system
    elif [ "$3" == "userdata" ]; then
        mount -t yaffs2 -o ro /dev/block/mtdblock1 /data
        mount -t ext2 -o rw,loop /turbo/userdata$2.ext2.img /dest
        cp -a /data/* /dest
        umount /data
    fi
    umount /dest
    rm -f -R /dest
}


mounter() # INTERNAL (parameter start at $1, i.e don't ever call from commandline)
{
    if  [ "$1" == "1" ]; then
        echo "[TURBO] No need to remount Slot 1" >>/boot.log
    else
        echo "[TURBO] About to switch mounts to Slot $1..." >>/boot.log
        umount /system
        umount /data
        losetup /dev/block/loop0 /turbo/system$1.ext2.img >>/boot.log
        losetup /dev/block/loop1 /turbo/userdata$1.ext2.img >>/boot.log
        mount -t ext2   -o rw                        /dev/block/loop0    /system >>/boot.log
        mount -t ext2   -o ro,remount                /dev/block/loop0    /system >>/boot.log
        mount -t ext2   -o rw,noatime,nosuid,nodev   /dev/block/loop1    /data >>/boot.log
        systemloop=`losetup | grep '/turbo/system'$1'.ext2.img' | awk '{print \$1}' | sed -e 's/:$//'`
        systemmount=`mount | grep $systemloop | awk '{print \$3}'`
        dataloop=`losetup | grep '/turbo/userdata'$1'.ext2.img' | awk '{print \$1}' | sed -e 's/:$//'`
        datamount=`mount | grep -m 1 $dataloop | awk '{print \$3}'`
        if [ "$systemmount" == "/system" ]; then
            echo "[TURBO] /turbo/system$1.ext2.img mounted on /system via $systemloop"
        else
            echo "[TURBO] Problem mounting /turbo/system$1.ext2.img to /system!"
        fi
        if [ "$datamount" == "/data" ]; then
            echo "[TURBO] /turbo/userdata$1.ext2.img mounted on /data via $dataloop"
        else
            echo "[TURBO] Problem mounting /turbo/userdata$1.ext2.img to /data!"
        fi
    fi
    
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 0 > $BOOTREC_LED_BLUE
    
    # TSDX
    if [ -e /data/tsdx/enabled ] && [ -d /data/data ]; then
        echo "[TSDX] TSDX Enabled" >>/boot.log
        # only proceed if data has been populated (i.e. ROM has booted at least once)
        # this is to ensure permissions are not broken
        if [ ! -d /sd-ext ]; then
            rm -r -f /sd-ext
            mkdir -p /sd-ext
            chmod -R 775 /sd-ext
            chown -R 0:0 /sd-ext
        fi
        chmod 775 /sd-ext
        chown 0:0 /sd-ext
        umount -l /sd-ext
        umount -l /dev/block/mmcblk0p2
        umount -l /dev/block/vold/179:2
        mount -t ext4 -o noauto_da_alloc,data=ordered,commit=15,barrier=1,nouser_xattr,errors=continue,noatime,nodiratime,nosuid,nodev /dev/block/mmcblk0p2 /sd-ext >>/boot.log
        if [ ! -d /sd-ext/data2 ]; then
            # Create data2sd folder for Titanium Backup if needed (to share app data between slots)
            mkdir -p /sd-ext/data2
            echo "[TSDX] Created /sd-ext/data2 for sharing app data (via Titanium Backup)" >>/boot.log
        fi
        for f in app app-asec app_s app-private framework_s lib_s; do
            if [ ! -h /data/$f ]; then
                # /data/$f not linked yet
                busybox echo 200 > $BOOTREC_LED_RED
                busybox echo 200 > $BOOTREC_LED_GREEN
                busybox echo 200 > $BOOTREC_LED_BLUE
                if [ -d /data/$f ]; then
                    # folder exists, move it
                    echo "[TSDX] Moving /data/$f to /sd-ext/$f" >>/boot.log
                    mv -f /data/$f /sd-ext/$f
                fi
                busybox echo 0 > $BOOTREC_LED_RED
                busybox echo 0 > $BOOTREC_LED_GREEN
                busybox echo 0 > $BOOTREC_LED_BLUE
                if [ ! -d /sd-ext/$f ]; then
                    # folder not exists yet (empty on internal), create it
                    echo "[TSDX] Creating /sd-ext/$f" >>/boot.log
                    mkdir -p /sd-ext/$f
                fi
                # link it
                echo "[TSDX] Linking /data/$f to /sd-ext/$f" >>/boot.log
                ln -s /sd-ext/$f /data/$f
            fi
        done
        if [ ! -h /data/system ]; then
            # /data/system not linked yet
            if [ -d /data/system ]; then
                # folder exists, move it
                busybox echo 200 > $BOOTREC_LED_RED
                busybox echo 200 > $BOOTREC_LED_GREEN
                busybox echo 200 > $BOOTREC_LED_BLUE
                echo "[TSDX] Moving /data/system to /sd-ext/system_slot$1" >>/boot.log
                mv /data/system /sd-ext/system_slot$1
                busybox echo 0 > $BOOTREC_LED_RED
                busybox echo 0 > $BOOTREC_LED_GREEN
                busybox echo 0 > $BOOTREC_LED_BLUE
            fi
            # link it
            echo "Linking /data/system to /sd-ext/system_slot$1"
            ln -s /sd-ext/system_slot$1 /data/system
        fi
    fi
    
    sync
}


mountproc()
{
    mount -o rw,remount -t rootfs rootfs /
    source /sbin/bootrec-device
    busybox echo 200 > $BOOTREC_LED_RED
    busybox echo 200 > $BOOTREC_LED_GREEN
    busybox echo 200 > $BOOTREC_LED_BLUE
    echo "[TURBO] Stage-2 (mountproc) started..." >>/boot.log
    mount -o errors=remount-ro /dev/block/mmcblk0p1 /sdcard >>/boot.log
    mount -o bind,errors=remount-ro /sdcard/turbo /turbo >>/boot.log
    # Test for ext# SDCard
    sdcard_ext=`mount | grep '/sdcard'`
    sdcard_ext2=`mount | grep '/sdcard' | sed "s/type ext//g"`
    if [ "$sdcard_ext" == "$sdcard_ext2" ]; then
        # not ext#, unmount it
        umount -l /sdcard >>/boot.log
    else
        # is ext#, keep mounted
        echo "[TURBO] ext-formatted SDCard detected" >>/boot.log
    fi
    if   [ -e /cache/multiboot1 ]; then
        rm /cache/multiboot1
        mounter 1
    elif [ -e /cache/multiboot2 ]; then
        rm /cache/multiboot2
        mounter 2
    elif [ -e /cache/multiboot3 ]; then
        rm /cache/multiboot3
        mounter 3
    elif [ -e /cache/multiboot4 ]; then
        rm /cache/multiboot4
        mounter 4
    elif [ -e /turbo/defaultboot_2 ]; then
        mounter 2
    elif [ -e /turbo/defaultboot_3 ]; then
        mounter 3
    elif [ -e /turbo/defaultboot_4 ]; then
        mounter 4
    else
        mounter 1
    fi
    
    # system free check
    systemfree=`df -m | grep '/system' | awk '{print $4}'`
    if test $systemfree -lt 1; then 
        echo "safe=no" > /tmp/systemfree.prop
        /sbin/aroma 1 0 "/sbin/aroma-res.zip"
        sync
        reboot
    fi

    # gapps full hack
    if [ ! -L /system/vendor/pittpatt ]; then
        # link faceunlock data to SDCard
        echo "[TURBO] Linking Faceunlock data to SDCard..." >>/boot.log
        mount -o remount,rw /system
        rm -rf /system/vendor/pittpatt
        mkdir -p /turbo/faceunlock
        ln -s /turbo/faceunlock /system/vendor/pittpatt
        mount -o remount,ro /system
    fi

    if [ ! -L /system/usr/srec/en-US ]; then
        # Link Google Now voice files to SDCard
        echo "[TURBO] Linking Google Now voice data to SDCard..." >>/boot.log
        mount -o remount,rw /system
        rm -rf /system/usr/srec/en-US
        mkdir -p /turbo/goolenow
        ln -s /turbo/goolenow /system/usr/srec/en-US
        mount -o remount,ro /system
    fi

    echo "[TURBO] Relocating dalvik-cache to /data/dalvik-cache..." >>/boot.log
    mkdir /data/dalvik-cache>>/boot.log
        chown system:system /data/dalvik-cache>>/boot.log
        chmod 0771 /data/dalvik-cache>>/boot.log
    mkdir /cache/dalvik-cache>>/boot.log
        chown system:system /cache/dalvik-cache>>/boot.log
        chmod 0771 /cache/dalvik-cache>>/boot.log
    mount -o bind /data/dalvik-cache /cache/dalvik-cache>>/boot.log
    
    sync
    
    echo "[TURBO] Running fixes/hacks script for specific ROM fixes..." >>/boot.log
    /sbin/fixes.sh

    /sbin/disableals.sh

    echo "[TURBO] Stage 2 finished, continue standard Android boot. Bye!" >>/boot.log
    date >>/boot.log
    
    sync
    mount -o ro,remount -t rootfs rootfs / >>/boot.log
    sync
    
    busybox echo 0 > $BOOTREC_LED_RED
    busybox echo 0 > $BOOTREC_LED_GREEN
    busybox echo 0 > $BOOTREC_LED_BLUE
}


checkfree()
{
    FREE=`df | grep $2 | awk '{print $4}'`
    SPACE=`expr $FREE - 10240`
    INPUT=`expr $3 + $4`
    echo "tmp=`expr $SPACE - $INPUT`" > /tmp/aroma/tmp.prop
}


checkcapacity()
{
    echo "tmp=`cat /proc/partitions | grep $2 | awk '{print $3}'`" > /tmp/aroma/tmp.prop
}


checktsdx()
{
    sync
    umount /system
    umount /data
    if  [ "$2" == "1" ]; then
        mount -t yaffs2 -o rw                       /dev/block/mtdblock0        /system
        mount -t yaffs2 -o rw,noatime,nosuid,nodev  /dev/block/mtdblock1        /data
    else
        losetup /dev/block/loop0 /turbo/system$1.ext2.img
        losetup /dev/block/loop1 /turbo/userdata$2.ext2.img
        mount -t ext2   -o rw,noatime,nosuid,nodev   /dev/block/loop0    /system
        mount -t ext2   -o rw,noatime,nosuid,nodev   /dev/block/loop1    /data
    fi
    
    sync
    
    if [ -e /data/tsdx/enabled ]; then
        echo "task=Remove" > /tmp/tsdxstatus.prop
    else
        echo "task=Install" > /tmp/tsdxstatus.prop
    fi
    
    sync
}


settsdx()
{
    sync

    if [ "$2" == "Install" ]; then
        mkdir -p /data/tsdx
        echo "1" > /data/tsdx/enabled
    fi

    if [ "$2" == "Remove" ]; then
        rm -rf /data/tsdx
        if [ ! -d /sd-ext ]; then
            # just in case
            rm -f /sd-ext # in case it's non-directory
            mkdir /sd-ext
            chmod -R 775 /sd-ext
            chown -R 0:0 /sd-ext
        fi
        mount /dev/block/mmcblk0p2 /sd-ext
        for f in app app-asec app_s app-private framework_s lib_s system; do
            if [ -h /data/$f ]; then
                # only delete and copy if symbolic link (i.e. TSDX is active)
                rm -f /data/$f
                if [ "$f" == "system" ]; then
                    # special case (always move/delete from sd-ext)
                    mv -f /sd-ext/system_slot$3 /data/system
                elif [ "$f" != "app" ] && [ "$f" != "app-asec" ] ; then
                    # only copy if not /data/app or app-asec
                    cp -a /sd-ext/$f /data/$f
                fi
            fi
        done
    fi

    if [ "$2" == "clean" ]; then
        rm -rf /sd-ext/app
        rm -rf /sd-ext/app-asec
        rm -rf /sd-ext/app-private
        rm -rf /sd-ext/app_s
        rm -rf /sd-ext/framework_s
        rm -rf /sd-ext/lib_s
    fi

    sync
}


setdefaultslot()
{
    sync
    rm -f /turbo/defaultboot_1
    rm -f /turbo/defaultboot_2
    rm -f /turbo/defaultboot_3
    rm -f /turbo/defaultboot_4
    echo "1" > /turbo/defaultboot_$2
    sync
}


checkurandom()
{
    sync
    
    if [ -e /data/urandomwrapper_disabled ]; then
        echo "title=Set urandom as entropy device" > /tmp/urandomstatus.prop
        echo "text=Not a seeder - this has 0% footprint. On ROM startup will replace the 'random' node with the faster urandom device." >> /tmp/urandomstatus.prop
        echo "task=enable" >> /tmp/urandomstatus.prop
    else
        echo "title=Restore random entropy device" > /tmp/urandomstatus.prop
        echo "text=Use standard random device for entropy" >> /tmp/urandomstatus.prop
        echo "task=disable" >> /tmp/urandomstatus.prop
    fi
    
    sync
}

seturandom()
{
    sync
    
    if [ "$2" == "enable" ]; then
        rm -f /data/urandomwrapper_disabled
    fi

    if [ "$2" == "disable" ]; then
        echo "1" > /data/urandomwrapper_disabled
    fi
    
    sync
}

enableurandom()
{
    if [ ! -e /data/urandomwrapper_disabled ]; then
        sync
        mount -o rw,remount -t rootfs rootfs /
        rm -f /dev/random
        mknod -m 444 /dev/random c 1 9
        chown root:root /dev/random
        mount -o ro,remount -t rootfs rootfs /
        sync
    fi
}

checkdeasec()
{
    sync
    
    if [ -e /data/deasec_enabled ]; then
        echo "title=Disable Deasec v2" > /tmp/deasecstatus.prop
        echo "text=Restore the buggy and annoying asec package encyption of Jellybean" >> /tmp/deasecstatus.prop
        echo "task=disable" >> /tmp/deasecstatus.prop
    else
        echo "title=Enable Deasec v2" > /tmp/deasecstatus.prop
        echo "text=By Giovanni Aneloni, enahnced by CosmicDan. This will force ROM to decrypt any apps on startup." >> /tmp/deasecstatus.prop
        echo "task=enable" >> /tmp/deasecstatus.prop
    fi
    
    sync
}

setdeasec()
{
    sync

    if [ "$2" == "disable" ]; then
        rm -f /data/deasec_enabled
    fi

    if [ "$2" == "enable" ]; then
        echo "1" > /data/deasec_enabled
    fi

    sync
}

checkusb()
{
    sync
    
    current=`grep -F "persist.sys.usb.config=" /system/build.prop | sed "s/persist.sys.usb.config=//g" | sed "s/,adb//g"`
    if [ "$current" == "mtp" ]; then
        echo "title=Change USB to UMS" > /tmp/usbstatus.prop
        echo "text=This slot currently set to MTP mode. Select to change to UMS (mass_storage)." >> /tmp/usbstatus.prop
        echo "task=mass_storage" >> /tmp/usbstatus.prop
    else # if it's blank, will default to mass_storage from turbo ramdisk
        echo "title=Change USB to MTP" > /tmp/usbstatus.prop
        echo "text=This slot currently set to UMS (mass_storage) mode. Select to change to MTP." >> /tmp/usbstatus.prop
        echo "task=mtp" >> /tmp/usbstatus.prop
    fi
    
    sync
}

setusb()
{
    sync
    check=`cat /system/build.prop | grep 'persist.sys.usb.config='`
    if [ "$check" == "" ]; then
        # build.prop not set [ how nice and clean, must be one of my ROM's :) ]
        echo "### Added by Turbo kernel" >> /system/build.prop
        echo "persist.sys.usb.config=$2,adb" >> /system/build.prop
        echo >> /system/build.prop
    else
        sed -i 's/persist.sys.usb.config=.*/persist.sys.usb.config='$2',adb/g' /system/build.prop
        sed -i 's/sys.usb.config=.*//g' # erase incorrect property if found
    fi
    sync
}

checkals()
{
    sync
    
    if [ -e /data/als_disabled ]; then
        echo "title=Enable ALS" > /tmp/alsstatus.prop
        echo "text=Enable the Ambient Light Sensor for the ROM in this Slot" >> /tmp/alsstatus.prop
        echo "task=enable" >> /tmp/alsstatus.prop
    else
        echo "title=Disable ALS" > /tmp/alsstatus.prop
        echo "text=Disable the Ambient Light Sensor for the ROM in this Slot" >> /tmp/alsstatus.prop
        echo "task=disable" >> /tmp/alsstatus.prop
    fi
    
    sync
}

setals()
{
    sync

    if [ "$2" == "disable" ]; then
        echo "1" > /data/als_disabled
    fi

    if [ "$2" == "enable" ]; then
        rm -f /data/als_disabled
    fi

    sync
}

$1 $1 $2 $3 $4
