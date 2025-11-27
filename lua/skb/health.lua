local M = {}
local config = require("skb.config")

-- Neovim 0.10+ uses `vim.health`, older versions used `require('health')`
-- This ensures compatibility.
local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local warn = health.warn or health.report_warn
local error = health.error or health.report_error
local info = health.info or health.report_info

-- Helper to check external executables
local function check_bin(name, is_optional)
	if vim.fn.executable(name) == 1 then
		ok(string.format("'%s' is installed", name))
	else
		if is_optional then
			warn(string.format("'%s' is not installed", name), "Some features might be limited.")
		else
			error(string.format("'%s' is not installed", name), string.format("Please install '%s'.", name))
		end
	end
end

-- Helper to check lua plugins
local function check_plugin(name)
	local status, _ = pcall(require, name)
	if status then
		ok(string.format("Plugin '%s' found", name))
	else
		error(string.format("Plugin '%s' not found", name), "Install it using your plugin manager.")
	end
end

function M.check()
	start("SKB Knowledge Base Check")

	-- 1. Check Lua Dependencies
	info("Checking Lua Dependencies...")
	check_plugin("plenary")
	check_plugin("telescope")

	-- 2. Check External Tools
	info("Checking External Tools...")
	check_bin("git", false) -- Required
	check_bin("rg", false) -- Required for Live Grep

	-- 3. Check Configuration & Paths
	info("Checking Configuration...")

	-- Ensure we have options loaded (merge defaults if setup hasn't run yet)
	local opts = vim.tbl_deep_extend("keep", config.options or {}, config.defaults)
	local path_str = vim.fn.expand(opts.skb_path)

	-- Check Root Path
	if vim.fn.isdirectory(path_str) == 1 then
		ok("Knowledge Base path exists: " .. path_str)
	else
		warn(
			"Knowledge Base path does not exist: " .. path_str,
			"Run setup() or call a plugin function to initialize directories."
		)
	end

	-- Check Git Status inside the path
	if opts.git.enabled then
		local git_dir = path_str .. "/.git"
		if vim.fn.isdirectory(git_dir) == 1 then
			ok("Git initialized in Knowledge Base")
		elseif vim.fn.isdirectory(path_str) == 1 then
			warn("Git not initialized yet", "It will initialize automatically when you use the plugin.")
		end
	else
		info("Git integration is disabled in config")
	end
end

return M
