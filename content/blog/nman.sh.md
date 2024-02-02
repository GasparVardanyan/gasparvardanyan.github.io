---
title: "nman.sh"
date: 2023-08-20T07:31:13+04:00
---

Man inside neovim.

Does syntax highlighting, uses nvim's colorscheme and works with links (Shift+K).

```sh
#!/bin/sh

nvim -c "Man $(echo $@)" -c "only" -c "set ft=man"
```

Can be used with **manbrowse.sh**:
```sh
#!/bin/sh

man -k . | awk '{$3="-"; print $0}' |  dmenu -i -l 20 -p 'Search for:' |  awk '{print $2, $1}' | tr -d '()'
```

And this sxhkd config:
```sxhkdrc
super + ctrl + m
    manbrowse.sh | xargs $TERMINAL -n pop-up -g 120x30 nman.sh
```
