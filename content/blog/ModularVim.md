---
title: "ModularVim"
date: 2025-07-06T18:00:11+04:00
---

# ModularVim

Modular NeoVim configuration written by a non lua/nvim master for non lua/nvim
masters. So simple **even a caveman** can get started.
Intended to be both beginner friendly and a complete IDE.

https://github.com/GasparVardanyan/ModularVim

## Design goals
There are a lot of great NeoVim distributions and using a distribution is a
great place to get started with NeoVim. But whenever you try to take a small
piece from a distribution and bring to your own setup, for example a setup for
a single plugin, you see how everything is tied together and sometimes it becomes
very complicated to understand what you have to take, and what not to take.

The main design goal of ModularVim is to keep everything as much separated from
each other as possible. Plugins are grouped into 'Modules'. Every Module
consists of plugin specs and 'ModuleActions'. Every plugin spec is
written in it's specific file. ModuleActions are used to load mappings for
example whenever the corresponding plugins are loaded.
This way we can have dap mappings for example independent of telescope and load
the dap-telescope mappings only when both dap and telescope are loaded.

To use the whole setup you need:
```lua
require ("modular")
```

It loads the default option, autocmds, mappings and Modules:
```lua
require ("modular.options")
require ("modular.lazy")
require ("modular.autocmds.generic")
require ("modular.mappings.generic")

require ("modular.extras")

local ModuleManager = require ("modular.ModuleManager")

local mm = ModuleManager:new ({
	modules = require ("modular.modules"),
	load_tracker = true
})
```

modular.modules returns a table of Modules:
```lua
return {
	ui_module = require ("modular.modules.UIModule"),
	basic_module = require ("modular.modules.BasicModule"),
	git_module = require ("modular.modules.GitModule"),
	-- .........
	-- .........
	-- .........
	lspextras_module = require ("modular.extras.modules.LspExtrasModule"),
	lint_module = require ("modular.modules.LintModule"),
}
```

And every Module includes it's specific specs and ModuleActions.
For example the DapModule looks like:
```lua
local Module = require ("modular.Module")
local ModuleAction = require ("modular.ModuleAction")

local DapModule = Module:new ({
	name = "Dap",
	plugins = {
		require ("modular.specs.Misc.mason_nvim"),
		require ("modular.specs.Dap.nvim-dap"),
		require ("modular.specs.Dap.mason-nvim-dap"),
		require ("modular.specs.Dap.nvim-dap-ui"),
		require ("modular.specs.Dap.telescope-dap_nvim"),
	},
	actions = {
		ModuleAction:new ({
			plugins = "nvim-dap",
			action = function ()
				require ("modular.mappings.Dap.nvim-dap")
			end
		}),
		ModuleAction:new ({ -- Telescope setup comes from the BasicModule
			plugins = { "telescope-dap.nvim", "telescope.nvim" },
			action = function ()
				require ("modular.mappings.Dap.telescope-dap_telescope_nvim")
			end
		})
	}
})

return DapModule
```

Another problem with vim distributions is that basically there's no way to
disable the default mappings for a specific stuff, lsp/dap/git for example
(of course you can unmap them one by one and get inconsistent setup after a
distribution update with changes in default mappings). Maybe whichkey can help
if it's used by the distribution. With ModularVim you can have your copy of a
module, DapModuleCustom for example, include all specs the original module uses
and replace the ModuleAction which loads the mappings/autocmds you don't
like.

