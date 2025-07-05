---
title: "YouTube Mixes in MPV   Part 2"
date: 2025-07-05T07:10:37+04:00
---

So continuing youtube mix support in mpv I've decided to replace my cmus commands
inside dwm with more generic commands to be able to control cmus, any mpv
instance playing a mix or a local playlist.

To control mpv instances I needed to have ipc sockets for each instance, so I
extended the local playlist / mix launcher scripts to use sockets:

play:
```sh
#!/bin/sh

dmenu_embed=""
mpv_embed=""
if [ "$XEMBED" != '' ]
then
	dmenu_embed="-w $XEMBED"
	mpv_embed="-wid=$XEMBED"
fi

l=$(ls ~/.local/share/playlists/*.m3u | sed 's/^.*\.local\/share\/playlists\///;s/\.m3u$//' | dmenu -p 'play: ' -l 20 $dmenu_embed)
if [ "$l" != '' ]
then
	playlist="$HOME/.local/share/playlists/$l.m3u"
	socket="$playlist.socket"
	mpv --fullscreen --loop-playlist=inf --ytdl-format="bestvideo+bestaudio/best" $mpv_embed "$playlist" --input-ipc-server="$socket" --shuffle
	rm "$socket"
fi
```

ytmpv:
```sh
#!/bin/sh

[ ! -d /tmp/ytmpv ] && exit

dmenu_embed=""
mpv_embed=""
if [ "$XEMBED" != '' ]
then
	dmenu_embed="-w $XEMBED"
	mpv_embed="-wid=$XEMBED"
fi

l=$(find /tmp/ytmpv -type f -name '*.m3u' | \sed 's#^/tmp/ytmpv/##;s#\.m3u$##' | dmenu -p 'play: ' -l 20 $dmenu_embed)
if [ "$l" != '' ]
then
	playlist="/tmp/ytmpv/$l.m3u"
	socket="$playlist.socket"
	mpv --fullscreen --loop-playlist=inf --ytdl-format="bestvideo+bestaudio/best" $mpv_embed "$playlist" --input-ipc-server="$socket"
	rm "$socket"
fi
```

