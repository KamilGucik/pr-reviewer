-- Additional tests for the show_pr_selection function
local stub = require("luassert.stub")
local ui = require("pr-reviewer.ui")

describe("show_pr_selection extended tests", function()
  before_each(function()
    ui.setup({
      ui = {
        use_telescope = false,
        width = 0.8,
        height = 0.8,
      },
    })
  end)

  after_each(function()
    -- Clean up any stubs or mocks
    if vim.notify:is_stub() then
      vim.notify:revert()
    end
  end)

  it("should handle PRs with empty titles gracefully", function()
    -- Arrange
    stub(vim.ui, "select")
    local prs = {
      { number = 1, title = "", author = { login = "user1" } },
      { number = 2, title = nil, author = { login = "user2" } },
    }
    local callback = spy.new(function() end)

    -- Act
    ui._show_builtin_selection(prs, callback)

    -- Assert
    assert.stub(vim.ui.select).was_called(1)
    local args = vim.ui.select.calls[1]
    assert.are.same({ "#1  (user1)", "#2  (user2)" }, args.refs[1])

    -- Cleanup
    vim.ui.select:revert()
  end)

  it("should handle PRs with missing author information gracefully", function()
    -- Arrange
    stub(vim.ui, "select")
    local prs = {
      { number = 1, title = "PR 1", author = nil },
      { number = 2, title = "PR 2", author = {} },
    }
    local callback = spy.new(function() end)

    -- Act
    ui._show_builtin_selection(prs, callback)

    -- Assert
    assert.stub(vim.ui.select).was_called(1)
    local args = vim.ui.select.calls[1]
    assert.are.same({ "#1 PR 1 ()", "#2 PR 2 ()" }, args.refs[1])

    -- Cleanup
    vim.ui.select:revert()
  end)

  it("should gracefully handle Telescope not being available even when configured", function()
    -- Arrange
    local config_with_telescope = {
      ui = {
        use_telescope = true,
        width = 0.8,
        height = 0.8,
      },
    }
    ui.setup(config_with_telescope)

    stub(ui, "_show_builtin_selection")

    -- Mock pcall to simulate telescope error during require
    local original_pcall = _G.pcall
    _G.pcall = function()
      return false, "module 'telescope' not found"
    end

    local prs = { { number = 1, title = "Test PR", author = { login = "user" } } }
    local callback = function() end

    -- Act
    ui.show_pr_selection(prs, callback)

    -- Assert
    assert.stub(ui._show_builtin_selection).was_called_with(prs, callback)

    -- Cleanup
    _G.pcall = original_pcall
    ui._show_builtin_selection:revert()
  end)

  it("should handle unexpected PR data structure gracefully", function()
    -- Arrange
    stub(vim.ui, "select")
    local malformed_prs = {
      { id = 1, name = "Bad PR 1" }, -- Missing expected fields
      {}, -- Empty PR data
    }
    local callback = spy.new(function() end)

    -- Act
    ui._show_builtin_selection(malformed_prs, callback)

    -- Assert
    assert.stub(vim.ui.select).was_called(1)
    local args = vim.ui.select.calls[1]
    -- Should handle missing fields without errors
    assert.are.same({ "# ", "# " }, args.refs[1])

    -- Cleanup
    vim.ui.select:revert()
  end)

  it("should handle very long PR titles by truncating them in the UI", function()
    -- Arrange
    stub(vim.ui, "select")
    local very_long_title = string.rep("Very long title ", 20) -- 300+ characters
    local prs = {
      { number = 1, title = very_long_title, author = { login = "user1" } },
    }
    local callback = spy.new(function() end)

    -- Act
    ui._show_builtin_selection(prs, callback)

    -- Assert
    assert.stub(vim.ui.select).was_called(1)
    local args = vim.ui.select.calls[1]
    -- Verify the length of the displayed item
    assert.truthy(#args.refs[1][1] <= 300, "PR title should be truncated for display")

    -- Cleanup
    vim.ui.select:revert()
  end)
end)