So your config can look like:
```lua
require ("modular.lazy")

local Module = require ("modular.Module")
local ModuleAction = require ("modular.ModuleAction")
local ModuleManager = require ("modular.ModuleManager")

local mm = ModuleManager:new ({
	modules = {
		ui_module = require ("modular.modules.UIModule"),
		basic_module = require ("modular.modules.BasicModule"),
		git_module = require ("modular.modules.GitModule"),
		nvim_module = require ("modular.modules.NvimModule"),
		compiler_module = require ("modular.modules.CompilerModule"),
		-- dap_module = require ("modular.modules.DapModule"),
		Module:new ({
			name = "DapCustom",
			plugins =
				require ("modular.modules.DapModule").plugins
			,
			actions = {
				ModuleAction:new ({
					plugins = "nvim-dap",
					action = function ()
						require ("modular.mappings.Dap.nvim-dap")
					end
				}),
				-- I use fzf-lua instead
				-- ModuleAction:new ({
				--     plugins = { "telescope-dap.nvim", "telescope.nvim" },
				--     action = function ()
				--         require ("modular.mappings.Dap.telescope-dap_telescope_nvim")
				--     end
				-- })
			}
		}),
		db_module = require ("modular.modules.DbModule"),
		md_module = require ("modular.modules.MdModule"),
		lsp_module = require ("modular.modules.LspModule"),
		lean_module = require ("modular.extras.modules.LeanModule"),
		clang_module = require ("modular.extras.modules.ClangModule"),
		-- I don't like ai:
		-- ai_module = require ("modular.modules.AiModule"),
		--
		-- I don't use neorg, orgmode is sufficient.
		-- org_module = require ("modular.modules.OrgModule"),
		Module:new ({
			name = "OrgCustom",
			plugins = {
				-- require ("modular.specs.Org.neorg"),
				require ("modular.specs.Org.orgmode"),
				require ("modular.specs.misc.image_nvim"),
				require ("modular.specs.misc.headlines_nvim"),
			},
			-- And I don't bother about having unnecessary neorg mappings,
			-- they don't get loaded until I don't load neorg.
			actions =
				require ("modular.modules.OrgModule").actions
			,
		}),
		test_module = require ("modular.modules.TestModule"),
		rest_module = require ("modular.modules.RestModule"),
		lspextras_module = require ("modular.extras.modules.LspExtrasModule"),
		lint_module = require ("modular.modules.LintModule"),
	},
	load_tracker = true     -- Notifies when all plugins of a module are loaded.
							-- Can be delayed because of lazy loading of some plugins.
})
```

## Suckless-style management

Like Suckless' patches custom configs can easily be merged without changing the
main config. An example of a custom config structure is **modular.user.gaspar**.

## Pros and cons of this apporach

Almost nothing is lazy-loaded here. Instead of mappings/commands loading plugins,
plugins load the appropriate mappings. This is for the sake of maintability.
Specs are separated from mappings and can be selectively enabled or disabled.
In cost we have 333ms startup time on i7-7500U cpu. LazyVim loads in 77ms.
LazyVim is the greatest NeoVim distribution in my opinion, but it seems hard to
customize (at least for beginners). With this approach we can easily switch
between native/nvim-cmp/blink.nvim completions for example. Currently the native
completions are the default, nvim-cmp and blink.nvim are in todos (see
**todo.norg**). Lazy loading can be managed with ModuleActions with **pre** events.
## Design principles
- Nothing here is intended to look cool. Everything here is about simplicity,
easy maintenance and efficiency. For example we had a PostPluginLoadAction.
What a stupid name. But it describes the best what it does (now it replaced with
ModuleAction which supports pre, post and plugin-independent actions)!

- Avoid overwriting NeoVim's default mappings IN ANY DAMN CASE!!
For example in LazyVim 's' in normal mode is mapped to flash.nvim... Why?
Here we use arrow.nvim in BasicModule. Look what they do by default:
```lua
opts = {
	show_icons = true,
	leader_key = ';', -- Recommended to be a single key
	buffer_leader_key = 'm', -- Per Buffer Mappings
}
```
.. maybe supposed to force the user to customize :d
Yes, there are a lot of great plugins, but the true power lies in vim/nvim.
See **:h motion.txt** for example. What plugin can be as much beneficial as these
motions?
Here we have some small exceptions which have to be reviewed.

## What else cavemans can do
[CHECK THIS](https://www.youtube.com/watch?v=unqsQJaECv0)

## Acknowledgments
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)

## Why such an empty commit history?

[dont write commit messages like me](https://github.com/GasparVardanyan/nvconf/commits/v2/)
For more details on current state see **todo.norg**.

## Seems on one uses this except me

So I continue working on my old config with my stupid commit style.