Then wrote this buggy shell script (plctrl):
```bash
#!/usr/bin/env bash

YTMPV_DIR="${YTMPV_DIR:-/tmp/ytmpv}"
PLCTRL_SOURCE="${PLCTRL_SOURCE:-/tmp/plctrl}"
PLMAN_DIR="$HOME/.local/share/playlists"

cmd_list_sources()
{
	list=""
	cmus=$(cmus-remote --query 2>/dev/null | grep ^status -m 1 | cut -d ' ' -f 2)
	[[ "$cmus" != '' ]] && list="cmus\n"

	ytmpv=$(find "$YTMPV_DIR" -type s -name '*.socket' | sed -E "s#^$YTMPV_DIR/?#YTMPV: #")
	list="$list$ytmpv\n"

	pl=$(find "$PLMAN_DIR" -type s -name '*.socket' | sed -E "s#^$PLMAN_DIR/?#PLMAN: #")
	list="$list$pl\n"

	echo -e "$list"
}

cmd_select_source()
{
	# TODO: automatically select if only one available source

	list=$(cmd_list_sources)
	echo "list: $list"
	if [[ "$list" != '' ]]
	then
		s=$(echo "$list" | dmenu -p 'plctrl source: ' -l 20)
		[[ "$s" != '' ]] && echo "$s" > "$PLCTRL_SOURCE"
	else
		rm "$PLCTRL_SOURCE"
	fi

	test -f "$PLCTRL_SOURCE"
}

cmd_validate_source()
{
	list=$(cmd_list_sources)
	f=$(cat "$PLCTRL_SOURCE")

	[ -f "$PLCTRL_SOURCE" ] && grep -Fxq "$list" <<< "$f" || return 1
}

cmd_validate()
{
	if ! cmd_validate_source
	then
		if ! cmd_select_source
		then
			return 1
		fi
	fi
	return 0
}

_cmd_mpv()
{
	_s=$(echo "$1" | sed 's/:/\\:/g')
	_c=$2

	echo "$_c" | socat - "$_s"
}

cmd_next()
{
	if cmd_validate
	then
		s=$(cat "$PLCTRL_SOURCE")

		if [[ "$s" = 'cmus' ]]
		then
			cmus-remote -n
		elif [[ "$s" == YTMPV:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$YTMPV_DIR/$s" 'playlist-next'
		elif [[ "$s" == PLMAN:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$PLMAN_DIR/$s" 'playlist-next'
		else
			echo "SS:$s"
		fi
	fi
}

cmd_prev()
{
	if cmd_validate
	then
		s=$(cat "$PLCTRL_SOURCE")

		if [[ "$s" = 'cmus' ]]
		then
			cmus-remote -r
		elif [[ "$s" == YTMPV:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$YTMPV_DIR/$s" 'playlist-prev'
		elif [[ "$s" == PLMAN:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$PLMAN_DIR/$s" 'playlist-prev'
		else
			echo "SS:$s"
		fi
	fi
}

cmd_toggle_play()
{
	if cmd_validate
	then
		s=$(cat "$PLCTRL_SOURCE")

		if [[ "$s" = 'cmus' ]]
		then
			cmus-remote -u
		elif [[ "$s" == YTMPV:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$YTMPV_DIR/$s" 'cycle pause'
		elif [[ "$s" == PLMAN:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$PLMAN_DIR/$s" 'cycle pause'
		else
			echo "SS:$s"
		fi
	fi
}

cmd_stop()
{
	if cmd_validate
	then
		s=$(cat "$PLCTRL_SOURCE")

		if [[ "$s" = 'cmus' ]]
		then
			cmus-remote -s
		elif [[ "$s" == YTMPV:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$YTMPV_DIR/$s" '{ "command": ["set_property", "pause", true] }'
			_cmd_mpv "$YTMPV_DIR/$s" 'seek 0 absolute'
		elif [[ "$s" == PLMAN:\ * ]]
		then
			s="${s#* }"
			_cmd_mpv "$PLMAN_DIR/$s" 'cycle pause'
		else
			echo "SS:$s"
		fi
	fi
}

cmd_optimize()
{
	mv "$1"{,.tmp}

	IFS=''

	cat -- "$1".tmp | while read -r k
	do
		if [[ "$k" =~ ^#.*$ ]]
		then
			echo -E "$k"
		elif grep -q "^https://\(www\.\)\?youtube.com/watch?v=" <<< "$k"
		then
			_k=$(echo "$k" | sed 's#https://\(www\.\)\?youtube.com/watch?v=##')
			f=$(rg --files --no-ignore --maxdepth=1 -L /media/music/music_best/ | rg -- "$_k")
			if [[ $(echo "$f" | wc -l) == 1 ]] && ! [ -z "$f" ]
			then
				echo "$f"
			else
				echo "$k"
			fi
		fi
	done >> "$1"
}

cmd_$1 "$2"
```

The interface to use is:
1. **plctrl select_source** - find active mpv instances via sockets, determine
whether cmus is running and open a dmenu prompt to select the player to control.
2. **plctrl next/prev/play/pause** - control the selected player if any, otherwise
do **select_source** first** - find active mpv instances via sockets, determine
whether cmus is running and open a dmenu prompt to select the player to control.
2. **plctrl next/prev/play/pause** - control the selected player if any, otherwise
do **select_source** first.
3. **plctrl optimize** - I store my local playlists with videos in
/media/music/music_best and name video files with youtube id. This command finds
already downloaded videos and replaces them with local files inside the playlist.
This command is invoked from ytmpv_server.py

