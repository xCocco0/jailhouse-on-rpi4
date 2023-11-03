#!/bin/bash


source ./build.config

USAGE="Usage: $0 <TARGET|clean|distclean>"
USAGE_DETAILED="\n
TARGET must be:\n
- <download>\n
\t clone all the required repositories\n
- <device_tree>\n
\t compile the device tree overlays and copy them to /boot\n
- <arm_trusted_firmware>\n
\t compile the arm trusted firmware, copy to /boot and update config.txt\n
- <linux>\n
\t compile the jailhouse patched kernel and install modules\n
- <buildroot>\n
\t compile the ramdisk of the inmate and copy to root directory\n
- <jailhouse>\n
\t compile jailhouse and install the driver to /lib/modules\n
\t This must be done while running the newly compiled kernel\n
"


if [ "$#" -lt 1 ]; then
	echo "Too few parameters"
	echo $USAGE
	echo -e $USAGE_DETAILED
	exit 1
fi

checksudo() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "This operation requires root privileges"
		echo "  sudo $0"
		exit 1
	fi
}

checkfiles() {

	if [ -d "./arm_trusted_firmware" ] && [ -d "./linux" ] && [ -d "./jailhouse" ] && [ -d "./buildroot" ]; then
		return 0
	else
		echo "You need to clone repositories first"
		echo "  $0 download"
		exit 1
	fi
}

checkkernel() {

	if uname -r | grep -q "jailhouse" ; then
		return 0
	else
		echo "Please boot into the jailhouse enabled kernel"
		echo "  sudo $0 linux"
		echo "  sudo reboot"
		exit 1
	fi
}

case $1 in
	download)
		git clone https://github.com/ARM-software/arm-trusted-firmware arm_trusted_firmware
		if [ "$disable_rt" == "y" ]; then
			git clone https://github.com/siemens/linux -b jailhouse-enabling/5.15 linux
		else
			git clone https://github.com/siemens/linux -b jailhouse-enabling/5.15-rt linux
		fi
		git clone https://github.com/siemens/jailhouse -b next jailhouse
		git clone https://gitlab.com/buildroot.org/buildroot.git buildroot
		[ "$use_palloc" == "y" ] && git clone https://github.com/heechul/palloc palloc
		# TODO: add check if directories already exist
		;;
	device_tree)
		checksudo
		cd ./dt
		make
		make install
		if [ "$jailhouse_largemem" == n ]; then
			echo "dtoverlay=jailhouse" >> /boot/config.txt
		else
			echo "dtoverlay=jailhousebig" >> /boot/config.txt
		fi
		echo "dtoverlay=aliases" >> /boot/config.txt
		;;
	arm_trusted_firmware)
		checkfiles
		checksudo
		cd arm_trusted_firmware
		make PLAT=rpi4 bl31 -j$(nproc)
		cp ./build/rpi4/release/bl31.bin /boot/bl31.bin
		echo "armstub=bl31.bin" >> /boot/config.txt
		;;
	linux)
		checkfiles
		checksudo
		cd linux
		[ "$use_palloc" == "y" ] && patch -N -p1 < ../palloc/palloc-5.15.patch
		cp ../configs/linux/rpi4jailhouse_defconfig ./arch/arm64/configs/
		make rpi4jailhouse_defconfig
		make -j$(nproc)
		make modules_install
		cp ./arch/arm64/boot/Image /boot/kernel5.15jailhouse
		echo "kernel=kernel5.15jailhouse" >> /boot/config.txt
		echo "$0: Please reboot to load into the new kernel"
		;;
	buildroot)
		checkfiles
		checksudo
		cd buildroot
		mkdir ./jailhouse
		cp ../configs/buildroot/{pi_user_table.txt,post-build.sh,rpi4_inmate_defconfig} ./jailhouse/
		cp ../configs/buildroot/raspberrypi4jailhouse_br_defconfig ./configs/
		if [ "$use_palloc" == "y" ]; then
			cp ../palloc/palloc-5.15.patch ./jailhouse/
		else
			sed -E -i"" "s/(BR2_LINUX_KERNEL_PATCH)/#\1/g" ./configs/buildroot/raspberrypi4jailhouse_br_defconfig
		fi
		if [ "$disable_rt" == "y" ]; then
			sed -E -i"" "s/(jailhouse-enabling\/[0-9\.])*-rt/\1/g" ./jailhouse/raspberrypi4jailhouse_br_defconfig
		fi
		make raspberrypi4jailhouse_br_defconfig
		utils/brmake -j2
		;;
	jailhouse)
		checkfiles
		checksudo
		checkkernel
		cd jailhouse
		cp ../configs/jailhouse/rpi4-mydemo.c configs/arm64/
		make
		make install
		if [ ! "$disable_dnsmasq" == "n" ]; then
			sed -E "s/<ifname>/$jailhouse_netshmem_if/g" ../configs/jailhouse/netshmem_if.template | sed -E "s/<iflow>/$jailhouse_netshmem_if_low/g" > /etc/network/interfaces.d/$jailhouse_netshmem_if
		fi
		;;
	clean)
		checkfiles
		cd jailhouse
		make clean
		cd ../buildroot
		make clean
		cd ../linux
		make clean
		cd ../arm_trusted_firmware
		make clean
		cd ../dt
		make clean
		;;
	distclean)
		rm -rf jailhouse/ buildroot/ linux/ palloc/ arm_trusted_firmware/
		rm -f ./dt/*.dtbo
		;;
	*)
		echo "$0: Invalid option '$1'"
		echo $USAGE
		echo -e $USAGE_DETAILED
		exit 1
		;;
esac

echo "$0: Completed"

exit 0
