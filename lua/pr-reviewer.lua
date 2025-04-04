-- Main PR-Reviewer module
local M = {}

-- Default configuration
M.config = {
  -- Function that generates a review directly
  model_cmd = function(context, prompt)
    -- This is a placeholder implementation that should be replaced
    -- In a real setup, you might call an AI service, use CodeCompanion, etc.
    return string.format([[
# PR Review

## Summary
This is a generated review based on the provided context and prompt.

## Context
%s

## Prompt
%s

## Recommendations
- This is a placeholder review
- Replace this function with your actual implementation
- Connect to your preferred AI service or tool
    ]], context:sub(1, 100) .. "...", prompt)
  end,
  default_prompt = "Please review this PR for any bugs, code quality issues, or potential improvements.",
  gh_cmd = "gh",
  ui = {
    width = 0.8,
    height = 0.8,
    use_telescope = true,
  }
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)
  
  -- Setup submodules with the config
  require("pr-reviewer.github").setup(M.config)
  require("pr-reviewer.ui").setup(M.config)
  require("pr-reviewer.ai").setup(M.config)
end

-- Check if setup is properly configured
function M.check_setup()
  local github = require("pr-reviewer.github")
  github.check_auth()
  
  vim.notify("PR-Reviewer configuration check complete", vim.log.levels.INFO)
end

-- Review a PR by number or select from available PRs
function M.review_pr(pr_number)
  local github = require("pr-reviewer.github")
  local ui = require("pr-reviewer.ui")

  if pr_number then
    -- Review specific PR by number
    github.get_pr_details(pr_number, function(pr_data)
      M.generate_review(pr_data)
    end)
  else
    -- Show selection UI for PRs
    ui.prompt_pr_list_type(function(show_all)
      github.list_prs(function(prs)
        ui.show_pr_selection(prs, function(pr)
          github.get_pr_details(pr.number, function(pr_data)
            M.generate_review(pr_data)
          end)
        end)
      end, show_all)
    end)
  end
end

-- Generate PR review using the AI module
function M.generate_review(pr_data)
  local github = require("pr-reviewer.github")
  local ui = require("pr-reviewer.ui")
  local ai = require("pr-reviewer.ai")

  -- Format PR context for AI
  local context = github.format_pr_context(pr_data)
  
  -- Prompt for custom review instructions if needed
  ui.prompt_for_review_options(M.config.default_prompt, function(prompt)
    if not prompt or prompt == "" then
      prompt = M.config.default_prompt
    end
    
    -- Generate review with AI
    ai.generate_review(context, prompt, function(review)
      ui.show_review(pr_data, review)
    end)
  end)
end

return M