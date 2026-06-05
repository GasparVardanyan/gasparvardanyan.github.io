---
title: "Tips for C/C++ Developers"
date: 2026-05-25T00:10:51+04:00
---

## Write portable code

Pick a standard and configure your compiler to strictly follow that standard.

For example, to enable a strict C++20 compliance in Clang/GCC use these flags:
```
-std=c++20 -pedantic-errors -Werror=pedantic
```

In CMake projects you can do:
```cmake
set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_EXTENSIONS OFF)

set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=c18 -pedantic-errors -Werror=pedantic")
```

## Multithread your tools

Make sure your language server - the thing that enables code autocompletion in
your IDE - is configured to use multiple threads.

The most common C/C++ language server is clangd. It supports multithreading via
the **--j=NUM_THREADS** command line flag. The **nproc** CLI tool, which is a part
of the GNU coreutils, prints out the number of threads your CPU supports.
In NeoVim I set up clangd like this:
```lua
local nproc = tonumber (vim.fn.system ({"nproc"}))

local jnproc = ''

if 0 ~= nproc
then
    jnproc =  "--j=" .. (nproc - 1)
end

LspServers ["clangd"] = {
    cmd = {
        "clangd",
        "--background-index",
        jnproc,
        "--header-insertion=iwyu",
        -- "--clang-tidy",
    },
}
```
There are different popular opinions on how many threads your multithreaded tool
must use; I choose one less than the all available threads.

In "modern" IDEs you'll probably find some GUI configuration blocks which might
support tuning the language server.

