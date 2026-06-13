---
title: "Filesystem Version Control: A Better Way to Manage a Linux System"
date: 2026-02-17T22:21:24.990Z
---

Have you ever accidentally deleted a folder and lost important data? Or an
OS upgrade broke your system and you were forced to reinstall it? Or one of
your partitions got full while others still had free space?

When you install a Linux distro, it is not always obvious how much space
/home or /root will need in the future. If you choose the wrong size, you
have to resize partitions later, which is annoying.

Btrfs solves these problems. With Btrfs, you format your whole drive as a
single partition (and a small EFI partition for UEFI). You organize your
data in subvolumes. You don't choose a fixed size for each subvolume -
they just take as much space as they need from the drive.

Creating a subvolume is simple:
btrfs subvolume create /path/to/subvol

You mount them like regular partitions:
```bash
mount /dev/$DISK -o subvol=/path/to/subvol /mount/path
```

Btrfs also lets you backup data easily with snapshots:
```bash
btrfs subvolume snapshot -r /path/to/subvol /path/to/new/snapshot
```

Initially, these snapshots only copy the metadata, not the actual data. After
snapshotting a 100GB subvolume, you might only use ~1KB of extra space. The
metadata keeps "pointers" to the blocks of your files. When you update a
big file that exists in multiple subvolumes, only the updated blocks get
duplicated. This results in very small space usage increase.

If your system breaks, you can replace the broken subvolume with a snapshot
of the last working state. You don't even need a live-USB if you keep a small
rescue system - just snapshot your initial system after install and make it
bootable. Some tools even allow automated snapshots of the base system and
let you boot directly into them.

Another option is ZFS, which is very powerful. It is less common on Linux
because of license issues, so it requires more manual work to setup. In
fact, Btrfs was created as a result of those licensing issues to give Linux
a native filesystem with similar features.

[This](/blog/arch-workstation-1/) is how I organize my system with Btrfs.
