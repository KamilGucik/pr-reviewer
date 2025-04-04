-- Tests for notification behavior in UI module
local ui = require("pr-reviewer.ui")

describe("UI Module notifications", function()
  before_each(function()
    ui.setup({
      ui = {
        use_telescope = false,
        width = 0.8,
        height = 0.8,
      },
    })
  end)

  it("should call vim.notify when there are no PRs", function()
    -- Arrange
    local original_notify = vim.notify
    local notify_called = false
    local notify_message = nil
    local notify_level = nil

    vim.notify = function(msg, level)
      notify_called = true
      notify_message = msg
      notify_level = level
    end

    -- Act
    ui.show_pr_selection({}, function() end)

    -- Assert
    assert.truthy(notify_called)
    assert.are.equal("No PRs awaiting your review", notify_message)
    assert.are.equal(vim.log.levels.INFO, notify_level)

    -- Cleanup
    vim.notify = original_notify
  end)

  it("should not call vim.notify when there are PRs", function()
    -- Arrange
    local original_notify = vim.notify
    local original_ui_select = vim.ui.select
    local notify_called = false

    vim.notify = function()
      notify_called = true
    end

    vim.ui.select = function() end -- Mock ui.select to do nothing

    local prs = { { number = 1, title = "Test PR", author = { login = "user" } } }

    -- Act
    ui.show_pr_selection(prs, function() end)

    -- Assert
    assert.falsy(notify_called)

    -- Cleanup
    vim.notify = original_notify
    vim.ui.select = original_ui_select
  end)
end)
