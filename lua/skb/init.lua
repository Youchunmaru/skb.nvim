-- module: skb.lua
local config = require("skb.config")

local M = {}
M.config = config

-- Helper:
local function get_path()
	return require("plenary.path")
end
local function get_scan()
	return require("plenary.scandir")
end
local function get_job()
	return require("plenary.job")
end

-- Helper: Get the base path object
local function get_skb_root()
	return get_path():new(M.config.options.skb_path)
end

-- Initialization
local function init_filesystem()
	local p = get_skb_root()

	-- Create root if missing
	if not p:exists() then
		p:mkdir({ parents = true })
	end

	-- Create templates directory if missing
	local t_path = p:joinpath("templates")
	if not t_path:exists() then
		t_path:mkdir({ parents = true })
	end

	-- Initialize Git only if enabled and .git folder is missing
	if M.config.options.git.enabled then
		local git_dir = p:joinpath(".git")
		if not git_dir:exists() then
			get_job()
				:new({
					command = "git",
					args = { "init" },
					cwd = p:absolute(),
					on_exit = function(_, return_val)
						if return_val == 0 then
							vim.schedule(function()
								vim.notify("SKB: Git init successful", vim.log.levels.INFO)
							end)
						end
					end,
				})
				:start()
		end
	end
end

-- PUBLIC SETUP
function M.setup(opts)
	M.config.setup(opts)
	-- Run initialization logic once on setup
	init_filesystem()
end

-- --- CORE FUNCTIONS ---

function M.search_notes()
	require("telescope.builtin").live_grep({
		prompt_title = "Search Knowledge Base",
		cwd = M.config.options.skb_path,
	})
end

function M.find_notes()
	require("telescope.builtin").find_files({
		prompt_title = "Find Notes",
		cwd = M.config.options.skb_path,
	})
end

function M.search_history()
	require("telescope.builtin").git_commits({
		prompt_title = "KB History (Global)",
		cwd = M.config.options.skb_path,
	})
end

function M.note_history()
	require("telescope.builtin").git_bcommits({
		prompt_title = "Current Note History",
		cwd = M.config.options.skb_path,
	})
end

function M.note_changes()
	require("telescope.builtin").git_status({
		prompt_title = "Uncommitted Changes",
		cwd = M.config.options.skb_path,
	})
end

function M.search_todos()
	require("telescope.builtin").live_grep({
		prompt_title = "Search TODOs",
		cwd = M.config.options.skb_path,
		default_text = "todo|\\[ \\]",
	})
end

-- --- NOTE CREATION ---

function M.new_note()
	vim.ui.input({ prompt = "New Note Path (e.g. 'dev/lua-tips'): " }, function(input)
		if not input or input == "" then
			return
		end

		-- Sanitize: spaces to dashes, lowercase
		local clean_input = input:gsub(" ", "-"):lower()

		-- Ensure extension
		local ext = "." .. M.config.options.extension
		if not clean_input:match(ext .. "$") then
			clean_input = clean_input .. ext
		end

		local filepath = get_skb_root():joinpath(clean_input)

		-- Create parent dir if needed
		local parent_dir = filepath:parent()
		if not parent_dir:exists() then
			parent_dir:mkdir({ parents = true })
		end

		-- Check if file exists to determine if we should template
		local is_new = not filepath:exists()

		-- Edit the file
		vim.cmd("edit " .. filepath:absolute())

		-- If it's new, add header and prompt for template
		if is_new then
			local title = input:match("([^/]+)$") or clean_input
			-- Capitalize first letter of title for aesthetics
			title = title:gsub("^%l", string.upper)

			local header = "# " .. title
			vim.api.nvim_buf_set_lines(0, 0, 0, false, { header, "", "" })

			-- Move cursor to end
			vim.cmd("normal G")

			-- Prompt for template
			M.insert_template()
		end
	end)
end

function M.insert_template()
	local template_dir = get_skb_root():joinpath("templates")

	-- Fail silently if template dir doesn't exist (deleted by user?)
	if not template_dir:exists() then
		return
	end

	local files = get_scan().scan_dir(
		template_dir:absolute(),
		{ depth = 1, search_pattern = "%." .. M.config.options.extension .. "$" }
	)

	if #files == 0 then
		return
	end

	local options = {}
	for _, file in ipairs(files) do
		table.insert(options, get_path():new(file):make_relative(template_dir:absolute()))
	end

	vim.ui.select(options, { prompt = "Select Template:" }, function(choice)
		if not choice then
			return
		end

		local selected_file = template_dir:joinpath(choice)

		-- Read file
		local content = vim.fn.readfile(selected_file:absolute())

		-- Insert at cursor
		local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
		vim.api.nvim_buf_set_lines(0, row, row, false, content)
	end)
end

-- --- VERSION CONTROL ---

function M.git_sync()
	if not M.config.options.git.enabled then
		return
	end

	local path = M.config.options.skb_path
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")

	vim.notify("SKB: Starting Sync...", vim.log.levels.INFO)

	-- Define jobs
	local git_push = get_job():new({
		command = "git",
		args = { "push" },
		cwd = path,
		on_exit = function(_, code)
			vim.schedule(function()
				if code == 0 then
					vim.notify("SKB: Sync Complete!", vim.log.levels.INFO)
				else
					vim.notify("SKB: Push failed. Check :messages", vim.log.levels.ERROR)
				end
			end)
		end,
	})

	local git_pull = get_job():new({
		command = "git",
		args = { "pull", "--rebase" },
		cwd = path,
		on_exit = function(_, code)
			if code == 0 then
				git_push:start()
			else
				vim.schedule(function()
					vim.notify("SKB: Pull failed. Fix conflicts manually.", vim.log.levels.ERROR)
				end)
			end
		end,
	})

	local git_commit = get_job():new({
		command = "git",
		args = { "commit", "-m", "Auto-sync: " .. timestamp },
		cwd = path,
		on_exit = function(_, code)
			if M.config.options.git.remote then
				git_pull:start()
			else
				vim.schedule(function()
					vim.notify("SKB: Local Commit Complete", vim.log.levels.INFO)
				end)
			end
		end,
	})

	local git_add = get_job():new({
		command = "git",
		args = { "add", "." },
		cwd = path,
		on_exit = function(_, code)
			if code == 0 then
				git_commit:start()
			else
				vim.schedule(function()
					vim.notify("SKB: Git Add failed", vim.log.levels.ERROR)
				end)
			end
		end,
	})

	-- Start the chain
	git_add:start()
end

return M
