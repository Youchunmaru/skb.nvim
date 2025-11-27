local M = {}

-- The Default Configuration
M.defaults = {
	skb_path = "~/knowledge_base",
	extension = "md",
	git = {
		enabled = true,
		remote = false,
	},
}

-- The Current Configuration
-- Initially, we just set this to the defaults.
-- When setup() is called, this will be overwritten with merged values.
M.options = {}
function M.setup(opts)
	opts = opts or {}

	-- vim.tbl_deep_extend is essentially "Object.assign" or a deep merge.
	-- "force" means the rightmost table (opts) wins if keys conflict.
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
	M.options.skb_path = vim.fn.expand(M.options.skb_path) -- expand path to avoid issues later
end

return M
