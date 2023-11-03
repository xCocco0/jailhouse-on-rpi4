all: dtbos

dtbos: jailhouse.dtbo aliases.dtbo jailhousebig.dtbo

%.dtbo: %.dts
	dtc -O dtb -b 0 -@ $< -o $@

install: dtbos
	cp *.dtbo /boot/overlays

clean:
	rm *.dtbo

.PHONY: install clean
