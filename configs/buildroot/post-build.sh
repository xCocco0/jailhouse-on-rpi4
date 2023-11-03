# auto mount debugfs on boot

echo "debugfs     /sys/kernel/debug debugfs defaults 0 0" >> ${TARGET_DIR}/etc/fstab