And finally remappings in dwm:
```diff
diff --git a/config.h b/config.h
index f65e096..8de9df3 100644
--- a/config.h
+++ b/config.h
@@ -141,7 +141,7 @@ static Key keys[] = {
 	{ MODKEY|ControlMask,                     XK_space,      focusmaster,           { .i    = 0              } },
 	{ MODKEY|ShiftMask,                       XK_space,      togglefloating,        { .i    = 0              } },
 	{ MODKEY|ControlMask|ShiftMask,           XK_space,      togglealwaysontop,     { .i    = 0              } },
-	// { MODKEY|ControlMask,                     XK_p,          togglesticky,          { .i    = 0              } }, // TODO: remap
+	{ MODKEY|AltMask,                         XK_s,          togglesticky,          { .i    = 0              } },
 	{ MODKEY,                                 XK_comma,      focusmon,              { .i    = +1             } },
 	{ MODKEY,                                 XK_period,     focusmon,              { .i    = -1             } },
 	{ MODKEY|ShiftMask,                       XK_comma,      tagmon,                { .i    = +1             } },
@@ -188,6 +188,8 @@ static Key keys[] = {
 	SPAWN_KEY   ( MODKEY|ControlMask,             XK_i,              FlameshotGui         )
 	SPAWN_KEY   ( MODKEY|ControlMask,             XK_o,              CmusStop             )
 	SPAWN_KEY   ( MODKEY|ControlMask|ShiftMask,   XK_i,              MpvPlay              )
+	SPAWN_KEY   ( MODKEY|AltMask,                 XK_u,              MusSelect            )
+	SPAWN_KEY   ( MODKEY|AltMask,                 XK_i,              YtMpv                )
 	SPAWN_KEY   ( 0,                              XK_Print,          FlameshotFull        )
 	SPAWN_KEY   ( ShiftMask,                      XK_Print,          FlameshotGui         )
 	SPAWN_KEY   ( MODKEY,                         XK_backslash,      PassFill             )
diff --git a/spawn_cmds.c b/spawn_cmds.c
index 7c96d47..f3cd3e3 100644
--- a/spawn_cmds.c
+++ b/spawn_cmds.c
@@ -11,8 +11,9 @@ struct {
 	}
 		Terminal,           Dmenu,
 		VolUp,              VolDown,               VolToggle,
-		CmusNext,           CmusPrev,              CmusToggle,         CmusStop,
+		CmusNext,           CmusPrev,              CmusToggle,         CmusStop,           MusSelect,
 		FlameshotGui,       FlameshotFull,
+		YtMpv,
 		MpvPlay,
 		BacklightUp,        BacklightDown,         BacklightMax,       BacklightMid,
 		KbdBrightOn,        KbdBrightOff,
@@ -62,22 +63,27 @@ struct {

 	.CmusPrev = {
 		.args = (const char * []) {
-			"sh", "-c", "cmus-remote -r && dwmstatus", NULL
+			"sh", "-c", "plctrl prev && dwmstatus", NULL
 		}
 	},
 	.CmusNext = {
 		.args = (const char * []) {
-			"sh", "-c", "cmus-remote -n && dwmstatus", NULL
+			"sh", "-c", "plctrl next && dwmstatus", NULL
 		}
 	},
 	.CmusToggle = {
 		.args = (const char * []) {
-			"sh", "-c", "cmus-remote -u && dwmstatus", NULL
+			"sh", "-c", "plctrl toggle_play && dwmstatus", NULL
 		}
 	},
 	.CmusStop = {
 		.args = (const char * []) {
-			"sh", "-c", "cmus-remote -s && dwmstatus", NULL
+			"sh", "-c", "plctrl stop && dwmstatus", NULL
+		}
+	},
+	.MusSelect = {
+		.args = (const char * []) {
+			"sh", "-c", "plctrl select_source && dwmstatus", NULL
 		}
 	},

@@ -92,6 +98,12 @@ struct {
 		}
 	},

+	.YtMpv = {
+		.args = (const char * []) {
+			"sh", "-c", "ytmpv", NULL
+		}
+	},
+
 	.MpvPlay = {
 		.args = (const char * []) {
 			"play", NULL
```

I use u,i,o keys for volume/music control (and other things), so replaced
super+alt+y with super+alt+i (super+ctrl+shift+i opens local playlists) and
mapped super+alt+u to **plctrl select_source**.

The last thing remaining to do is extend plctrl to get playback info and update
dwmstatus to work with it.

... I think I have a couple u,i,o free mappings (with super+alt+...) to add
"toggle repeat" and "shuffle" mappings ...
