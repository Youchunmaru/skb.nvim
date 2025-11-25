-- module: kb.lua
local config = require("skb.config")
-- A simple knowledge base manager for Neovim
local M = {}

-- CONFIGURATION
M.config = config

-- Setup function to override defaults if needed
function M.setup(opts)
	M.config.setup(opts)
end

-- Helper: Ensure directory exists
local function ensure_dir()
	-- 1. Create the directory if it doesn't exist
	if vim.fn.isdirectory(M.config.options.skb_path) == 0 then
		vim.fn.mkdir(M.config.options.skb_path, "p")
	end

	-- 2. Initialize Git if enabled and .git folder is missing
	if M.config.options.git.enabled then
		local git_dir = M.config.options.skb_path .. "/.git"
		if vim.fn.isdirectory(git_dir) == 0 then
			-- Run git init
			vim.fn.system("cd " .. M.config.options.skb_path .. " && git init")
			vim.notify("Knowledge Base: Git repository initialized.", vim.log.levels.INFO)
		end
	end
end

-- 1. SEARCH: Wrapper around Telescope Live Grep (uses Ripgrep)
function M.search_notes()
	ensure_dir()
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		vim.notify("Telescope plugin is required for searching!", vim.log.levels.ERROR)
		return
	end

	builtin.live_grep({
		prompt_title = "Search Knowledge Base",
		cwd = M.config.options.skb_path,
	})
end

-- 2. FIND: Wrapper to find specific files by name
function M.find_notes()
	ensure_dir()
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		return
	end

	builtin.find_files({
		prompt_title = "Find Notes",
		cwd = M.config.skb_path,
	})
end

-- 3. SEARCH HISTORY: View git commits and changes
function M.search_history()
	ensure_dir()
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		return
	end

	-- git_commits shows the log. Pressing <cr> usually checks out the commit,
	-- but the preview window serves as a great way to view changes.
	builtin.git_commits({
		prompt_title = "Knowledge Base History (Global)",
		cwd = M.config.options.skb_path,
	})
end

-- 4. NOTE HISTORY: View history of CURRENT file
function M.note_history()
	ensure_dir()
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		return
	end

	builtin.git_bcommits({
		prompt_title = "Current Note History",
		cwd = M.config.options.skb_path,
		-- git_bcommits automatically limits to the current buffer
	})
end

-- 5. NOTE CHANGES: View uncommitted changes (Git Status)
function M.note_changes()
	ensure_dir()
	local ok, builtin = pcall(require, "telescope.builtin")
	if not ok then
		return
	end

	builtin.git_status({
		prompt_title = "Uncommitted Changes",
		cwd = M.config.options.skb_path,
	})
end

-- 6. CREATE: specific function to create a new note with a title
function M.new_note()
	ensure_dir()

	vim.ui.input({ prompt = "New Note Name: " }, function(input)
		if input == nil or input == "" then
			return
		end

		-- Sanitize filename: replace spaces with dashes, lowercase
		local filename = input:gsub(" ", "-"):lower()
		if not filename:match("%." .. M.config.options.extension .. "$") then
			filename = filename .. "." .. M.config.options.extension
		end

		local filepath = M.config.options.skb_path .. "/" .. filename

		-- Edit the file (creates it if it doesn't exist)
		vim.cmd("edit " .. filepath)

		-- Optional: Add a title header automatically if new file
		if vim.fn.getfsize(filepath) == -1 then
			local header = "# " .. input
			vim.api.nvim_buf_set_lines(0, 0, 0, false, { header, "", "" })
			-- Move cursor to end
			vim.cmd("normal G")
		end
	end)
end

-- 5. VERSIONING: Git Sync
-- Adds all changes, commits with timestamp, and pulls/pushes
function M.git_sync()
	if not M.config.options.git.enabled then
		vim.notify("Git sync is disabled in config", vim.log.levels.WARN)
		return
	end

	local path = M.config.options.skb_path
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local commit_msg = "Auto-sync: " .. timestamp

	-- We chain commands using '&&'.
	-- 1. cd to path
	-- 2. git add .
	-- 3. git commit
	-- 4. git pull --rebase (to avoid conflicts)
	-- 5. git push
	local cmd = string.format("cd %s && git add . && git commit -m '%s'", path, commit_msg)
	if M.config.options.git.remote then
		vim.notify("Syncing with remote!", vim.log.levels.INFO)
		cmd = cmd .. " && git pull --rebase && git push"
	end

	vim.notify("Starting Git Sync...", vim.log.levels.INFO)

	-- Execute asynchronously so we don't freeze Neovim
	vim.fn.jobstart(cmd, {
		on_exit = function(_, code, _)
			if code == 0 then
				vim.notify("Knowledge Base Synced Successfully!", vim.log.levels.INFO)
			else
				vim.notify("Git Sync Failed. Check :messages", vim.log.levels.ERROR)
			end
		end,
		on_stderr = function(_, data, _)
			-- Log errors to :messages
			if data then
				-- formatting for cleaner logs
			end
		end,
	})
end

return M
