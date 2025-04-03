-- Plugin registration
if vim.fn.has("nvim-0.7.0") == 0 then
  vim.api.nvim_err_writeln("PR-Reviewer requires at least Neovim 0.7.0")
  return
end

-- Prevent loading multiple times
if vim.g.loaded_pr_reviewer == 1 then
  return
end
vim.g.loaded_pr_reviewer = 1

-- Register commands
vim.api.nvim_create_user_command("PRReview", function(args)
  require("pr-reviewer").review_pr(args.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("PRReviewSetup", function(args)
  local pr_reviewer = require("pr-reviewer")
  local config_str = args.args

  -- Try to evaluate the config string as Lua code
  local success, config = pcall(loadstring, "return " .. config_str)

  if success and type(config) == "function" then
    local ok, result = pcall(config)
    if ok and type(result) == "table" then
      pr_reviewer.setup(result)
    else
      vim.notify("Invalid configuration", vim.log.levels.ERROR)
    end
  else
    vim.notify("Failed to parse configuration", vim.log.levels.ERROR)
  end
end, { nargs = "+" })

vim.api.nvim_create_user_command("PRReviewCheck", function()
  require("pr-reviewer").check_setup()
end, {})
