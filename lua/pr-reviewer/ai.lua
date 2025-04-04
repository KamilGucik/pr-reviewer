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
  -- Check if model_cmd is a function
  if type(M.config.model_cmd) ~= "function" then
    vim.notify("Invalid model_cmd configuration (must be a function)", vim.log.levels.ERROR)
    return
  end
  
  -- Run the model_cmd function to get the review directly
  local ok, result = pcall(function()
    return M.config.model_cmd(context, prompt)
  end)
  
  -- Handle any errors from the function execution
  if not ok then
    vim.notify("Error executing model_cmd function: " .. tostring(result), vim.log.levels.ERROR)
    return
  end
  
  -- If the function returned nil or non-string result, show an error
  if result == nil or type(result) ~= "string" then
    vim.notify("model_cmd function must return a string containing the review", vim.log.levels.ERROR)
    return
  end
  
  -- Return the review via callback
  callback(result)
end

return M
