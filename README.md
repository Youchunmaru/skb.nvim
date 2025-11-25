# simple knowledge base (skb.nvim)

A simple, modular Neovim plugin to manage a local knowledge base using Markdown files, Git, and Telescope. Designed for a friction-less "Zettelkasten-lite" workflow in the terminal.

## Features

- Search: Live grep through your notes using Telescope (ripgrep required).
- Find: Quickly open files by name.
- Sync: Auto-sync to a Git repository (add/commit/pull/push) with one command.
- History: View modification history (diffs) of the current note or the entire knowledge base.
- Changes: View uncommitted changes in real-time to see what you've worked on.

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
        main = "kb", 
        -- 'dir' points to your config root, allowing us to 'require' the local module
        opts = {
            --kb_path = "~/knowledge_base",
            --extension = "md",
            --git = {
                --enabled = true,
                --remote = false
            --}
        },
        dependencies = {
            "nvim-telescope/telescope.nvim", -- We need telescope for the search features
            "nvim-lua/plenary.nvim",
        },

        keys = {
            { 
                "<leader>ns", 
                function() require("kb").search_notes() end, 
                desc = "[N]otes [S]earch (Grep)" 
            },
            { 
                "<leader>nf", 
                function() require("kb").find_notes() end, 
                desc = "[N]otes [F]ind File" 
            },
            { 
                "<leader>nn", 
                function() require("kb").new_note() end, 
                desc = "[N]ew [N]ote" 
            },
            { 
                "<leader>ng", 
                function() require("kb").git_sync() end, 
                desc = "[N]otes [G]it Sync" 
            },
            { 
                "<leader>nh", 
                function() require("kb").note_history() end, 
                desc = "[N]ote [H]istory (File)" 
            },
            { 
                "<leader>nH", 
                function() require("kb").search_history() end, 
                desc = "[N]ote [H]istory (Global)" 
            },
            { 
                "<leader>nc", 
                function() require("kb").note_changes() end, 
                desc = "[N]ote [C]hanges (Status)" 
            },
        },
    }
}

```
