#!/sbin/sh

#Pulls software out of Android Secure Encrypted Containers (ASEC) 2012/10/09 Giovanni Aneloni

if [ -e /data/deasec_enabled ]; then

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
	echo "    [i] New APK location - $APK">>/deasec.log
        cp $APK /data/local/tmp/pkg.apk
        chmod 644 /data/local/tmp/pkg.apk
        pm install -r -f /data/local/tmp/pkg.apk && rm /data/local/tmp/pkg.apk>>/deasec.log
    # Skip this and let Android clean up when it sees fit. Causes apps disappearing in some cases when phone crashes/bootloops
    #echo "    [i] Delete - $ASEC">>/deasec.log
    #    rm -f $ASEC>>/deasec.log
done

echo "### Deasec finished">>/deasec.log

mount -o ro,remount -t rootfs rootfs /

fi