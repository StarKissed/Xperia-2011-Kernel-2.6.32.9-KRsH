#!/sbin/sh

#Pulls software out of Android Secure Encrypted Containers (ASEC) 2012/10/09 Giovanni Aneloni

if [ -e /data/deasec_enabled ]; then

sleep 10

LD_LIBRARY_PATH="/system/lib"
PATH="/system/xbin:/system/sbin:/system/bin"

mount -o rw,remount -t rootfs rootfs /

echo "### Deasec started...">/deasec.log

for ASEC in $(find /data/app-asec/ -name '*.asec')
do
    echo "[!] Deasec $ASEC">>/deasec.log
	PKG=$(basename $ASEC|cut -d'-' -f1)
	echo "    [i] Package name $PKG">>/deasec.log
	if [ -d /mnt/asec/$PKG*/lib ]
	then
		echo "    [i] Relocate libs...">>/deasec.log
		find /data/data/$PKG/ -type l -name lib -exec rm {} \;
		cp -r /mnt/asec/$PKG*/lib /data/data/$PKG/>>/deasec.log
		echo "    [i] Fix libs permissions...">>/deasec.log
		chown -R system:system /data/data/$PKG/lib>>/deasec.log
		chmod -R 755 /data/data/$PKG/lib>>/deasec.log
	fi
    
	APK=$(pm path $PKG|cut -d':' -f2)
	echo "    [i] APK - $APK">>/deasec.log
        cp $APK /data/local/tmp/pkg.apk
        chmod 644 /data/local/tmp/pkg.apk
        pm install -r -f /data/local/tmp/pkg.apk && rm /data/local/tmp/pkg.apk>>/deasec.log
done

echo "### Checking for dead ASEC containers...">>/deasec.log

cd /data/app-asec/
for ASEC in $(ls *.asec)
do
    PKG=$(basename $ASEC|cut -d'-' -f1)
    PKG_PATH=`pm list packages -f | grep $PKG | sed "s/package://g" | sed "s/=$PKG//g"`
    if [ "`dirname $PKG_PATH`" == "/data/app" ]; then
        echo "    /data/app-asec/$ASEC is not longer in use. Deleting...">>/deasec.log
        rm -rf /data/app-asec/$ASEC
    fi
done

echo "### Deasec finished">>/deasec.log

mount -o ro,remount -t rootfs rootfs /

fi