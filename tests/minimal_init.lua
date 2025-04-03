-- Add the plugin directory to package.path
local plugin_root = vim.fn.getcwd()
vim.opt.runtimepath:append(plugin_root)

-- Minimal plugin configuration for testing
require("pr-reviewer").setup()
