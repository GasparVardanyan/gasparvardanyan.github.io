---
title: "Another Reason Why NeoVim Is Superior to \"Modern\" IDEs."
date: 2026-07-11T07:03:05+04:00
---

In IDEs, things like code completion and language-specific features are handled
by language servers. The IDE sends the source files to the language server
and asks for the information it needs. For example, when you "control-click"
on a class name, the IDE queries the language server for its definition,
gets the file and line number, and takes you there.

Most language servers support "code actions". For instance, if you include
a C++ header but never use it, the language server can both warn you about
the unused include and offer a code action to remove it automatically.

On the other hand, many linters only produce warnings without any
corresponding code actions. In "modern" IDEs, that's usually all you get. So
when clang-tidy tells you "variable 'x' of type 'int' can be declared 'const'
[misc-const-correctness]", you still have to type the const yourself.

NeoVim is different - you're free to do whatever you want, and you have deep
access to everything through Lua. I'm now building a custom language server
that reads linter diagnostics and generates suitable code actions for them. I
just finished the action for the clang-tidy const-correctness warning.

It solves a very small problem: instead of typing const by hand, I open the
code actions menu and pick the one that adds it automatically. Honestly,
in this case the time saved is tiny.

But the foundation is already there, so I can easily add more code actions
for other diagnostics. Once I have a handful of them - each fixing a minor
annoyance with a quick key combination - the overall experience will be much
smoother than fixing every warning manually.

## Update

It's already a plugin and supports a couple code actions:

{{< zoomable-image "/nanolog/diactions.gif" >}}

The plugin is available
[here](https://github.com/GasparVardanyan/diactions.nvim).
