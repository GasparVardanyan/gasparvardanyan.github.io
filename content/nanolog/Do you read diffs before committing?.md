---
title: "Do You Read Diffs Before Committing?"
date: 2026-06-14T17:45:03+04:00
---

Do you read diffs before committing?  If no, maybe because
it's not a great experience reading plain diff in terminal?
[Delta](https://dandavison.github.io/delta/) makes diffs more readable as
it does in the "Staged changes" window in this screensot:
{{< zoomable-image "/nanolog/2026-06-14-170627_1920x1080_scrot.png" >}}

I use delta in [LazyGit](https://github.com/jesseduffield/lazygit) (the rest
of the git related stuff in the screenshot). Two separate programs doing
different things "mixed" together. LazyGit is a TUI wrapper on git. It shows
changed files, whether they are staged or not (as in the "Files" window in this
screenshot), worktrees, branches and the diff, helps with staging/unstaging by
hunks, merging, rebasing, etc. By default LazyGit displays plain git diff. You
can configure git to use Delta as diff pager. This way both LazyGit and the
"git diff" command use Delta to display the diff.

Furthermore I use lazygit inside NeoVim. When I want to commit and push
changes I open lazygit with "<space>gl", check the diff, fix things if
necessary, stage files, commit and push from LazyGit.

NeoVim developers don't have to worry about git support. When git support
(or something else) is broken, other IDEs can give the priority to other
things and delay the fix. NeoVim cares only about editing the text. LazyGit
and Delta are separate projects, they don't stop each other.

Furthermore in NeoVim world there are a lot of great plugins making git easier.

A lot of the times you have to jump from one changed file to another to do
modifications. [FzfLua](https://github.com/ibhagwan/fzf-lua) - a generic fuzzy
matcher - makes this process very easy. You can fuzzy-find the changed git
files, open the necessary one or add all of them to quickfix list and review
them one by one:
{{< zoomable-image "/nanolog/2026-06-14-173151_1920x1080_scrot.png" >}}
It also helps fuzzy-navigating git
worktrees:
{{< zoomable-image "/nanolog/2026-06-14-173218_1920x1080_scrot.png" >}}

Then comes [GitSigns](https://github.com/lewis6991/gitsigns.nvim). It helps
to see the status of each line (appended, removed, changed), quickly view the
diff of the current hunk, navigate between hunks, undo hunks, stage/unstage
hunks, etc:
{{< zoomable-image "/nanolog/2026-06-14-173328_968x488_scrot.png" >}}

Both FzfLua and LazyGit use Delta to display the diff. They don't have to
worry about making the diff readable - there's already a good software which
does it and does it well, so they just use it.

Then there's another NeoVim plugin -
[DiffView](https://github.com/sindrets/diffview.nvim) - which helps working
with diffs and merge conflicts, viewing individual file git history and much
more:
{{< zoomable-image "/nanolog/2026-06-14-173705_1920x1080_scrot.png" >}}

🔥🔥 Using NeoVim is an awesome experience 🔥🔥
