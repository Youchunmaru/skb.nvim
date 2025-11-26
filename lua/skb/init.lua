-- module: skb.lua
local config = require("skb.config")
local Path = require("plenary.path")
local Scan = require("plenary.scandir")
local Job = require("plenary.job")
-- A simple knowledge base manager for Neovim
local M = {}

-- CONFIGURATION
M.config = config

-- Setup function to override defaults if needed
function M.setup(opts)
	M.config.setup(opts)
end

-- Helper: Get the base path object
local function get_skb_path()
	return Path:new(M.config.options.skb_path)
end

-- Helper: Ensure directory exists
local function ensure_dir()
	local p = get_skb_path()

	if not p:exists() then
		p:mkdir({ parents = true })
	end

	-- Initialize Git if enabled
	if M.config.options.git.enabled then
		local git_dir = p:joinpath("/.git")
		if not git_dir:exists() then
			Job:new({
				command = "git",
				args = { "init" },
				cwd = p:absolute(),
				on_exit = function(_, return_val)
					if return_val == 0 then
						vim.schedule(function()
							vim.notify("SKB: Git init succesful", vim.log.levels.INFO)
						end)
					end
				end,
			}):start()
		end
	end

	local t_path = p:joinpath("templates")
	if not t_path:exists() then
		t_path:mkdir({ parents = true })
	end
end
-- SEARCH: Wrapper around Telescope Live Grep (uses Ripgrep)
function M.search_notes()
	ensure_dir()
	require("telescope.builtin").live_grep({
		prompt_title = "Search Knowledge Base",
		cwd = M.config.options.skb_path,
	})
end

-- FIND: Wrapper to find specific files by name
function M.find_notes()
	ensure_dir()
	require("telescope.builtin").find_files({
		prompt_title = "Find Notes",
		cwd = M.config.options.skb_path,
	})
end

-- SEARCH HISTORY: View git commits and changes
function M.search_history()
	ensure_dir()
	require("telescope.builtin").git_commits({
		prompt_title = "Knowledge Base History (Global)",
		cwd = M.config.options.skb_path,
	})
end

-- NOTE HISTORY: View history of CURRENT file
function M.note_history()
	ensure_dir()
	require("telescope.builtin").git_bcommits({
		prompt_title = "Current Note History",
		cwd = M.config.options.skb_path,
	})
end

-- NOTE CHANGES: View uncommitted changes (Git Status)
function M.note_changes()
	ensure_dir()
	require("telescope.builtin").builtin.git_status({
		prompt_title = "Uncommitted Changes",
		cwd = M.config.options.skb_path,
	})
end

-- SEARCH TODOS: Scans for "[ ]" or "TODO" in your notes
function M.search_todos()
	ensure_dir()
	require("telescope.builtin").live_grep({
		prompt_title = "Search TODOs",
		cwd = M.config.options.skb_path,
		default_text = "TODO|[ ]",
	})
end
-- CREATE: specific function to create a new note with a title
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
		return
	end

	local path = M.config.options.skb_path
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")

	vim.notify("Starting Sync...", vim.log.levels.INFO)

	-- We run this as a sequence of synchronous jobs for simplicity within the async function,
	-- or chained callbacks. Here is a linear approach using Job:sync() inside a coroutine
	-- or simply chaining callbacks. For simplicity/readability, let's chain `git add` and `commit`.

	Job:new({
		command = "git",
		args = { "add", "." },
		cwd = path,
		on_exit = function(_, _)
			Job:new({
				command = "git",
				args = { "commit", "-m", "Auto-synv: " .. timestamp },
				cwd = path,
				on_exit = function(_, code)
					if M.config.options.git.remote then
						Job:new({
							command = "git",
							args = { "pull", "rebase" },
							cwd = path,
							on_exit = function(_, pull_code)
								if pull_code == 0 then
									Job:new({
										command = "git",
										args = { "push" },
										cwd = path,
										on_exit = function(_, push_code)
											if push_code == 0 then
												vim.schedule(function()
													vim.notify("Sync Complete!", vim.log.levels.INFO)
												end)
											end
										end,
									}):start()
								end
							end,
						}):start()
					else
						vim.schedule(function()
							vim.notify("Local Commit Complete", vim.log.levels.INFO)
						end)
					end
				end,
			}):start()
		end,
	}):start()
end

return M
