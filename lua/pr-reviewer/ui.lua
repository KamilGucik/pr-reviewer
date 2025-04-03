-- UI components for PR-Reviewer
local M = {}

-- Configuration reference
M.config = {}

-- Setup function
function M.setup(config)
  M.config = config
end

-- Show PR selection UI
function M.show_pr_selection(prs, callback)
  if #prs == 0 then
    vim.notify("No PRs awaiting your review", vim.log.levels.INFO)
    return
  end

  if M.config.ui.use_telescope and pcall(require, "telescope") then
    M._show_telescope_selection(prs, callback)
  else
    M._show_builtin_selection(prs, callback)
  end
end

-- Show PR selection using Telescope
function M._show_telescope_selection(prs, callback)
  require("telescope")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  local entries = {}
  for _, pr in ipairs(prs) do
    table.insert(entries, {
      value = pr,
      display = string.format("#%s %s (%s)", pr.number, pr.title, pr.author.login),
      ordinal = string.format("%s %s %s", pr.number, pr.title, pr.author.login),
    })
  end

  pickers
    .new({}, {
      prompt_title = "PR Review",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = entry.display,
            ordinal = entry.ordinal,
          }
        end,
      }),
      sorter = conf.generic_sorter(),
      attach_mappings = function(prompt_bufnr, map)
        map("i", "<CR>", function()
          local selection = require("telescope.actions.state").get_selected_entry(prompt_bufnr)
          require("telescope.actions").close(prompt_bufnr)
          callback(selection.value)
        end)
        return true
      end,
    })
    :find()
end

-- Show PR selection using built-in UI
function M._show_builtin_selection(prs, callback)
  local items = {}
  for _, pr in ipairs(prs) do
    table.insert(items, string.format("#%s %s (%s)", pr.number, pr.title, pr.author.login))
  end

  vim.ui.select(items, {
    prompt = "Select a PR to review:",
  }, function(choice)
    if choice then
      local pr_number = string.match(choice, "#(%d+)")
      for _, pr in ipairs(prs) do
        if tostring(pr.number) == pr_number then
          callback(pr)
          break
        end
      end
    end
  end)
end

-- Prompt for review options (custom prompt)
function M.prompt_for_review_options(default_prompt, callback)
  vim.ui.input({
    prompt = "Enter custom review prompt (or leave blank for default):",
    default = default_prompt,
  }, function(input)
    callback(input)
  end)
end

-- Show PR review UI with AI feedback
function M.show_review(pr_data, review)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * M.config.ui.width)
  local height = math.floor(vim.o.lines * M.config.ui.height)

  -- Display review in buffer
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(review, "\n"))
  vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

  -- Open in a floating window
  vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })

  -- Set buffer name
  vim.api.nvim_buf_set_name(bufnr, string.format("PR Review: #%s %s", pr_data.number, pr_data.title))
end

return M
