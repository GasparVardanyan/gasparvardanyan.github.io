---
title: "Efficiency"
date: 2022-07-30T17:10:06+04:00
---

There are a couple less known/used techniques to boost working/learning efficiency. They are simple to follow. There are a lot of awesome tools to efficiently organize your work, but ofcourse I'll suggest only the FOSS ones, and mostly cli/tui ones ))


So starting from the simplest one, I suggest to use **todo managers**.
  * There is a simple [dmenu](https://tools.suckless.org/dmenu/)-based [shell script](https://tools.suckless.org/dmenu/scripts/todo) on Suckless' website to organize todos. This script saves todos in **~/.todo**, just names or small hints, every element is in a separate line, so you can get the todo's count (*wc -c ~/.todo | cut -d ' ' -f 1*) and put it on your statusbar (if you use TWMs or something that much extensible). Also you can do something like this in your **~/.xinitrc** to regularly get notified about remaining todos count:
  ```sh
  while :; do todos=$(cat ~/.todo 2>/dev/null | wc -l); [ $todos != 0 ] && dunstify todo "you have $todos todos!"; sleep $(( 60 * 60 )); done &
  ```
  * Emacs have an **Org mode** and there's a vim plugin called [vim-orgmode](https://github.com/jceb/vim-orgmode) to
  organize your todos. It's an editor mode for note keeping, project planning and managing todo lists.
  * And the next tool I suggest to manage todos is [todo-txt.cli](https://github.com/todotxt/todo.txt-cli). It seems a very cool alternative to the previously mentioned dmenu-based shell script.


The next thechnique is called **Timeboxing**. A comprehensive time-management system inspired by time-boxing is the [Pomodoro Technique]() by Francesco Cirillo. This one suggests to break your time to working/resting periods


<!-- https://en.wikipedia.org/wiki/Incremental_reading -->

<!-- reayw frustration pomodoro -->
