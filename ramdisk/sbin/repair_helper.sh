#!/sbin/busybox sh

start()
{
    echo "#####" > /tmp/turbo_repair.log
    echo "Turbo Repair started" >> /tmp/turbo_repair.log
    date >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
    echo " " >> /tmp/turbo_repair.log
}

repairsd()
{
    umount -l /dev/block/mmcblk0p1
    umount -l /dev/block/mmcblk0p2
    if   [ "$2" == "1" ]; then
        echo " " >> /tmp/turbo_repair.log
        mount -o ro /dev/block/mmcblk0p1 /sdcard
        sdcard_test=`busybox mount | busybox grep '/sdcard'`
        sdcard_test2=`busybox mount | busybox grep '/sdcard' | busybox sed "s/ext2//g"`
        umount -l /dev/block/mmcblk0p1
        if [ "$sdcard_test" != "$sdcard_test2" ]; then
            # ext2
            echo "### About to run e2fsck on microSD ext2 partition... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            e2fsck -p -f -v /dev/block/mmcblk0p1 >> /tmp/turbo_repair.log
        else
            # vfat assumed
            echo "### About to run fsck_msdos on microSD FAT32 partition... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            fsck_msdos -y /dev/block/mmcblk0p1 >> /tmp/turbo_repair.log
        fi
    elif [ "$2" == "2" ]; then
        echo " " >> /tmp/turbo_repair.log
        if [ -e /dev/block/mmcblk0p2 ]; then
            echo "### About to run e2fsck on microSD sd-ext partition... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            e2fsck -p -f -v /dev/block/mmcblk0p2 >> /tmp/turbo_repair.log
        else
            echo "### Skipped e2fsck on microSD sd-ext partition (not found) " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
        fi
    fi
}

fixpermissions()
{
    umount -l /dev/block/mmcblk0p1
    umount -l /dev/block/mmcblk0p2
    mount -o rw /dev/block/mmcblk0p1 /sdcard
    umount /data
    umount /system
    echo " " >> /tmp/turbo_repair.log
    if [ "$2" == "1" ]; then
        echo "### About to repair permissions for Internal system... " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
        mount -t yaffs2 -o rw /dev/block/mtdblock0 /system >> /tmp/turbo_repair.log
        mount -t yaffs2 -o rw /dev/block/mtdblock1 /data >> /tmp/turbo_repair.log
        if [ -e /system/etc/init.d/11link2sd ]; then 
            echo "### Link2SD installation detected, mounting..."
            /sbin/sh /system/etc/init.d/11link2sd
        elif [ -e /dev/block/mmcblk0p2 ]; then
            echo "### sd-ext partition detected, mounting..."
            mount -o rw /dev/block/mmcblk0p2 /sd-ext
        fi
        /sbin/fix_permissions >> /tmp/turbo_repair.log
    else
        if [ -e /sdcard/turbo/userdata$2.ext2.img ]; then
            echo "### About to repair permissions for Slot $2... " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
            mount -t ext2 -o rw,loop,noatime,nosuid,nodev  /sdcard/turbo/system$2.ext2.img  /system >> /tmp/turbo_repair.log
            mount -t ext2 -o rw,loop,noatime,nosuid,nodev  /sdcard/turbo/userdata$2.ext2.img  /data >> /tmp/turbo_repair.log
            if [ -e /system/etc/init.d/11link2sd ]; then
                echo "### Link2SD installation detected, mounting..."
                /sbin/sh /system/etc/init.d/11link2sd
            elif [ -e /dev/block/mmcblk0p2 ]; then
                echo "### sd-ext partition detected, mounting..."
                mount -o rw /dev/block/mmcblk0p2 /sd-ext
            fi
            /sbin/fix_permissions >> /tmp/turbo_repair.log
        else
            echo "### Slot $2 has no userdata image, fix permissions skipped. " >> /tmp/turbo_repair.log
            echo "###" >> /tmp/turbo_repair.log
        fi
    fi
    umount -l /dev/block/mmcblk0p1
    umount -l /dev/block/mmcblk0p2
    umount /data
    umount /system
}

repairslot()
{
    umount -l /dev/block/mmcblk0p1
    umount -l /dev/block/mmcblk0p2
    umount /data
    umount /system
    mount -o rw /dev/block/mmcblk0p1 /sdcard
    echo " " >> /tmp/turbo_repair.log
    if [ -e /sdcard/turbo/$3$2.ext2.img ]; then
        echo "### About to run e2fsck on $3 partition for Slot $2... " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
        e2fsck -p -f -v /sdcard/turbo/$3$2.ext2.img >> /tmp/turbo_repair.log
    else
        echo "### Slot $2 has no $3 image, e2fsck skipped. " >> /tmp/turbo_repair.log
        echo "###" >> /tmp/turbo_repair.log
    fi
}

finish()
{
    echo " " >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
    echo "Turbo Repair finished" >> /tmp/turbo_repair.log
    date >> /tmp/turbo_repair.log
    echo "#####" >> /tmp/turbo_repair.log
}

copylog()
{
    umount -l /dev/block/mmcblk0p1
    mount -o rw /dev/block/mmcblk0p1 /sdcard
    cp -f /tmp/turbo_repair.log /sdcard/turbo_repair.log
    umount -l /dev/block/mmcblk0p1
    mount -o rw /dev/block/mmcblk0p1 /sdcard
}

$1 $1 $2 $3

