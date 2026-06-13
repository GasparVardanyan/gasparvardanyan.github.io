---
title: "Why \"Modern\" IDEs Are Actually a Step Backward"
date: 2026-03-13T21:18:18.353Z
---

First of all, when you close your "modern" IDE, then reopen it and open a
project, what do you get? An empty editor. It doesn't recover the old files,
layouts, and tabs you had before closing the IDE. Yes, it stores the recent
files list, and under the "File" submenu, you have another submenu, "Recent,"
from which you can open your recent files.

But after opening an old file, what do you get? Your cursor is at the
beginning of the file instead of being at the last position where you edited
it. This is absurd. Modern IDEs shouldn't be this clunky regarding simple
yet essential things.

On the other hand, what do you get in Vim or NeoVim? Either you start your
config from scratch and add support for this kind of stuff, or you use a
preconfigured Vim/NeoVim distribution such as LazyVim, which has already been
configured not to act like a dumb piece of brick in these situations. Try
to configure your "modern" IDE or edit the source code and recompile it so
it doesn't act like a brick. Good luck :d

Probably you didn't even notice how easy life can be with the simple
intelligence of your development environment, right? Maybe even now you
can't imagine it. You first need to work in a truly professional development
environment, then try to go back to "modern" IDEs to understand and feel
the difference.

Vim and NeoVim save your cursor locations to registers. These registers
are saved in the cache automatically, so after closing and reopening the
editor, you don't lose them. I have a simple autocmd - in the Vim world,
this is the equivalent of an event listener - which gets executed every
time I open a file, finds my cursor's last position from the registers,
and moves my cursor to that position.

Furthermore, in the Vim world, you can save your session to a file. That session
file consists of simple Vim commands which open the saved windows, buffers,
and tabs exactly as you saved them. I have autocmds to store the session
before closing a project and reload the session after opening a project. To
navigate projects, I use a plugin which simply gives me the ability to save a
directory list, edit that list, and cd into any of them. Right after the cd,
the "project opened autocmd" gets executed. Right before the cd and before
exiting Vim, the "project closed autocmd" gets executed. And that plugin
supports fuzzy finders such as FzfLua and Telescope.

Furthermore, do you remember the magic of fuzzy searching? FzfLua, a great
NeoVim plugin, supports fuzzy searching worktrees of the repo and navigating
between them.

I quickly navigate projects and worktrees without losing the state of my
editor. When I open a project, every window and every tab is in the same
place as I left it, with the same cursor position and the same layout.

Does your IDE allow you to edit the same file in two different splits in
different parts at the same time?
