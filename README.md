
```lua
return {
    {
        -- We give it a name to identify it in the Lazy UI
        "youchunmaru.simpleKnowledgeBase",
        -- 'dir' points to your config root, allowing us to 'require' the local module
        dir = vim.fn.stdpath("config"),
        name = "kb-local", 
        
        dependencies = {
            "nvim-telescope/telescope.nvim", -- We need telescope for the search features
            "nvim-lua/plenary.nvim",
        },

        -- Lazy load this plugin when any of these keys are pressed
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

        opts = {
            --kb_path = "",
            --extension = "",
            --git = {
                --enabled = true,
                --remote = false
            --}
        }
    }
}

```
