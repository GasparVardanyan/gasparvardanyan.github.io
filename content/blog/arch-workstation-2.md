---
title: "Managing an Arch Linux workstation. Part 2 - Pacman"
date: 2025-11-24T21:45:13+04:00
---

Have you ever wanted to clean up your linux workstation from unneeded packages?

First you have to list them all and see which one is needed and which one already doesn't, right? And what you typically see trying to list all installed packages is a big mess. Even if you list only the explicitly installed packages, not the ones which are installed as dependencies, you see a very big list of packages, some of which are system packages (intel igpu driver for example) and it's very confusing to decide which one is really needed. Maintaining a system like this is very frustrating and painful.

To solve this problem I decided to take a benefit from Arch's metapackages. Metapackages in Arch Linux (and probably in other distributions too) are just empty packages carying a list of dependencies.

The greatest package manager: Arch's Pacman uses files called [PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD) to describe packages. I've splited the packages I use to metapackages, each one containing a list of packages of a specific category as dependencies.

So the PKGBUILD of the package **gaspar-meta-fonts** currently looks like:
```PKGBUILD
pkgname=gaspar-meta-fonts
pkgver=1
pkgrel=2
arch=('any')
options=('!debug')
groups=('gaspar')
depends=(
	ttf-ibm-plex
	ttf-ibmplex-mono-nerd
	ttf-iosevka-nerd
	noto-fonts-emoji
	otf-font-awesome
)

# vim:ft=sh
```

There are a couple of **gaspar-meta-\*** packages:
- gaspar-meta-arch
- gaspar-meta-archdrive
- gaspar-meta-base
- gaspar-meta-desktoptools
- gaspar-meta-devenv
- gaspar-meta-fonts
- gaspar-meta-git
- gaspar-meta-linux
- gaspar-meta-media
- gaspar-meta-network
- gaspar-meta-nvim
- gaspar-meta-nvim-devenv
- gaspar-meta-nvim-work
- gaspar-meta-shell
- gaspar-meta-website
- gaspar-meta-work

gaspar-meta-git for example contains the packages needed for working with git as dependencies:
```PKGBUILD
pkgname=gaspar-meta-git
pkgver=1
pkgrel=2
arch=('any')
options=('!debug')
groups=('gaspar')
depends=(
	git
	git-delta
	lazygit
	less
	neovim
	openssh
)

# vim:ft=sh
```

Also there are **gaspar-device-\*** and **gaspar-device-\*-gpu** packages containing the device specific packages as dependencies.

For example **gaspar-device-g16_7630** contains these dependencies:
alsa-firmware, alsa-plugins, alsa-utils, acpi, acpi_call, tlp, scx-scheds, smartmontools, ethtool, gaspar-device-g16_7630-gpu, intel-ucode, libsmbios, nvidia-open, sof-firmware, thermald.

And **gaspar-device-g16_7630-gpu** contains these dependencies:	intel-gpu-tools, intel-media-driver, libva, libva-utils, libvdpau, libvdpau-va-gl, mesa, mesa-utils, nvidia-prime, nvidia-utils, nvtop, opencl-nvidia, vdpauinfo, vpl-gpu-rt, vulkan-headers, vulkan-icd-loader, vulkan-intel, vulkan-mesa-layers, vulkan-tools.

As you can see the gpu firmware package **nvidia-open** is in the device package, the gpu one contains the userspace packaged required to work with gpu.
This is because I use the second one in the host and in the containers where I want to work with gpus too, but the firmware package needs to be installed only on host.

Pacman's packages have this great feature: I add **provides=('gaspar-device-gpu')** to device gpu specific packages and whenevet I install **gaspar-device-gpu** either explicitly or as a dependency, pacman provides the list of all packages providing that package and asks me to choose which one I want to install.

I use Systemd Nspawn containers, each container uses different set of metapackages. To manage the container and host metapackages I've added another group of metapackages:
- gaspar-system-devenv - this contains the metapackages used for personal development projects as dependencies
- gaspar-system-odyssey - this one is for the host (I've called my host **odyssey**)
- gaspar-system-website - this container was dedicated for thes website, but now I edit this website in devenv
- gaspar-system-work - and this one is for work

For example gaspar-system-odyssey looks like:
```PKGBUILD
pkgname=gaspar-system-odyssey
pkgver=1
pkgrel=9
arch=('any')
options=('!debug')
groups=('gaspar')
depends=(
	gaspar-meta-arch
	gaspar-meta-base
	gaspar-meta-desktoptools # TODO: review
	gaspar-meta-fonts
	gaspar-meta-git
	gaspar-meta-linux
	gaspar-meta-media
	gaspar-meta-network
	gaspar-meta-nvim
	gaspar-meta-shell
	gaspar-device
	gaspar-device-gpu
)

# vim:ft=sh
```

Whenever I need to install my setup from scratch I install this package, which asks me to choose the appropriate gaspar-device and gaspar-device-gpu packages for the device.

I keep these metapackages [in my dotfiles](https://github.com/GasparVardanyan/dotfiles/tree/master/repo). I usually clone my dotfiles in /desktop/dotfiles and make a symlink of my repo directory from my dotfiles to /desktop/repo and add this to **/etc/pacman.conf**:
```ini
[gaspar]
SigLevel = Optional TrustAll
Server = file:///desktop/repo
```

Then updating the repo cache with **pacman -Syy** I have access to this repo.

And my system looks very clean:
```
-> [ ~ ] :: pacman -Qe # the explicitly installed packages
gaspar-system-odyssey 1-9
-> [ ~ ] :: pacman -Qi gaspar-system-odyssey
Name            : gaspar-system-odyssey
Version         : 1-9
Description     : None
Architecture    : any
URL             : None
Licenses        : None
Groups          : gaspar
Provides        : None
Depends On      : gaspar-meta-arch  gaspar-meta-base  gaspar-meta-desktoptools  gaspar-meta-fonts
				  gaspar-meta-git  gaspar-meta-linux  gaspar-meta-media  gaspar-meta-network
				  gaspar-meta-nvim  gaspar-meta-shell  gaspar-device  gaspar-device-gpu
Optional Deps   : None
Required By     : None
Optional For    : None
Conflicts With  : None
Replaces        : None
Installed Size  : 0.00 B
Packager        : Unknown Packager
Build Date      : Sun 09 Nov 2025 03:46:15 AM +04
Install Date    : Sun 09 Nov 2025 03:48:40 AM +04
Install Reason  : Explicitly installed
Install Script  : No
Validated By    : SHA-256 Sum

-> [ ~ ] :: pacman -Qi gaspar-meta-arch
Name            : gaspar-meta-arch
Version         : 1-4
Description     : None
Architecture    : any
URL             : None
Licenses        : None
Groups          : gaspar
Provides        : None
Depends On      : arch-wiki-docs  arch-wiki-lite  archlinux-contrib  devtools  dialog  pacman-contrib
				  pkgfile  reflector
Optional Deps   : None
Required By     : gaspar-system-odyssey
Optional For    : None
Conflicts With  : None
Replaces        : None
Installed Size  : 0.00 B
Packager        : Unknown Packager
Build Date      : Fri 07 Nov 2025 09:09:06 PM +04
Install Date    : Fri 07 Nov 2025 09:16:55 PM +04
Install Reason  : Installed as a dependency for another package
Install Script  : No
Validated By    : SHA-256 Sum

-> [ ~ ] ::
```

In the next part I'll describe the Systemd Nspawn usage.
