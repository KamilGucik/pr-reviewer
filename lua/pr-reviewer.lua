-- main module file
local github = require("pr-reviewer.github")
local ui = require("pr-reviewer.ui")
local ai = require("pr-reviewer.ai")

---@class Config
---@field model_cmd string Command template for the AI model integration
---@field default_prompt string Default review prompt template
---@field gh_cmd string GitHub CLI command to use
---@field ui table UI configuration options
local config = {
  -- Command template for the AI model integration
  model_cmd = 'CodeCompanion query "{context}" "{prompt}"',

  -- Default review prompt template
  default_prompt = [[
      Please review this PR and provide feedback on:
      1. Code quality and best practices
      2. Potential bugs or issues
      3. Performance considerations
      4. Security concerns
      5. Suggested improvements
  ]],

  -- GitHub CLI command to use
  gh_cmd = "gh",

  -- UI options
  ui = {
    -- Whether to use Telescope for PR selection
    use_telescope = true,
    -- Width of the PR selection window (percentage of screen)
    width = 0.8,
    -- Height of the PR selection window (percentage of screen)
    height = 0.6,
  },
}

---@class PRReviewer
local M = {}

---@type Config
M.config = config

---@param args Config?
-- Setup function to initialize the plugin with user configuration
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- Initialize submodules
  github.setup(M.config)
  ui.setup(M.config)
  ai.setup(M.config)
end

-- Check if GitHub CLI is authenticated and ready
function M.check_setup()
  github.check_auth()
end

-- Main review function
function M.review_pr(pr_number)
  if pr_number and pr_number ~= "" then
    github.get_pr_details(pr_number, function(pr_data)
      M.generate_review(pr_data)
    end)
  else
    github.list_prs(function(prs)
      ui.show_pr_selection(prs, function(selected_pr)
        if selected_pr then
          github.get_pr_details(selected_pr.number, function(pr_data)
            M.generate_review(pr_data)
          end)
        end
      end)
    end)
  end
end

-- Generate PR review using AI
function M.generate_review(pr_data)
  -- Prepare context for AI review
  local context = github.format_pr_context(pr_data)

  -- Ask for custom prompt (optional)
  ui.prompt_for_review_options(M.config.default_prompt, function(prompt)
    if prompt then
      -- Generate review with AI
      ai.generate_review(context, prompt, function(review)
        -- Display review in buffer
        ui.show_review(pr_data, review)
      end)
    end
  end)
end

return M
