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
		default_text = "TODO|\\[ \\]",
	})
end
-- CREATE: specific function to create a new note with a title
function M.new_note()
	ensure_dir()

	vim.ui.input({ prompt = "New Note Path (e.g., 'folder/name'): " }, function(input)
		if input == nil or input == "" then
			return
		end

		-- Sanitize filename: replace spaces with dashes, lowercase
		local filename = input:gsub(" ", "-"):lower()

		if not filename:match("%." .. M.config.options.extension .. "$") then
			filename = filename .. "." .. M.config.options.extension
		end

		local filepath = get_skb_path():joinpath(filename)
		vim.notify("path: " .. filepath:absolute(), vim.log.levels.ERROR)
		local parent_dir = filepath:parent()
		if not parent_dir:exists() then
			parent_dir:mkdir({ parents = true })
			vim.notify(
				"Created new directory: " .. parent_dir:make_relative(M.config.options.skb_path),
				vim.log.levels.INFO
			)
		end

		-- Edit the file (creates it if it doesn't exist)
		vim.cmd("edit " .. filepath:absolute())

		if filepath:exists() and filepath:_stat().size == 0 or not filepath:exists() then
			local title = input:match("([^/]+)$")
			local header = "# " .. title
			vim.api.nvim_buf_set_lines(0, 0, 0, false, { header, "", "" })
			vim.cmd("normal G")

			-- add template
			M.insert_template()
		end
	end)
end

-- TEMPLATES (New Feature): Scans the /templates folder and lets you pick one to insert
function M.insert_template()
	ensure_dir()
	local template_dir = get_skb_path():joinpath("templates")

	-- Get list of files in templates dir
	local files = Scan.scan_dir(
		template_dir:absolute(),
		{ depth = 1, search_pattern = "%." .. M.config.options.extension .. "$" }
	)

	if #files == 0 then
		vim.notify("No templates found in /templates folder.", vim.log.levels.WARN)
		return
	end

	-- Prepare formatted list for the selection UI
	local options = {}
	for _, file in ipairs(files) do
		-- Show just the filename, not full path
		table.insert(options, Path:new(file):make_relative(template_dir:absolute()))
	end

	vim.ui.select(options, { prompt = "Select a Template:" }, function(choice)
		if not choice then
			return
		end

		local selected_file = template_dir:joinpath(choice)

		-- Read the template file
		local lines = selected_file:read()

		-- Plenary read() returns a string or lines depending on version,
		-- but usually we need to split if it's a blob.
		-- A safer vanilla way to read lines into a table:
		local content = vim.fn.readfile(selected_file:absolute())

		-- Paste content at cursor position
		local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
		vim.api.nvim_buf_set_lines(0, row, row, false, content)
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
