---
title: "Managing an Arch Linux workstation. Part 3 - Systemd Nspawn"
date: 2025-11-25T18:02:27+04:00
---


## The basic setup
As I mentioned in [Part 1](../arch-workstation-1/) and [Part 2](../arch-workstation-2/) I use [Systemd Nspawn](https://wiki.archlinux.org/title/Systemd-nspawn) to manage containers. It's like the chroot command, but it is a chroot on steroids.
By using containers, I can keep the host system minimal (currently it has only 684 packages installed) while maintaining separate, well-organized environments for different tasks.

As I described in Part 1 I have these subvolumes:

- **/systems/archlinux-base** \[RO\] - [pacstrapped](https://man.archlinux.org/man/pacstrap.8) basic
installation with base, base-devel and vi packages and zoneinfo, hwclock, locale configurations
- **/systems/archlinux-linux** \[RO\] - a snapshot of archlinux-base with linux, linux-headers and
linux-firmware* packages
- **/systems/archlinux-packaged** \[RO\] - a snapshot of archlinux-linux with packages my basic setup contains
- ...

And the **/containers** subvolume: the subvolume for systemd-nspawn containers.
For the containers the "linux" and the firmware packages aren't needed, because they run on host's kernel with host's firmware drivers, so **/systems/archlinux-base** is a good template to make a container on top of it.

To make the container these are the essential steps:
1. **btrfs subvolume snapshot /systems/archlinux-base /containers/test** - create the container as a snapshot of archlinux-base.
2. **dbus-uuidgen > /containers/test/etc/machine-id** - generate a unique id for the container. If it remains the same as the host's one, systemd will faill in some tasks and container will become unusable until changing the machine-id. dbus-uuidgen generates an id looking random, seems sufficient to just generate one, but it might generate an existing id, or an identical one to hosts's id... I'm not sure how it ensures that the generated id is unique, so I have to make a wrapper script on it to make sure that I'm always using truely unique ids.
3. **mount /dev/nvme0n1p2 -o subvol=/containers/test /var/lib/machines/test --mkdir** - mount the container to the systemd's traditional location so **machinectl** can see and work with it.
4. Edit **/etc/fstab** accordingly and do **systemctl daemon-reload**
5. Edit the machine's config: by default if it's started with machinectl it'll use namespacing and virtual networking. Booting the container in a namespaced environment will use different set of UIDs and GIDs. This is good for security, but if you want to mount file, directory or a device from host to the container, unmatching UIDs and GIDs will cause some problems. If you disable the namespacing later, probably the container will not recognize the old UIDs and GIDs set to files from previous boots and will cause problems.
To disable the user namespacing and the virtual network we have to edit the machine's config: **machinectl edit test** and add:
```ini
[Exec]
PrivateUsers=no

[Network]
VirtualEthernet=no
```
This config gets saved to **/etc/systemd/nspawn/test.nspawn**, you can edit it directly.

6. Boot and upgrade the packages so the systemd versions between the host and the container don't conflict.

## Scripting the configs.
As far as I know there's no way to do scripting in the container's files.
For example I want to mount all the fonts installed on the host to the container to avoid duplicate big packages (ttf-iosevka-nerd is ~1GiB). The file lists of packages can change from version to version, so we need a dynamic solution.

When a container starts with machinectl (either explicitly with the start command or at boot if enabled), it will run the **systemd-nspawn@.service.d** unit passing the container's name as an argument. So editing **/etc/systemd/system/systemd-nspawn@.service.d/override.conf** we can make it to run a bash script which will decide which files from host to mount:
```ini
[Service]
ExecStartPost=/usr/local/etc/nspawn/machine.sh %I
```

From **machine.sh** we can do:
```bash
#!/usr/bin/env bash

MACHINE="$1"

pacman -Ql $(pactree gaspar-meta-fonts -d 1 -l | sed '1d' | paste -s -d ' ') \
	| cut -f 2- -d ' ' \
	| grep -v '/$' \
	| xargs -I _ machinectl bind --mkdir --read-only $MACHINE "_"
```

This will find all dependencies of gaspar-meta-fonts - the fonts I use, read the files lists of that packages and mount them all to the container.


## A better setup

So let's make a more flexible setup for various use cases of containers.
First let's move the font part to a separate script **/usr/local/etc/nspawn/configs/font.sh**:
```bash
pacman -Ql $(pactree gaspar-meta-fonts -d 1 -l | sed '1d' | paste -s -d ' ') \
	| cut -f 2- -d ' ' \
	| grep -v '/$' \
	| xargs -I _ machinectl bind --mkdir --read-only $MACHINE "_"
```
And make some more configs:
- **/usr/local/etc/nspawn/configs/gpu.sh** - for accessing gpus from the container (even cuda works with this setup):
```bash
machinectl bind --mkdir $MACHINE /dev/dri
machinectl bind --mkdir $MACHINE /dev/shm
machinectl bind --mkdir $MACHINE /dev/nvidia0
machinectl bind --mkdir $MACHINE /dev/nvidiactl
machinectl bind --mkdir $MACHINE /dev/nvidia-modeset
machinectl bind --mkdir $MACHINE /dev/nvidia-uvm
machinectl bind --mkdir $MACHINE /dev/nvidia-uvm-tools

systemctl set-property --runtime systemd-nspawn@$MACHINE.service \
	DeviceAllow="/dev/dri/renderD128" \
	DeviceAllow="/dev/dri/renderD129" \
	DeviceAllow="/dev/nvidia0" \
	DeviceAllow="/dev/nvidiactl" \
	DeviceAllow="/dev/nvidia-modeset" \
	DeviceAllow="/dev/nvidia-uvm" \
	DeviceAllow="/dev/nvidia-uvm-tools"
```
- **/usr/local/etc/nspawn/configs/resolv.sh** - after switching the wifi network, this file changes and the container must have an identical one to be able to access the Internet.
```bash
machinectl bind --mkdir --read-only $MACHINE /etc/resolv.conf
```
- **/usr/local/etc/nspawn/configs/mirrorlist.sh** - To use the host's package mirrorlist which can be regenerated with [reflector](https://wiki.archlinux.org/title/Reflector) to get the fastest ones.
```bash
machinectl bind --mkdir --read-only $MACHINE /etc/pacman.d/mirrorlist
```
- **/usr/local/etc/nspawn/configs/desktop.sh** - mount the desktop related stuff: dotfiles, etc
```bash
machinectl bind --mkdir --read-only $MACHINE /desktop
```
- **/usr/local/etc/nspawn/configs/kvm.sh** - to be able to run vms from the container
```bash
machinectl bind --mkdir $MACHINE /dev/kvm
systemctl set-property --runtime systemd-nspawn@$MACHINE.service \
	DeviceAllow="/dev/kvm"
```
- **/usr/local/etc/nspawn/configs/limits.sh** - had your program accidentially crashed your os filling the RAM and forcing you to reboot? Using these limits it will never happen again ))
```bash
systemctl set-property --runtime systemd-nspawn@$MACHINE.service	\
	MemoryHigh=10G							\
	MemoryMax=10G							\
	CPUQuota=1000%
```
- **/usr/local/etc/nspawn/configs/xorg.sh** - running gui apps from the container requires an authentication. First from **~/.xinitrc** I do:
```bash
mkdir /tmp/nspawn
touch /tmp/nspawn/xauth
xauth nextract - "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f /tmp/nspawn/xauth nmerge -
chmod +r /tmp/nspawn/xauth
pactl load-module module-native-protocol-tcp port=4656 listen=0.0.0.0 auth-anonymous=true 2>&1 >/dev/null &
```
As I'm lazy to make a separate script for the audio protocol authentication, I do it along with corg configs. This export xorg's xauth key to /tmp/nspawn/xauth, which will be mounted to the container. Xorg reads the key from thr $XAUTHORITY file, so we also need to automate it. When you log in, the scripts from /etc/profile.d/ [get executed](https://wiki.archlinux.org/title/Bash#Configuration_files). We can make one which sets XAUTHORITY to /tmp/nspawn/xauth.
**/usr/local/etc/nspawn/profile.d/xorg.sh** - inside the host:
```bash
#!/bin/sh

export DISPLAY=:0
export XAUTHORITY=/tmp/nspawn/xauth
export PULSE_SERVER="0.0.0.0:4656"
```
And finally edit the **/usr/local/etc/nspawn/configs/xorg.sh** to mount the neccessary files:
```bash
machinectl bind --mkdir $MACHINE /tmp/.X11-unix
machinectl bind --mkdir --read-only $MACHINE /usr/local/etc/nspawn/profile.d/xorg.sh /etc/profile.d/nspawn_xorg.sh
mkdir /tmp/nspawn
chmod +rwx /tmp/nspawn
machinectl bind --mkdir --read-only $MACHINE /tmp/nspawn
```
- **/usr/local/etc/nspawn/configs/userconfig.sh** - other container specific settings loader:
```bash
if [ -d "/usr/local/etc/nspawn/userconfig/$MACHINE" ] ; then
	find "/usr/local/etc/nspawn/userconfig/$MACHINE" -type f -name "*.sh" \
		| sort -n -t / -k 8n \
		| while read f
		do
			source "$f"
		done
fi
```
This script lists all files inside **/usr/local/etc/nspawn/userconfig/$MACHINE**, sorts numberically and runs them.
For example **/usr/local/etc/nspawn/userconfig/devenv/1-src.sh** mounts personal development specific sources subvolume to /src inside the container:
```bash
machinectl bind --mkdir $MACHINE /rootfs/data/devenv /src
```
- **/usr/local/etc/nspawn/configs/upgrade.sh** - mounts the upgrade scripts to the container:
```bash
if [ -d "/usr/local/etc/nspawn/upgrade/$MACHINE" ] ; then
	machinectl bind --mkdir --read-only $MACHINE "/usr/local/etc/nspawn/upgrade/$MACHINE" /tmp/upgrade
fi
```
For example **/usr/local/etc/nspawn/upgrade/devenv/** contains these files:
```bash
### 1-compiledb@gaspar.sh: ###
#!/usr/bin/env bash

pipx upgrade compiledb

### 2-cpan@gaspar.sh: ###
#!/usr/bin/env bash

source /etc/profile
cpan -u

### 3-paru@gaspar.sh: ###
#!/usr/bin/env bash

paru -Syu

### 4-cppman@gaspar.sh: ###
#!/usr/bin/env bash

pipx upgrade cppman
```

With this bash function these NUM-NAME@USER.sh scripts get called in numberical order from the user USER inside the container:
```bash
upgrade() {
	# TODO:
	# collect the package list of the container(s), download to a directory on
	# host with pacman -Sw, then mount it to the containers and then upgrade
	m="${1#*@}"

	active=false
	machine_active "$m" && active=true

	if [ false = "$active" ]
	then
		sudo machinectl start "$m" && echo nspawn "Booting $m"
	fi

	if wait_machine "$m"
	then
		# FIXME: unmount all mounted packages (e.g. fonts)
		# we unmount mirrorlist because pacman-mirrorlist fails to upgrade

		mirrorlist_mounted=false
		sudo machinectl shell "root@$m" /usr/bin/mount | grep -Fq /etc/pacman.d/mirrorlist && mirrorlist_mounted=true

		sudo machinectl shell "root@$m" /usr/bin/pacman -Syyw
		if [ true = "$mirrorlist_mounted" ]
		then
			sudo machinectl shell "root@$m" /usr/bin/umount /etc/pacman.d/mirrorlist
		fi
		sudo machinectl shell "root@$m" /usr/bin/pacman -Suu
		if [ true = "$mirrorlist_mounted" ]
		then
			sudo machinectl bind --mkdir --read-only "$m" /etc/pacman.d/mirrorlist
		fi
		sudo machinectl shell "root@$m" /usr/bin/pacman -Scc

		if [ -d "/usr/local/etc/nspawn/upgrade/$m" ] ; then
			for f in $(find "/usr/local/etc/nspawn/upgrade/$m" -type f -name "*.sh" \
				| sort -n -t / -k 8n)
			do
				fname=$(basename "$f")
				if echo "$fname" | grep -Fq @
				then
					uname=${fname#*@}
					uname=${uname%%.*}
					host="$uname@$m"
				else
					uname=''
					host="$m"
				fi

				sudo machinectl shell "$host" "/tmp/upgrade/$fname"
			done
		fi
	else
		notify "Failed to upgrade the machine $m"
	fi

	if [ false = "$active" ]
	then
		sudo machinectl poweroff "$m" &&  notify "Powereing off $m"
	fi
}
```

## Configuring the containers.
First I have **/usr/local/etc/nspawn/configpacks/desktop.sh:**
```bash
source /usr/local/etc/nspawn/configs/desktop.sh
source /usr/local/etc/nspawn/configs/font.sh
source /usr/local/etc/nspawn/configs/gpu.sh
source /usr/local/etc/nspawn/configs/xorg.sh
```
And **/usr/local/etc/nspawn/configpacks/essentials.sh:**
```bash
source /usr/local/etc/nspawn/configs/mirrorlist.sh
source /usr/local/etc/nspawn/configs/resolv.sh
source /usr/local/etc/nspawn/configs/upgrade.sh
source /usr/local/etc/nspawn/configs/userconfig.sh
```

These are "config packs" for quick setups.
The **/usr/local/etc/nspawn/machine.sh** which gets called after a container boots now looks for machine specific configs in **/usr/local/etc/nspawn/machines/** and sources them together with the "essentials":
```bash
#!/usr/bin/env bash

MACHINE="$1"
CONF="/usr/local/etc/nspawn/machines/$MACHINE.sh"

if [ -f "$CONF" ] ; then
	source "$CONF"
fi

source /usr/local/etc/nspawn/configpacks/essentials.sh
```

For example **/usr/local/etc/nspawn/machines/work.sh** does:
```bash
source /usr/local/etc/nspawn/configs/limits.sh
source /usr/local/etc/nspawn/configpacks/desktop.sh
```

So now to create a new container, let's name it "hello", I have to follow [the basic setup](#the-basic-setup), create **/usr/local/etc/nspawn/machines/hello.sh** which will include the configs/configpacks I want the container to use, add custom upgrade scripts in **/usr/local/etc/nspawn/upgrade/hello/** and custom container-specific scripts in **/usr/local/etc/nspawn/userconfig/hello/**.

**machinectl start hello** will start the container and **machinectl enable hello** will enable the appropriate systemd unit to boot the container when host boots.

My container configs are available [here](https://github.com/GasparVardanyan/dotfiles/tree/master/nspawn).

The management utility to start/stop a container, run shell or terminal from a container and to upgrade containers is available [here](https://github.com/GasparVardanyan/dotfiles/blob/master/skel/utilsbin/.local/bin/nspawn).

## Package management
configs/desktop.sh mounts /desktop to the container. As described in [Part 2](../arch-workstation-2/) I have multpile gaspar-system-* metapackages. Repo is symlinked to /desktop/repo. So in the container I have to add:
```ini
[gaspar]
SigLevel = Optional TrustAll
Server = file:///desktop/repo
```
to /etc/pacman.conf and install the appropriate metapackage. For example for the devenv container I have **gaspar-system-devenv**:
```PKGBUILD
pkgname=gaspar-system-devenv
pkgver=1
pkgrel=1
arch=('any')
options=('!debug')
groups=('gaspar')
depends=(
	gaspar-meta-git
	gaspar-meta-nvim-devenv
	gaspar-meta-shell
	gaspar-meta-devenv
	gaspar-device-gpu
)

# vim:ft=sh
```

## The magic part
The magic in all of this is that we’re on Linux. What’s the actual difference between the host and the containers? They each live on their own Btrfs subvolume; the host simply provides the kernel and firmware drivers, while the containers do not. By installing the necessary packages inside a container (gaspar-device-*), we can add a GRUB entry for it and boot that container as if it were the host. And according to the [systemd-vmspawn(1)](https://man.archlinux.org/man/systemd-vmspawn.1) manual, we can even run containers as virtual machines via QEMU.
