-- GitHub API integration for PR-Reviewer
local M = {}

-- Configuration reference
M.config = {}

-- Setup function
function M.setup(config)
  M.config = config
end

-- Check if GitHub CLI is authenticated and ready
function M.check_auth()
  local Job = require("plenary.job")

  Job:new({
    command = M.config.gh_cmd,
    args = { "auth", "status" },
    on_exit = function(j, return_val)
      vim.schedule(function()
        if return_val == 0 then
          vim.notify("GitHub CLI is authenticated and ready", vim.log.levels.INFO)
          return true
        else
          vim.notify("GitHub CLI authentication issue. Run 'gh auth login' to authenticate.", vim.log.levels.ERROR)
          return false
        end
      end)
    end,
  }):start()
end

-- List PRs awaiting review
function M.list_prs(callback)
  local Job = require("plenary.job")

  Job:new({
    command = M.config.gh_cmd,
    args = { "pr", "list", "--json", "number,title,url,headRefName,author", "--search", "review-requested:@me" },
    on_exit = function(j, return_val)
      vim.schedule(function()
        if return_val ~= 0 then
          vim.notify("Failed to fetch PRs", vim.log.levels.ERROR)
          return
        end

        local result = table.concat(j:result(), "")
        local success, parsed = pcall(vim.json.decode, result)

        if not success then
          vim.notify("Failed to parse PR list", vim.log.levels.ERROR)
          return
        end

        callback(parsed)
      end)
    end,
  }):start()
end

-- Get PR details
function M.get_pr_details(pr_number, callback)
  local Job = require("plenary.job")

  Job:new({
    command = M.config.gh_cmd,
    args = { "pr", "view", pr_number, "--json", "number,title,body,additions,deletions,changedFiles,files" },
    on_exit = function(j, return_val)
      vim.schedule(function()
        if return_val ~= 0 then
          vim.notify("Failed to get PR details", vim.log.levels.ERROR)
          return
        end

        local result = table.concat(j:result(), "")
        local success, parsed = pcall(vim.json.decode, result)

        if not success then
          vim.notify("Failed to parse PR details", vim.log.levels.ERROR)
          return
        end

        -- Get PR diff
        Job:new({
          command = M.config.gh_cmd,
          args = { "pr", "diff", pr_number },
          on_exit = function(j2, return_val2)
            vim.schedule(function()
              if return_val2 ~= 0 then
                vim.notify("Failed to get PR diff", vim.log.levels.ERROR)
                return
              end

              parsed.diff = table.concat(j2:result(), "\n")
              callback(parsed)
            end)
          end,
        }):start()
      end)
    end,
  }):start()
end

-- Format PR context for AI review
function M.format_pr_context(pr_data)
  local context = string.format(
    [[
PR #%s: %s

Description:
%s

Changes Summary:
- %d files changed
- %d additions
- %d deletions

Diff:
%s
]],
    pr_data.number,
    pr_data.title,
    pr_data.body or "(No description provided)",
    pr_data.changedFiles,
    pr_data.additions,
    pr_data.deletions,
    pr_data.diff
  )

  return context
end

return M
