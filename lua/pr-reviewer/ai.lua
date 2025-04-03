-- AI model integration for PR-Reviewer
local M = {}

-- Configuration reference
M.config = {}

-- Setup function
function M.setup(config)
  M.config = config
end

-- Generate review using AI model
function M.generate_review(context, prompt, callback)
  local Job = require("plenary.job")

  local cmd =
    M.config.model_cmd:gsub("{context}", vim.fn.shellescape(context)):gsub("{prompt}", vim.fn.shellescape(prompt))
  local cmd_parts = vim.split(cmd, " ")
  local command = table.remove(cmd_parts, 1)

  -- Run AI review
  Job:new({
    command = command,
    args = cmd_parts,
    on_stdout = function(_, data)
      -- Process each line of output
    end,
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        vim.notify("Failed to get AI review", vim.log.levels.ERROR)
        return
      end

      local review = table.concat(j:result(), "\n")
      callback(review)
    end,
  }):start()
end

return M
