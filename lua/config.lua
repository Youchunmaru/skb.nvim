local M = {}

-- 1. The Default Configuration
-- This acts as your schema.
M.defaults = {
	kb_path = vim.fn.expand("~/knowledge_base"),
	extension = "md",
	git = {
		enabled = true,
		remote = false,
	},
}

-- 2. The Current Configuration
-- Initially, we just set this to the defaults.
-- When setup() is called, this will be overwritten with merged values.
M.options = vim.deepcopy(M.defaults)

-- 3. The Merge Logic
function M.setup(opts)
	opts = opts or {}

	-- vim.tbl_deep_extend is essentially "Object.assign" or a deep merge.
	-- "force" means the rightmost table (opts) wins if keys conflict.
	M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
