#!/bin/sh

. ./build.config

JAILHOUSE_DIR=$(pwd)/jailhouse
JAILHOUSE_TOOLS=$JAILHOUSE_DIR/tools
JAILHOUSE_CONF=$JAILHOUSE_DIR/configs/arm64
JAILHOUSE_CMD=$JAILHOUSE_TOOLS/jailhouse
BRIDGE_CONF=$(pwd)/configs/dnsmasq/bridge.conf
INMATE=rpi4-mydemo
INMATE_RAMDISK=$(pwd)/buildroot/output/images/Image

USAGE="$0 <enable|start|status|stop|disable>"

if [ "$(id -u)" -ne 0 ]; then
	echo Must be root
	exit
fi

if [ "$#" -lt 1 ]; then
	echo $USAGE
	exit
fi

case $1 in
	enable)	
		echo Inserting driver...
		insmod $JAILHOUSE_DIR/driver/jailhouse.ko
		echo Enabling jailhouse...
		$JAILHOUSE_CMD enable $JAILHOUSE_CONF/rpi4.cell
		sleep 1
		echo Starting DHCP server...
		dnsmasq --interface=$jailhouse_netshmem_if --bind-interfaces --domain-needed --bogus-priv --dhcp-range="$jailhouse_netshmem_if_low,$jailhouse_netshmem_if_high,12h"
		;;
	start)
		echo Starting cell...
		$JAILHOUSE_CMD cell linux \
			-d $JAILHOUSE_CONF/dts/inmate-rpi4.dtb \
			-c "console=ttyS0,115200" \
			$JAILHOUSE_CONF/$INMATE.cell \
			$INMATE_RAMDISK
		;;
	stop)	
		echo Destroy jailhouse cell...
		$JAILHOUSE_CMD cell destroy 1
		;;
	status)
		$JAILHOUSE_CMD cell list
		;;
	disable)
		echo Disabling jailhouse...
		$JAILHOUSE_CMD disable
		rmmod jailhouse
		pkill dnsmasq
		;;
	*)
		echo $USAGE
		;;
esac

exit 0

