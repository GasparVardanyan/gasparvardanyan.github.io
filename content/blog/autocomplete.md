---
title: "Autocomplete"
date: 2025-08-22T18:30:09+04:00
---

Back in the day [urxvt](https://software.schmorp.de/pkg/rxvt-unicode.html) was one of the best terminals. urxvt gives a perl interface for writing extensions. One of the best extensions available for urxvt was [autocomplete-ALL-the-things](https://github.com/Vifon/autocomplete-ALL-the-things).
![demo](https://cloud.githubusercontent.com/assets/674812/3480320/3bd2e726-035f-11e4-9e64-db599724c931.gif)
autocomplete-ALL-the-things is completing text based on the text visible on the screen. It supports multiple methods of text matching:
* `aAtt:word-complete` -- classical prefix-based completion for words
* `aAtt:WORD-complete` -- completion for WORDS (in the Vim meaning)
* `aAtt:fuzzy-word-complete` -- fuzzy completion for words
* `aAtt:fuzzy-WORD-complete` -- fuzzy completion for WORDS
* `aAtt:fuzzy-complete` -- fuzzy completion for arbitrary strings
* `aAtt:suffix-complete` -- fuzzy completion for suffixes, disrespecting
  prefixes of both completion and given strings
* `aAtt:surround-complete` -- fuzzy completion for surrounded by quotes or
  braces strings, excluding surrounding.

When I was using [st](https://st.suckless.org/), I've edited the perl extension of urxvt to work as an independent script. It was taking screen text from stdin, cursor position and the wanted matching method from cli parameters and giving the matches and their positions to stdout. Then I patched st to work with that script. The patch is available [here](https://st.suckless.org/patches/autocomplete/).

Then I switched to [alacritty](https://github.com/alacritty/alacritty). It's written in the safest language, whose knowledge I don't have at all. I asked developers to implement this feature, but they were busy rewriting The World in God's language.

I use NeoVim and I'm a little familiar with Lua, so I decided to write a NeoVim plugin to support this script.

It was a simple, small Lua script:
```lua
local ACMPL = {
	WORD         =  "word-complete"        ,
	WWORD        =  "WORD-complete"        ,
	FUZZY_WORD   =  "fuzzy-word-complete"  ,
	FUZZY_WWORD  =  "fuzzy-WORD-complete"  ,
	FUZZY        =  "fuzzy-complete"       ,
	SUFFIX       =  "suffix-complete"      ,
	SURROUND     =  "surround-complete"    ,
}

local function complete (action)
	local win = vim.api.nvim_get_current_win ()
	local buf = vim.api.nvim_win_get_buf (win)

	local first = vim.fn.line ("w0")
	local last = vim.fn.line ("w$")

	local lines = vim.api.nvim_buf_get_lines (buf, first - 1, last, false)

	local pos = vim.api.nvim_win_get_cursor (win)
	local cur_row_buf, cur_col = pos [1], pos [2]

	local cur_row_file = cur_row_buf - first

	local completions = vim.fn.systemlist (
		"acmpl " .. action .. " " .. cur_row_file .. " " .. cur_col,
		lines
	)

	local targetlen = completions [1]:len ()

	local matches = { completions [1] }
	for i = 2, #completions, 4 do
		table.insert (matches, completions [i])
	end

	vim.fn.complete (vim.fn.col (".") - targetlen, matches)
end

vim.keymap.set ("i", "<M-C-/>", function () complete (ACMPL.WORD) end)
vim.keymap.set ("i", "<M-C-.>", function () complete (ACMPL.FUZZY_WORD) end)
vim.keymap.set ("i", "<M-C-,>", function () complete (ACMPL.FUZZY) end)
vim.keymap.set ("i", "<M-C-'>", function () complete (ACMPL.SUFFIX) end)
vim.keymap.set ("i", "<M-C-;>", function () complete (ACMPL.SURROUND) end)
vim.keymap.set ("i", "<M-C-]>", function () complete (ACMPL.WWORD) end)
vim.keymap.set ("i", "<M-Esc>", function () complete (ACMPL.FUZZY_WWORD) end)
-- TODO: implement an undo mapping
```

Unfortunately **vim.fn.complete** works only in the **insert** mode, I want this
functionality to be available in the **terminal** mode too. But at least I have
this great weapon in my arsenal again ))

The perl script is available [here](../acmpl).
