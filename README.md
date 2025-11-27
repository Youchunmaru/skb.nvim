# simple knowledge base (skb.nvim)

A simple, modular Neovim plugin to manage a local knowledge base using Markdown files, Git, and Telescope. Designed for a friction-less "Zettelkasten-lite" workflow in the terminal.

## Features

- Search: Live grep through your notes using Telescope (ripgrep required).
- Find: Quickly open files by name.
- Sync: Auto-sync to a Git repository (add/commit/pull/push) with one command.
- History: View modification history (diffs) of the current note or the entire knowledge base.
- Changes: View uncommitted changes in real-time to see what you've worked on.
- Templates: Create templates and apply them to a new note
- Folders: Organize your notes in folder structures

## Requirements

- Neovim >= 0.9.0
- Telescope.nvim
- plenary.nvim
- ripgrep (for searching)
- git (for versioning)

## Installation

### using lazy.nvim

```lua
return {
    {
        "Youchunmaru/skb.nvim",
        opts = {
            kb_path = "~/knowledge_base",-- the path to save your note files in
            extension = "md",-- the file extension you wanna use for note-taking
            git = {-- git settings
                enabled = true,-- if you want to use git for history
                remote = false-- if you want to sync your notes to a repo, you have to manually add a remote if you want to use that
            }
        },
        dependencies = {
            "nvim-telescope/telescope.nvim", -- We need telescope for the search features
            "nvim-lua/plenary.nvim", -- plenary for some convenient methods
        },

        keys = {-- you can change the key combinations as you see fit, or remove those you are not using
            { 
                "<leader>ns", 
                function() require("skb").search_notes() end, -- Searche for a given string inside you notes
                desc = "[N]otes [S]earch (Grep)" 
            },
            { 
                "<leader>nf", 
                function() require("skb").find_notes() end, -- Searche for file names
                desc = "[N]otes [F]ind File" 
            },
            { 
                "<leader>nn", 
                function() require("skb").new_note() end, -- create a new note and optionally apply a template
                desc = "[N]ew [N]ote" 
            },
            { 
                "<leader>ng", 
                function() require("skb").git_sync() end, -- apply your changes to git and optionally sync them to a repo
                desc = "[N]otes [G]it Sync" 
            },
            { 
                "<leader>nh", 
                function() require("skb").note_history() end, -- See the change history for the note file you are in
                desc = "[N]ote [H]istory (File)" 
            },
            { 
                "<leader>nH", 
                function() require("skb").search_history() end, -- see all changes for all notes
                desc = "[N]ote [H]istory (Global)" 
            },
            { 
                "<leader>nc", 
                function() require("skb").note_changes() end, -- see the changes since your last sync
                desc = "[N]ote [C]hanges (Status)" 
            },
            { 
                "<leader>nt", 
                function() require("skb").search_todo() end, -- search for todo's
                desc = "[N]ote [S]earch (TODO)" 
            },
        },
    }
}

```
