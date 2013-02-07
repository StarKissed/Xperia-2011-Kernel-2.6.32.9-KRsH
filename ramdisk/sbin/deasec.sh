#!/system/bin/sh

# Pulls software out of Android Secure Encrypted Containers (ASEC)
# Original design - Giovanni Aneloni 2012/10/09 
# Modified by CosmicDan 2013/02/07

#mount -o rw,remount -t rootfs rootfs /
#set -x
#exec >>/deasec.log 2>&1

deasec_proc()
{
    mount -o rw,remount -t rootfs rootfs /
    LD_LIBRARY_PATH="/system/lib"
    PATH="/system/xbin:/system/sbin:/system/bin"
    echo "### Deasec started...">>/deasec.log 2>&1
    for ASEC in $(find /data/app-asec/ -name '*.asec')
    do
        echo "[!] Deasec $ASEC">>/deasec.log 2>&1
        PKG=$(basename $ASEC|cut -d'-' -f1)
        echo "    [i] Package name $PKG">>/deasec.log 2>&1
        if [ -d /mnt/asec/$PKG*/lib ]
        then
            echo "    [i] Relocate libs...">>/deasec.log
              find /data/data/$PKG/ -type l -name lib -exec rm {} \;
              cp -r /mnt/asec/$PKG*/lib /data/data/$PKG/>>/deasec.log 2>&1
            echo "    [i] Fix libs permissions...">>/deasec.log
              chown -R system:system /data/data/$PKG/lib>>/deasec.log 2>&1
              chmod -R 755 /data/data/$PKG/lib>>/deasec.log 2>&1
        fi
        APK=`basename $ASEC | sed "s/.asec//g"`
        echo "    [i] Moving APK to /data/app/$APK.apk">>/deasec.log
          cp /mnt/asec/$PKG*/pkg.apk /data/app/$APK.apk>>/deasec.log 2>&1
          chmod 644 /data/app/$APK.apk>>/deasec.log 2>&1
        echo "    [i] Hacking PackageManager...">>/deasec.log
          sed -i 's/mnt\/asec\/'$APK'\/pkg.apk/data\/app\/'$APK'.apk/g' /data/system/packages.xml
          #sed -i 's/resourcePath=.*zip\" /data\/app\/'$APK'.apk\" /g' /data/system/packages.xml
          sed -i 's/resourcePath=.*zip\" //g' /data/system/packages.xml
          sed -i 's/flags=.*\" ft=/flags=\"0\" ft=/g' /data/system/packages.xml
          sed -i 's/mnt\/asec\/'$APK'\/lib/data\/data\/'$PKG'\/lib/g' /data/system/packages.xml
        echo "    [i] Cleaning up...">>/deasec.log
          rm -rf $ASEC
          umount -l /mnt/asec/$PKG*
    done
    #echo "### Checking for dead ASEC containers...">>/deasec.log
    #cd /data/app-asec/
    #for ASEC in $(ls *.asec)
    #do
    #    PKG=$(basename $ASEC|cut -d'-' -f1)>>/deasec.log 2>&1
    #    PKG_PATH=`su -c '/system/bin/pm list packages -f' system | grep $PKG | sed "s/package://g" | sed "s/=$PKG//g"`>>/deasec.log 2>&1
    #    if [ "`dirname $PKG_PATH`" == "/data/app" ]; then
    #        echo "    /data/app-asec/$ASEC is not longer in use. Deleting...">>/deasec.log
    #        rm -rf /data/app-asec/$ASEC>>/deasec.log 2>&1
    #    fi
    #done
    echo "### Deasec finished">>/deasec.log
    mount -o ro,remount -t rootfs rootfs /
}

if [ -e /data/deasec_enabled ]; then
    deasec_proc
fi
