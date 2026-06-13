---
title: "More on Fuzzy Matching. Perl Isn't a \"Write Only\" Language"
date: 2026-02-18T23:29:35.688Z
---

{{< zoomable-image "https://cloud.githubusercontent.com/assets/674812/3480320/3bd2e726-035f-11e4-9e64-db599724c931.gif" >}}
Some people say Perl is a "write-only" language. Is it? Back in the day, I used
the urxvt terminal; it was the best, and every "cool kid" was using it. The
de facto window manager was i3 until Suckless took over with its high-quality,
simple software like the dwm window manager and the st terminal. The Suckless
philosophy is that core functionality should be minimal, with extra features
available as patches. You are supposed to patch the code, fix conflicts,
and recompile. Even for simple configurations, you edit the source code in
plain, understandable C.

urxvt had a great plugin called autocomplete-ALL-the-things. It was a fuzzy
matcher for screen text with several modes to autocomplete words, "WORDS"
(in the Vim sense), text surrounded by braces and quotes, etc. It worked
in the terminal command line, in Vim, or anywhere you typed text. Since
urxvt had a Perl interface, the plugin was written in Perl. It highlighted
matches on the terminal and allowed you to cycle through them to autocomplete
partially typed text.

I was so used to it that working in a terminal without it felt impossible. When
I switched from urxvt to st, I decided to port that plugin. I didn't
have an internet connection that day, and LLMs weren't a thing yet, so
I only had man pages and some PDF books. I edited the plugin to act as
a standalone CLI tool that took info from stdin and printed matches to
stdout. Then I integrated it into st to keep the same experience. This
was my very first experience with Perl. The patch is still available
[here](https://st.suckless.org/patches/autocomplete/).

Years later, I moved to the Alacritty terminal, which is written in Rust. Since
I, the lowly peasant, do not know Rust, I asked the developers to integrate
that functionality. They didn't; they were busy rewriting the world in the
most perfect language ever created.

So, I integrated that functionality directly into NeoVim
instead. At least there, I have the same amazing tool under
my fingers as before. The NeoVim version is available
[here](https://gasparvardanyan.github.io/blog/autocomplete/).

NeoVim uses Lua along with VimScript for configuration. Lua is an easy
language, similar to C or even easier. I learned Lua just by configuring NeoVim.

This is the Linux way. We don't wait for a GUI toggle or a feature request. We
aren't limited by rigid, hardcoded blocks. We patch the source, script the
bridge, and build our own reality.
