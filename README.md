# Jailhouse on Raspberry Pi 4B
This repository contains a few useful configuration files that can help setting up the [Jailhouse](https://github.com/siemens/jailhouse) hypervisor on the Raspberry Pi 4B. Some configs have been modified from the [Jailhouse Images](https://github.com/siemens/jailhouse-images) repository while some are based on my personal experience while setting up the board. There are also two helper scripts to setup everything from scratch and to handle the creation of cells.

## Contents

- ``build.sh``

  This is a helper script to perform all the required steps in an easy way. It can get a working a fully system by executing the following steps:

  1) ``build.sh download`` - Clones all the required repositories in the current directory

  2) ``build.sh device_tree`` - Compiles the device trees that are required to perform the memory reservation required by Jailhouse, install them to /boot partition and update the config.txt file
  
  3) ``build.sh arm_trusted_firmware`` - Compile the arm trusted firmware to substitute the default raspberry pi firmware, install it to /boot and update the config.txt file
  
  4) ``build.sh buildroot`` - Use Buildroot to create a fully working Linux ramdisk to run inside Jailhouse

  5) ``build.sh linux`` - Compile the [Jailhouse Linux fork](https://github.com/siemens/linux), copy the final image to /boot and update the config.txt file

  6) ``build.sh jailhouse`` - Compile and install Jailhouse
 
  Please note that operations 2-3-4-5 can be executed in any order, but Jailhouse must be compiled while running the newly built kernel.

- ``build.config``

  This is a configuration file used in the scripts. The actual settings include:
  - ``use_palloc`` - Whether to apply the [Palloc](https://github.com/heechul/palloc) patch to the host and guest kernels (default = n)
  - ``disable_rt`` - Do not apply the Preempt-RT patch to host and guest kernels (default = n)
  - ``jailhouse_largemem`` - Increase the reserved memory size in the device tree by an additional 1GB (default = y)
  - ``disable_dnsmasq`` - Do not run dnsmasq to dynamically assign IPs to the inmates (default = y)
  - ``jailhouse_netshmem_if`` - The name of the network interface that Jailhouse is using (default = eth1)
  - ``jailhouse_netshmem_if_low`` - Specifies the lower address to be assigned to inmates (default = 10.1.1.1)
  - ``jailhouse_netshmem_if_high`` - Specifies the upper address to be assigned to inmates (default = 10.1.1.7)
  
- ``run.sh``

  This is a script to handle the enabling/disable of the hypervisor and the creation/termination of the inmate, this is basically a wrapper for the jailhouse/tools/jailhouse command. Moreover, it starts the DHCP server to assign IPs to inmates. The default inmate is a custom one which uses the additional 1GB in the device tree overlay.

- ``dt/``

  Contains the source files for the device trees
  
- ``buildroot/``

  The configuration files used by Buildroot to build the inmate ramdisk

- ``jailhouse/``

  This contains the description of the modified cell with an additional 1GB of memory
  
- ``linux/``

  This contains the configs for the host linux kernel
