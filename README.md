# Resistance Zero Neovim Plugin

An implementation of Mark Forster's Resistance Zero Productivity system.

[Resistance Zero by Mark Forster](http://markforster.squarespace.com/blog/2022/6/14/resistance-how-to-make-the-most-of-it-the-resistance-zero-sy.html)

TLDR | Four steps to the system:
1. Write out a list of things to do.
2. Starting at the end of the list, scan backwards an mark tasks with no resistance.
3. Starting with the end of the marked list, take action on every no resistance task.
4. Repeat the first three steps.

Mr. Forster's system suggests a quick scan of all the tasks while still contemplating taking action on each one. As the review process iterates, the skipped reviewed tasks lose resistance and will eventually become marked. Through experimentation, I found modifying the task to lower the resistance and gain momentum on the main task worked best.

The review scan of the task line starts from the end because, per Mr. Forster's words, "I found that I got better results having the older slower moving tasks at the end of the scan, rather than at the beginning." This psycological though process also applies to acting on tasks starting from the end of the list.

My implementation of Mr. Forster's system tries to honor all of the above with some minor additions I have found useful throughout my productivity journey.

## Installation

Re-Zero has been tested on Neovim v0.12+. Should work on Neovim 0.9+, but no guarantees.

### Installation using [Lazy](https://github.com/folke/lazy.nvim)

```lua
{ "ivanOzerets/re-zero" }
```

Then run `:Lazy sync`.

### Installation using [Vim packages](https://github.com/neovim/neovim)

```lua
vim.pack.add({
    "https://github.com/ivanOzerets/re-zero",
})
```

### Installation using [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use "ivanOzerets/re-zero
```

Then run `:PackerSync` (or `:PackerInstall`).

### Installation using [Vim-Plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'ivanOzerets/re-zero'
```

Then run `:PlugInstall`.

## Features

### Task Lists

The todo.md file is broken up into three task lists.

Each list is responsible for a task in a certain state.

Per Mr. Forster's system, if a task is "marked", the task is active and lives in the `active list`.

If a task is new or a subtask, the task is pending and lives in the `pending list`.

If a task is complete, the task lives in the `finished list`.

### Review Mode

When entering Review Mode, a separate floating buffer displays the pending tasks one at a time in reverse order. The user selects one of four options for each task.
- Some resistance to the task.
- No resistance to the task.
- The task is complete.
- Undo the last review mode action.

**Some Resistance**

Psychologically, when a task has some resistance, reviewing the task and asking the question of whether you have no resistance to this task, most often lowers that task's resistance on subsequent reviews. I found it too easy to skill tasks without giving each a proper consideration. "Oh that task again, ahh, I'll start that later."

The motivation of this plugin was not only to implement Mr. Forster's Resistance Zero system, but also experiment with creating a tool to help my get things done. As a result, the change that has helped me the most is adjusting task with some resistance every review cycle to potentially gain any progress towards its completion. Breaking a bigger task down has helped greatly.

This implementation facilitates such an understanding and prompts the user to enter a subtask of the parent task every time a task has some resistance. The new "subtasks" are filtered back into the pending list and its parent task is displayed alongside the new subtask (- [ ] subtask (parent task)).

**Re-Zero (No Resistance)**

If the user has no resistance to the current task (re-zero), the task gets filtered into the active list and the task is marked with an asterisk (- [*] some task).

If a task has a parent task attched and is marked completed, the subtask will get filtered into the finished list while the parent task get refiltered into the pending list. The same mechanic applies to marking tasks as complete straight from the pending list.

### Daily Archive

At the end of every day, or triggered manually, a snapshot of the current todo.md file is archived under `~\re-zero\archive\`.

The date at the top of the file is updated and the finished list get wiped.

The archive acts as a running record of the task the user finished everyday and what tasks were left over.

### Smart Enter

Taking inspiration from Notion, VimWiki, Emacs Org Mode, etc., creating a new task from new line actions works exactly how one would expect it to work.

Pressing `<Enter>` in Insert mode or `o` in Normal mode obeys the rules of creating a new task bullet (- [ ]) respective to the list the new task is in.

## File Format

When first opening up todo.md, the file will be autopopulated with these four header.

### TODO *Date*

The first line of todo.md gets autopopulated with the current date.

This date is referenced every time a daily check is run at the end of the day or manually.

### Active List

This list contains the tasks that have zero resistance to getting done.

At any time the user can start going down the list, top to bottom, and completing their set of tasks

### Pending List

This list contains the set of new tasks the user has entered or will enter at any time.

Jumping to a new task entry in the pending list is easy with the `<leader> td` keymap.

### Finished List

This list contains all the tasks that have been compelted.

All tasks in the list get wiped at the start of each new day.

## Commands

- `:ReZero` -- Opens the todo.md file.
- `:ReZeroReview` -- Starts review mode of the current pending tasks.
- `:ReZeroUpdate` -- Runs a daily save check.

## Keymaps

### Normal Mode

- `"<leader> tt` -- Open todo.md.
- `"<leader> td` -- Jump to new task.
- `"<leader> tu` -- Runs daily update.
- `"<leader> tr` -- Starts review mode.
    - `h` -- Task has some resistance - Enter subtask.
    - `j` -- Task has no resistance (re-zero).
    - `k` -- Task is done.
    - `u` -- Undo previous review action.
- `"o"` -- "Smart" enter from Normal mode.
- `<Enter>` -- Move the hovered task to the finished list.

### Insert Mode

- `<Enter>` -- "Smart" enter from Insert mode.
