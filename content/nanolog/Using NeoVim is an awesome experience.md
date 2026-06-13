---
title: "Using NeoVim Is an Awesome Experience"
date: 2026-06-06T19:36:29.933Z
---

There are a lot of plugins covering almost anything you'll need in your
development environment.

When there's no plugin solving your problem, you can manually do it. It's easy!

For example I wanted [IWYU](https://include-what-you-use.org/) integration in NeoVim
and didn't found any plugins for it.  [This](https://github.com/GasparVardanyan/nvconf/blob/v2/lua/modular/autocmds/Clang/iwyu.lua) is how
I integrated IWYU in my NeoVim config, and [these](https://github.com/GasparVardanyan/nvconf/blob/v2/lua/modular/mappings/Clang/iwyu.lua)
are the mappings.

I was using a theme plugin which didn't working with some plugins
I was using, on some places didn't working the way I wanted. I've
[customized](https://github.com/NvChad/base46/pulls/GasparVardanyan) the
plugin manually and now it works as I like.

The repo was inactive and had a good PR... No problem! I merged the PR
directly into my fork.

Sometimes you don't even need to code anything to solve your problem.
I'm using a plugin to manage [treesitters](https://tree-sitter.github.io/tree-sitter/).
Seems it doesn't have an "update all" feature and I wanted to update all
installed treesitters. In its UI in front of every installed treesitter it
shows ✅ and it have "u" mapping to update the "selected" treesitter. To
"select" a treesitter you just navigate to its line.

{{< zoomable-image "/nanolog/2026-06-13-232151_545x753_scrot.png" >}}

This is what I've did: moved the cursor to a ✅ symbol, pressed * and
executed this command:
:%g//norm u
And it updated all of the installed treesitters.

How it worked? Explore the magic yourself 🙂

I use NeoVim primarily for C/C++ development and it have everything I
need. And there are NeoVim integrations for almost anything!!

* Unity: [neovim-unity](https://github.com/walcht/neovim-unity), [nvim-unity](https://github.com/apyra/nvim-unity).
* Unreal Engine: [Unreal.nvim](https://github.com/zadirion/Unreal.nvim), [UnrealDev.nvim](https://github.com/taku25/UnrealDev.nvim).
* Java: [nvim-java](https://github.com/nvim-java/nvim-java), [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls).
* Android: [android-nvim](https://github.com/ariedov/android-nvim).
* Apple ecosystem: [xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim)
* Dot Net: [easy-dotnet.nvim](https://github.com/GustavEikaas/easy-dotnet.nvim).
* CMake: [cmake-tools.nvim](https://github.com/Civitasv/cmake-tools.nvim), universal compiler: [compiler.nvim](https://github.com/Zeioth/compiler.nvim).
* Unit tests: [neotest](https://github.com/nvim-neotest/neotest)
* AI: [avante.nvim](https://github.com/yetone/avante.nvim)
* ...
