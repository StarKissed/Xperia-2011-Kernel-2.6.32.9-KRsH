#!/sbin/sh

#Pulls software out of Android Secure Encrypted Containers (ASEC) 2012/10/09 Giovanni Aneloni

if [ -e /data/deasec_enabled ]; then

LD_LIBRARY_PATH="/system/lib"
PATH="/system/xbin:/system/sbin:/system/bin"

mount -o rw,remount -t rootfs rootfs /

for ASEC in $(find /data/app-asec/ -name '*.asec')
do
    echo "Deasec $ASEC">>/deasec.log
	PKG=$(basename $ASEC|cut -d'-' -f1)
	echo "Package name $PKG">>/deasec.log
	if [ -d /mnt/asec/$PKG*/lib ]
	then
		echo "Relocate libs">>/deasec.log
		find /data/data/$PKG/ -type l -name lib -exec rm {} \;
		cp -r /mnt/asec/$PKG*/lib /data/data/$PKG/
		echo "Fix libs permissions">>/deasec.log
		chown -R system:system /data/data/$PKG/lib
		chmod -R 755 /data/data/$PKG/lib
	fi
	APK=$(pm path $PKG|cut -d':' -f2)
	echo "APK location $APK">>/deasec.log
        cp $APK /data/local/tmp/pkg.apk
        chmod 644 /data/local/tmp/pkg.apk
        pm install -r -f /data/local/tmp/pkg.apk && rm /data/local/tmp/pkg.apk
done

mount -o ro,remount -t rootfs rootfs /

fi