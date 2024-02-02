---
title: "Easy Channel List Player"
date: 2022-08-19T01:52:43+04:00
---

```sh
#!/bin/sh

# SHELL SCRIPT TO RANDOMELY PLAY A MUSIC FROM CHANNELS LIST
# HINT: PRESS 'q' TO PLAY THE NEXT MUSIC

l=$(ls ~/.config/ytfzf/subscriptions-* | sed 's/^.*subscriptions-//' | dmenu -p 'list: ' -l 20)

if [ "$l" != '' ]
then
	t=$(mktemp)
	cp ~/.config/ytfzf/subscriptions-"$l" "$t"
	YTFZF_SUBSCRIPTIONS_FILE="$t" ytfzf -cSI -r -l -m
fi
```

```
-> [ ~ ] :: ls .config/ytfzf/
 subscriptions-armmus   subscriptions-classic   subscriptions-dub    subscriptions-rock
 subscriptions-blues    subscriptions-dark      subscriptions-funk   subscriptions-sensual
 subscriptions-chill    subscriptions-deep      subscriptions-mix    subscriptions-synthwave
-> [ ~ ] :: \cat .config/ytfzf/subscriptions-blues
https://yewtu.be/channel/UCYY_YLVWFI_IZ51Eu6x9bgA
https://yewtu.be/channel/UClfiK5XMFRDwEX0aQVdJVog
https://yewtu.be/channel/UCtM8in_qEBSzv47sVVpxbUQ
-> [ ~ ] ::
```
