local M = {}
local config = require("skb.config")

local health = vim.health

-- Helper to check external executables
local function check_bin(name, is_optional)
	if vim.fn.executable(name) == 1 then
		health.ok(string.format("'%s' is installed", name))
	else
		if is_optional then
			health.warn(string.format("'%s' is not installed", name), "Some features might be limited.")
		else
			health.error(string.format("'%s' is not installed", name), string.format("Please install '%s'.", name))
		end
	end
end

-- Helper to check lua plugins
local function check_plugin(name)
	local status, _ = pcall(require, name)
	if status then
		health.ok(string.format("Plugin '%s' found", name))
	else
		health.error(string.format("Plugin '%s' not found", name), "Install it using your plugin manager.")
	end
end

function M.check()
	health.start("SKB Knowledge Base Check")

	-- 1. Check Lua Dependencies
	health.info("Checking Lua Dependencies...")
	check_plugin("plenary")
	check_plugin("telescope")

	-- 2. Check External Tools
	health.info("Checking External Tools...")
	check_bin("git", false) -- Required
	check_bin("rg", false) -- Required for Live Grep
	check_bin("fd", true) -- For find files

	-- 3. Check Configuration & Paths
	health.info("Checking Configuration...")

	-- Ensure we have options loaded (merge defaults if setup hasn't run yet)
	local opts = vim.tbl_deep_extend("keep", config.options or {}, config.defaults)
	local path_str = vim.fn.expand(opts.skb_path)

	-- Check Root Path
	if vim.fn.isdirectory(path_str) == 1 then
		health.ok("Knowledge Base path exists: " .. path_str)
	else
		health.warn(
			"Knowledge Base path does not exist: " .. path_str,
			"Run setup() or call a plugin function to initialize directories."
		)
	end

	-- Check Git Status inside the path
	if opts.git.enabled then
		local git_dir = path_str .. "/.git"
		if vim.fn.isdirectory(git_dir) == 1 then
			health.ok("Git initialized in Knowledge Base")
		elseif vim.fn.isdirectory(path_str) == 1 then
			health.warn("Git not initialized yet", "It will initialize automatically when you use the plugin.")
		end
	else
		health.info("Git integration is disabled in config")
	end
end

return M