Make sure your project's compilation is multithreaded. Check [this](https://stackoverflow.com/questions/10688549/how-do-i-configure-portable-parallel-builds-in-cmake#50883540)
for enabling multithreading in CMake projects.
In NeoVim I use [cmake-tools.nvim](https://github.com/Civitasv/cmake-tools.nvim)
with this config:
```lua
{
	"Civitasv/cmake-tools.nvim",
	config = function ()
		local nproc = require ("modular.utils").nproc
		local cmake_build_options = {}
		local cmake_generate_options = {}

		if 0 ~= nproc
		then
            -- multithreading make/ninja
			vim.list_extend (cmake_build_options, { "-j" .. (nproc - 1) })
		end

		if 1 == vim.fn.executable ("clang") and 1 == vim.fn.executable ("clang++")
		then
			vim.fn.setenv ("CC", "/usr/bin/clang")
			vim.fn.setenv ("CXX", "/usr/bin/clang++")
		end

        -- explained below
		if 1 == vim.fn.executable ("ccache")
		then
			vim.fn.setenv ("CMAKE_C_COMPILER_LAUNCHER", "ccache")
			vim.fn.setenv ("CMAKE_CXX_COMPILER_LAUNCHER", "ccache")
		end

		if 1 == vim.fn.executable ("ninja")
		then
            -- ninja is faster than make
			vim.list_extend (cmake_generate_options, { "-G Ninja" })
		end

		require ("cmake-tools").setup {
			cmake_build_options = cmake_build_options,
			cmake_generate_options = cmake_generate_options,
		}
	end,
}
```

As you can see I choose ninja over make whenever it's available in the system.
Ninja is faster than make. I also prefer clang over gcc to have LSP-compatible
errors/warnings.

## Use compiler cache to speed up recompilation

[ccache](https://ccache.dev/) is the most popular compiler cache management
tool.
> If you ever run make clean; make, you can probably benefit from ccache. It
> is common for developers to do a clean build of a project for a variety of
> reasons, and this discards the results of your previous compilations. By
> using ccache, recompilation goes much faster.
> Another reason to use ccache is that the same cache is used for builds
>
> in different directories. If you have several versions or branches of a
> project stored in different directories, many of the object files in a build
> directory can often be taken from the cache even if they were compiled for
> another version or branch.
>
> A third scenario is using ccache to speed up clean builds performed by
> servers or build farms that regularly verify that the code builds.
>
> You can also share the cache between users, which can be very useful on
shared compilation servers.

CMake supports ccache via environment variables **CMAKE_C_COMPILER_LAUNCHER**
and **CMAKE_CXX_COMPILER_LAUNCHER**.

In NeoVim I set up ccache to work with CMake like this:
```lua
if 1 == vim.fn.executable ("ccache")
then
    vim.fn.setenv ("CMAKE_C_COMPILER_LAUNCHER", "ccache")
    vim.fn.setenv ("CMAKE_CXX_COMPILER_LAUNCHER", "ccache")
end
```

## IWYU: Include what you use
[This](https://include-what-you-use.org/) tool helps to avoid unnecessarily
included headers and include the necessary ones. For example if you include
A.h which includes B.h for its internal stuff, you can use symbols - variables,
functions, structs, etc - from B.h without actually including it. Then in the
future if A.h removes the include directive for B.h because of some
internal changes, your code wouldn't compile. IWYU checks what symbols do you
use in your code and includes all necessary headers directly and removes all
unused headers.

> "Include what you use" means this: for every symbol (type, function variable,
> or macro) that you use in foo.cc, either foo.cc or foo.h should #include a .h
> file that exports the declaration of that symbol. The include-what-you-use
> tool is a program that can be built with the clang libraries in order to
> analyze #includes of source files to find include-what-you-use violations,
> and suggest fixes for them.

> The main goal of include-what-you-use is to remove superfluous #includes. It
> does this both by figuring out what #includes are not actually needed
> for this file (for both .cc and .h files), and replacing #includes with
> forward-declares when possible.

Don't forget about multithreading! IWYU supports multithreading with the
**-j NUM_THREADS** CLI flag.

In NeoVim I set up IWYU like this:
```lua
local groups = require ("modular.autogroups")

if 1 == vim.fn.executable ("iwyu-tool") and 1 == vim.fn.executable ("iwyu-fix-includes")
then
	local nproc = require ("modular.utils").nproc
	local iwyu_current
	local iwyu_root

	if 0 ~= nproc
	then
		iwyu_current = "w | !iwyu-tool -p . -j " .. (nproc - 1) .. " % | iwyu-fix-includes"
		iwyu_root = "w | !iwyu-tool -p . -j " .. (nproc - 1) .. " | iwyu-fix-includes"
	else
		iwyu_current = "w | !iwyu-tool -p . % | iwyu-fix-includes"
		iwyu_root = "w | !iwyu-tool -p . | iwyu-fix-includes"
	end

	vim.api.nvim_create_autocmd ("FileType", {
		group = vim.api.nvim_create_augroup (groups.ClangIWYU, { clear = true }),
		pattern = { "cpp" },
		callback = function (args)
			local bufnr = args.buf
				vim.api.nvim_buf_create_user_command (bufnr, "ClangIWYUCurrent",
					function () vim.cmd (iwyu_current) end, { nargs = 0 }
				)

				vim.api.nvim_buf_create_user_command (bufnr, "ClangIWYURoot",
					function () vim.cmd (iwyu_root) end, { nargs = 0 }
				)
		end
	})
end

-- ...

local groups = require ("modular.autogroups")
local map = vim.keymap.set

if 1 == vim.fn.executable ("iwyu-tool") and 1 == vim.fn.executable ("iwyu-fix-includes")
then
	local reg_mapping_group = require ("modular.utils").reg_mapping_group
	reg_mapping_group ("<leader>Ch",  "headers")

	vim.api.nvim_create_autocmd ("FileType", {
		group = vim.api.nvim_create_augroup (groups.ClangIWYUMappings, { clear = true }),
		pattern = { "cpp" },
		callback = function (args)
			local bufnr = args.buf
			map ("n", "<leader>Chc", vim.cmd.ClangIWYUCurrent, { buffer = bufnr, desc = "iwyu current file" })
			map ("n", "<leader>Chr", vim.cmd.ClangIWYURoot, { buffer = bufnr, desc = "iwyu root" })
		end
	})
end
```

There's no NeoVim IWYU plugin available but it doesn't stop
NeoVim users from integrating it in their workflow. In "modern" IDEs
you might be forced to use IWYU manually from the terminal. In
this case, or in general, consider using [git pre-commit
hooks](https://www.slingacademy.com/article/git-pre-commit-hook-a-practical-guide-with-examples/).

Clangd also supports IWYU-like functionality. To enable it, edit the
**~/.config/clangd/config.yaml** file and add this:
```yaml
Diagnostics:
  UnusedIncludes: Strict
  MissingIncludes: Strict
```

This will generate warnings and enable **code actions** (automated small code
editing actions) to remove the unused includes and include the missing headers.

## Utilize the full power of your device

You probably already know about the "power profiles" of your device. You
can set it to "Performance", "Balanced", "Power" and other modes. This will
change the performance of your system. It's something motherboard-related
and affects both CPU and GPU. Your system can be tuned further. For
example, in Linux Intel CPUs give a configuration interface through the
[intel pstate](https://docs.kernel.org/admin-guide/pm/intel_pstate.html)
driver. This driver enables configuration options for turbo
boost, hardware-managed performance states, CPU core frequency
limitations and exposes various global and per-core settings via
[cpufreq](https://docs.kernel.org/admin-guide/pm/cpufreq.html).  Intel RAPL
(Running Average Power Limit) exposes CPU energy configuration options through
[powercap](https://www.kernel.org/doc/html/next/power/powercap/powercap.html).

When you compile your C/C++ projects, these
configurations matter! Nvidia GPUs can be tuned through the
[nvidia-smi](https://man.archlinux.org/man/nvidia-smi.1) CLI tool. Consider tweaking
it if you use CUDA. By tuning the [performance state](https://man.archlinux.org/man/nvidia-smi.1#Performance_State)
and other settings, you can speed-up CUDA applications.

On Linux there are user-friendly tools such as [TLP](https://linrunner.de/tlp/index.html)
available to configure these options.

Modern CPUs often feature different types of cores. Some are Performance
cores (P-cores), while others are Efficiency cores (E-cores). These cores
differ in their operating frequencies and, consequently, in the frequency
ranges available for configuration.

One limitation of TLP is that it requires exact frequency values to be
specified. However, the valid frequency ranges vary between core types and,
naturally, between CPU models.

To simplify this, I developed
[DeviceMaster](https://github.com/GasparVardanyan/DeviceMaster), which allows
frequency limits to be configured using percentages rather than absolute
values. It also provides several additional features that make CPU power
and performance tuning easier to manage.

I configure my device like
[this](https://github.com/GasparVardanyan/DeviceMaster/tree/master#example-usage).

Another important thing to configure properly is the Extensible Scheduler Class
of the Linux Kernel. Roughly speaking, it decides which cores have to be used for
which tasks. Remember that CPUs have P cores and E cores, so this is important
for compilation speed and overall system performance. It can be configured with
the [sched-ext](https://wiki.cachyos.org/configuration/sched-ext/) CLI tool.

I configure it like this in **/etc/scx_loader.toml**:
```toml
default_sched = "scx_lavd"
default_mode = "Auto"

[scheds.scx_lavd]
auto_mode = ["--autopower"]
```

## Use linters

Linters help to quickly notice bugs, modernize your code and learn good coding
practices. For example, when your function takes a forwarding reference and you
forget to std::forward it like this:
```cpp
template <typename T>
void f (T && t) {
	someFunc (t);
}
```
you wouldn't have compilation errors or warnings. This code would work fine in
many situations and could be hard to debug when something fails because
of it. However, clang-tidy would give a diagnostic message like this:
```
forwarding reference parameter 't' is never forwarded inside the function body
[cppcoreguidelines-missing-std-forward]
```

In NeoVim I set up clang-tidy and cppcheck like this:

```lua
local clang_config = require ("modular.config.clang")

local clang_standard = function ()
    if vim.bo.filetype == "cpp" then
        return "--extra-arg=-std=" .. clang_config.stdcpp
    elseif vim.bo.filetype == "c" then
        return "--extra-arg=-std=" .. clang_config.stdc
    else
        return ""
    end
end

local cppcheck_standard = function ()
    if vim.bo.filetype == "cpp" then
        return "--std=" .. clang_config.stdcpp
    elseif vim.bo.filetype == "c" then
        return "--std=" .. clang_config.stdc
    else
        return ""
    end
end

local nproc = require ("modular.utils").nproc
local cppcheck_jnproc = ''

if 0 ~= nproc
then
    cppcheck_jnproc =  "-j " .. (nproc - 1)
end

local clang_tidy = require ("lint.linters.clangtidy")
local cppcheck = require ("lint.linters.cppcheck")

-- https://clang.llvm.org/extra/clang-tidy/
vim.list_extend (clang_tidy.args, {
    clang_standard,
    "--checks=*" -- abseil, altera, android, boost, bugprone,
        -- cert, clang, concurrency, cppcoreguidelines, darwin,
        -- fuchsia, google, hicpp, linuxkernel, llvm, llvmlibc,
        -- misc, modernize, mpi, objc, openmp, performance,
        -- portability, readability, zircon

        .. ",-darwin-*"
        .. ",-linuxkernel-*"
        .. ",-llvmlibc-*"
        .. ",-objc-*"

        .. ",-altera-unroll-loops"
        .. ",-bugprone-easily-swappable-parameters"
        .. ",-fuchsia-default-arguments-calls"
        .. ",-fuchsia-default-arguments-declarations"
        .. ",-fuchsia-overloaded-operator"
        .. ",-fuchsia-trailing-return"
        .. ",-google-explicit-constructor"
        .. ",-hicpp-explicit-conversions"
        .. ",-llvm-else-after-return"
        .. ",-llvm-header-guard"
        .. ",-misc-non-private-member-variables-in-classes"
        .. ",-misc-use-anonymous-namespace"
        .. ",-modernize-use-trailing-return-type"
        .. ",-readability-else-after-return"
        .. ",-readability-function-cognitive-complexity"
        .. ",-readability-identifier-length"
        .. ",-readability-isolate-declaration"
        .. ",-readability-magic-numbers"
        .. ",-readability-redundant-access-specifiers"
        .. ",-readability-redundant-inline-specifier"
        .. ",-readability-simplify-boolean-expr"

        -- .. ",-cppcoreguidelines-avoid-do-while"
        -- .. ",-cppcoreguidelines-avoid-magic-numbers"
        -- .. ",-cppcoreguidelines-non-private-member-variables-in-classes"
        -- .. ",-cppcoreguidelines-owning-memory"
        -- .. ",-cppcoreguidelines-rvalue-reference-param-not-moved"
        -- .. ",-modernize-use-nodiscard"
})

vim.list_extend (cppcheck.args, {
    cppcheck_standard,
    cppcheck_jnproc,
    "--check-level=exhaustive",
    "--enable=all",
    "--suppress=missingIncludeSystem",
})
```

clang-tidy works with [CUDA
too](https://clang.llvm.org/extra/clang-tidy/#running-clang-tidy-on-cuda-files).

For Qt applications, use [clazy](https://github.com/KDE/clazy). Unfortunately
clazy doesn't support enabling all diagnostics and disabling selected ones.
In NeoVim I set up clazy like this:

```lua
local clazy = require ("lint.linters.clazy")

vim.list_extend (clazy.args, {
    clang_standard,
    "-checks=" -- why * doesn't work here?
        .. "level0"
        .. ",level1"
        .. ",level2"
        .. ",assert-with-side-effects"
        .. ",compare-member-check"
        .. ",container-inside-loop"
        .. ",detaching-member"
        .. ",heap-allocated-small-trivial-type"
        .. ",ifndef-define-typo"
        .. ",isempty-vs-count"
        .. ",jni-signatures"
        .. ",qbytearray-conversion-to-c-style"
        .. ",qhash-with-char-pointer-key"
        .. ",qproperty-type-mismatch"
        .. ",qrequiredresult-candidates"
        .. ",qstring-ref"
        .. ",qstring-varargs"
        .. ",qt-keyword-emit"
        .. ",qt-keywords"
        .. ",qvariant-template-instantiation"
        .. ",raw-environment-function"
        .. ",reserve-candidates"
        .. ",sanitize-inline-keyword"
        .. ",signal-with-return-value"
        .. ",thread-with-slots"
        .. ",tr-non-literal"
        .. ",unexpected-flag-enumerator-value"
        .. ",unneeded-cast"
        .. ",unused-result-check"
        .. ",use-arrow-operator-instead-of-data"
        .. ",use-chrono-in-qtimer"
        .. ",used-qunused-variable",
})
```

## Use profilers

Linux has a built in performance profiler called
[perf](https://perfwiki.github.io/main/).  It helps you analyze
your application's performance and pinpoint which functions consume
the most CPU time. Other operating systems likely offer similar
tools. If you're using NeoVim, you're in luck - there's an excellent
[extension](https://github.com/t-troebst/perfanno.nvim) that integrates perf
directly into NeoVim.

## Conditional breakpoints

This is worth noting here because if you use a "modern" IDE, there's a good
chance you're not familiar with conditional breakpoints. For example, when
you need to stop inside a loop only when the loop counter reaches a specific
value, you might write an if statement and place a breakpoint inside it:
```cpp
for (std::size_t i = 0; i < COUNT; ++i) {
    if (i == 1000) {
        int xxx; // breakpoint on this line
    }
}
```

In "modern" IDEs the conditional breakpoint feature is "hidden" behind the
GUI blocks. With NeoVim, debugging is not a built-in feature. You have to set
up the debugger yourself, configure key mappings, and explore the available
functionality. In the process, you often discover features that you might
never have encountered in a traditional IDE, including powerful debugging
capabilities such as conditional breakpoints.

## Documentation tools

You can browse [cppreference.com](cppreference.com) and
[cplusplus.com](cplusplus.com) from your terminal like the man pages
with [cppman](https://github.com/aitjcize/cppman). It also supports caching both
sites and browsing in offline mode. There's also a NeoVim
[extension](https://github.com/madskjeldgaard/cppman.nvim) to integrate
cppman.

[Zeal](https://zealdocs.org/) is an offline GUI documentation browser. It
supports sources like cppreference, Qt, CUDA, OpenGL, etc. There's also a Vim
[extension](https://github.com/nilp0inter/zeavim.vim) to access Zeal docs like
you access Qt docs from QtCreator.

I manage zeavim mappings in NeoVim like this:
```lua
local map = vim.keymap.set

local function zeal_search (docset, query)
    local old_docset = vim.b.manualDocset

    vim.fn ["zeavim#DocsetInBuffer"] (docset)
    vim.fn ["zeavim#SearchFor"] ("", query)

	vim.print ("Searching for " .. query)

    if old_docset ~= nil then
        vim.b.manualDocset = old_docset
    else
        vim.b.manualDocset = nil
    end
end

local function zeal_search_input (docset)
	local query = vim.fn.input("Search for: ")

    if docset ~= "" and query ~= "" then
		zeal_search (docset, query)
    end
end

map ("n", "<leader>zc", function ()
	zeal_search ("c", vim.fn.expand ("<cWORD>"))
end, { desc = "C" })
map ("n", "<leader>zp", function ()
	zeal_search ("cpp", vim.fn.expand ("<cWORD>"))
end, { desc = "C++" })
map ("n", "<leader>zq", function ()
	zeal_search ("qt6", vim.fn.expand ("<cWORD>"))
end, { desc = "Qt6" })

map ("n", "<leader>zC", function ()
	zeal_search_input ("c")
end, { desc = "C - input" })
map ("n", "<leader>zP", function ()
	zeal_search_input ("cpp")
end, { desc = "C++ - input" })
map ("n", "<leader>zQ", function ()
	zeal_search_input ("qt6")
end, { desc = "Qt6 - input" })
```

## Use powerful tools and master your tools

Using Windows wouldn't teach you anything. Instead, you'll have to do a lot of
things manually, set up your tools and libraries manually every time you do a
fresh install. It would make your device feel slow.

Using a preconfigured Linux distribution wouldn't teach you as much as DIY ones.
Instead for example Ubuntu would force you to use heave snaps instead of regular
deb packages and rusted coreutils as GNU coreutils replacement which don't pass
all of the GNU coreutils tests. Ubuntu will force its politics on you too!
That distribution isn't for conservatives ))

Using "modern" IDEs wouldn't teach you anything; you wouldn't know what
happens under the hood when you press that green triangle button, for example.

DIY Linux distros such as Arch and Gentoo or good IDEs such as Vim and NeoVim
can make things harder for you if you're new to programming. You'll had to
learn programming plus your OS plus your programming tools, all at once. First
learn programming and only then switch to powerful tools. For beginners,
CachyOS is a great Linux distribution. VSCode is bloated but flexible and good
enough IDE.
