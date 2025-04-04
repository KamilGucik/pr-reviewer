-- Tests for edge cases in PR selection
local ui = require("pr-reviewer.ui")

describe("PR selection edge cases", function()
  before_each(function()
    ui.setup({
      ui = {
        use_telescope = false,
        width = 0.8,
        height = 0.8,
      },
    })
  end)

  it("should handle PRs with missing fields gracefully", function()
    -- Arrange
    local original_ui_select = vim.ui.select
    local select_called = false
    local select_items = nil

    vim.ui.select = function(items)
      select_called = true
      select_items = items
    end

    local incomplete_prs = {
      { number = 1 }, -- No title or author
      { number = 2, title = "PR 2" }, -- No author
      { number = 3, author = { login = "user3" } }, -- No title
    }

    -- Act
    ui._show_builtin_selection(incomplete_prs, function() end)

    -- Assert
    assert.truthy(select_called)
    assert.are.equal(3, #select_items)
    -- Even with missing fields, the function should create some representation of the PRs
    assert.truthy(select_items[1]:match("#1"))
    assert.truthy(select_items[2]:match("#2 PR 2"))
    assert.truthy(select_items[3]:match("#3"))
    assert.truthy(select_items[3]:match("user3"))

    -- Cleanup
    vim.ui.select = original_ui_select
  end)

  it("should handle telescope use correctly", function()
    -- Arrange
    local config_with_telescope = {
      ui = {
        use_telescope = true,
        width = 0.8,
        height = 0.8,
      },
    }
    ui.setup(config_with_telescope)

    local original_pcall = _G.pcall
    local telescope_required = false

    -- Mock pcall to return false for requiring telescope
    _G.pcall = function(func, ...)
      if func == require then
        local module = ...
        if module == "telescope" then
          telescope_required = true
          return false -- Simulate telescope not available
        end
      end
      return original_pcall(func, ...)
    end

    local original_ui_select = vim.ui.select
    local select_called = false

    vim.ui.select = function()
      select_called = true
    end

    local prs = { { number = 1, title = "PR 1", author = { login = "user1" } } }

    -- Act
    ui.show_pr_selection(prs, function() end)

    -- Assert
    assert.truthy(telescope_required, "Should try to require telescope")
    assert.truthy(select_called, "Should fall back to builtin selection")

    -- Cleanup
    _G.pcall = original_pcall
    vim.ui.select = original_ui_select
  end)
end)
