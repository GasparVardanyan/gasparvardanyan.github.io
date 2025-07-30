---
title: "The Famous Nvidia Bug"
date: 2025-07-30T11:30:31+04:00
---

There is a [famous nvidia bug](https://forums.developer.nvidia.com/t/external-monitor-freezes-when-using-dedicated-gpu/265406) where the external monitor freezes when doing some nvidia gpu related work: running an app which uses the gpu, closing the app or resizing it's window on X11. The forum post was created on 05.09.2023 and the bug isn't fixed yet...

The workaround I used was to disable and then re-enable the external monitor with xrandr. But it had it's problems: I use dwm and when I have separate tags and layouts on the external monitor, after disabling the monitor all windows go to the primary monitor (where rendering is done with iGPU) and after re-enabling the monitor I have to move windows back, rearrange and set layouts.

Another workaround was to always use dGPU for rendering, but it had it's problem too: qutebrowser (and probably all QtWebEngine based browsers) doesn't do hardware video decoding when the primary gpu is the nvidia one (chrome://gpu shows the related info).

With a little bit of tinkering I've found that instead of disabling and then re-enabling the monitor I can change the resolution to something else and then change back: it unfreezes the monitor keeping all windows in their place and no monitor-related settings (layouts on tags, etc) drop in dwm since monitor isn't being disconnected.

When the external monitor freezes, journalctl shows related logs, so I automated the unfreeze workaround:
```bash
#!/usr/bin/env bash

[ ! -f /usr/local/bin/journalfollow ] && exit

s=0

sudo journalfollow | while read l
do
	echo "$l" | grep -Fq 'NVRM: kdispApplyWarForBug3385499_v03_00: timeout waiting for METHOD_EXEC to IDLE' && s=$(( s + 1 ))
	echo "$l" | grep -Fq 'NVRM: kdispApplyWarForBug3385499_v03_00: timeout waiting for channel state to UNCONNECTED' && s=$(( s + 1 ))

	# echo "$s: $l"

	if [ 2 -eq "$s" ]
	then
		s=0
		if xrandr --listactivemonitors | grep -Fq HDMI-1-0
		then
			xrandr --output HDMI-1-0 --mode 1680x1050
			xrandr --output HDMI-1-0 --mode 1920x1080
			[ -x ~/.fehbg ] && ~/.fehbg
		fi
	fi
done
```

**journalfollow** is another script doing **sudo journalctl -f**. As I always fail to use **chmod +s** and never try to learn it :d, I configured /etc/sudoers to be able to run the script without entering my password. I run this script from ~/.xinitrc.

Now whenever the external monitor freezes this script receives the logs and unfreezes it without losing window states.
