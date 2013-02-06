#!/sbin/sh

if [ -e /data/deasec_enabled ]; then
    mount -o rw,remount -t rootfs rootfs /
    echo "### Deasec_clean started...">/deasec.log
    for ASEC in $(find /data/app-asec/ -name '*.asec')
    do
        echo "    [i] Delete - $ASEC">>/deasec.log
        rm -f $ASEC>>/deasec.log
    done
    echo "### Deasec_clean finished">>/deasec.log
    mount -o ro,remount -t rootfs rootfs /
fi