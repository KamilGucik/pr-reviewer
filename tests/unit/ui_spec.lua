-- Tests for the PR-Reviewer UI module
local match = require("luassert.match")
local stub = require("luassert.stub")
local ui = require("pr-reviewer.ui")

-- Setup with default config
local default_config = {
  ui = {
    use_telescope = false,
    width = 0.8,
    height = 0.8,
  },
}

describe("PR-Reviewer UI", function()
  before_each(function()
    ui.setup(default_config)
  end)

  after_each(function()
    -- Clean up any stubs or mocks
    if vim.notify:is_stub() then
      vim.notify:revert()
    end
  end)

  describe("show_pr_selection", function()
    it("should notify when there are no PRs", function()
      -- Arrange
      stub(vim, "notify")
      local callback = spy.new(function() end)

      -- Act
      ui.show_pr_selection({}, callback)

      -- Assert
      assert.stub(vim.notify).was_called_with("No PRs awaiting your review", vim.log.levels.INFO)
      assert.spy(callback).was_not_called()
    end)

    it("should call _show_telescope_selection when telescope is enabled and available", function()
      -- Arrange
      local config_with_telescope = {
        ui = {
          use_telescope = true,
          width = 0.8,
          height = 0.8,
        },
      }
      ui.setup(config_with_telescope)

      stub(ui, "_show_telescope_selection")
      stub(ui, "_show_builtin_selection")

      -- Mock pcall to simulate telescope being available
      local original_pcall = _G.pcall
      _G.pcall = function()
        return true
      end

      local prs = { { number = 1, title = "Test PR", author = { login = "user" } } }
      local callback = function() end

      -- Act
      ui.show_pr_selection(prs, callback)

      -- Assert
      assert.stub(ui._show_telescope_selection).was_called_with(prs, callback)
      assert.stub(ui._show_builtin_selection).was_not_called()

      -- Cleanup
      _G.pcall = original_pcall
      ui._show_telescope_selection:revert()
      ui._show_builtin_selection:revert()
    end)

    it("should call _show_builtin_selection when telescope is disabled", function()
      -- Arrange
      stub(ui, "_show_builtin_selection")

      local prs = { { number = 1, title = "Test PR", author = { login = "user" } } }
      local callback = function() end

      -- Act
      ui.show_pr_selection(prs, callback)

      -- Assert
      assert.stub(ui._show_builtin_selection).was_called_with(prs, callback)

      -- Cleanup
      ui._show_builtin_selection:revert()
    end)

    it("should call _show_builtin_selection when telescope is enabled but not available", function()
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

      -- Mock pcall to simulate telescope not being available
      local original_pcall = _G.pcall
      _G.pcall = function()
        return false
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

    it("should properly schedule vim.notify for async contexts", function()
      -- Arrange
      local original_schedule_wrap = vim.schedule_wrap
      local schedule_wrap_spy = spy.new(function(fn)
        return function(...)
          fn(...)
        end
      end)
      vim.schedule_wrap = schedule_wrap_spy

      stub(vim, "notify")

      -- Act
      ui.show_pr_selection({}, function() end)

      -- Assert
      assert.spy(schedule_wrap_spy).was_called(1)
      assert.stub(vim.notify).was_called_with("No PRs awaiting your review", vim.log.levels.INFO)

      -- Cleanup
      vim.schedule_wrap = original_schedule_wrap
    end)
  end)

  describe("_show_builtin_selection", function()
    it("should call vim.ui.select with correct parameters", function()
      -- Arrange
      stub(vim.ui, "select")

      local prs = {
        { number = 1, title = "PR 1", author = { login = "user1" } },
        { number = 2, title = "PR 2", author = { login = "user2" } },
      }

      local callback = spy.new(function() end)
      local expected_items = {
        "#1 PR 1 (user1)",
        "#2 PR 2 (user2)",
      }

      -- Act
      ui._show_builtin_selection(prs, callback)

      -- Assert
      assert.stub(vim.ui.select).was_called(1)
      local args = vim.ui.select.calls[1]
      assert.are.same(expected_items, args.refs[1])
      assert.are.same({ prompt = "Select a PR to review:" }, args.refs[2])

      -- Cleanup
      vim.ui.select:revert()
    end)

    it("should call the callback with selected PR", function()
      -- Arrange
      -- Mock vim.ui.select to immediately call its callback
      stub(vim.ui, "select", function(items, _, callback)
        callback(items[2]) -- Select the second PR
      end)

      local prs = {
        { number = 1, title = "PR 1", author = { login = "user1" } },
        { number = 2, title = "PR 2", author = { login = "user2" } },
      }

      local callback = spy.new(function() end)

      -- Act
      ui._show_builtin_selection(prs, callback)

      -- Assert
      assert.spy(callback).was_called_with(prs[2])

      -- Cleanup
      vim.ui.select:revert()
    end)

    it("should not call the callback when selection is cancelled", function()
      -- Arrange
      -- Mock vim.ui.select to call its callback with nil (cancelled)
      stub(vim.ui, "select", function(_, _, callback)
        callback(nil)
      end)

      local prs = {
        { number = 1, title = "PR 1", author = { login = "user1" } },
        { number = 2, title = "PR 2", author = { login = "user2" } },
      }

      local callback = spy.new(function() end)

      -- Act
      ui._show_builtin_selection(prs, callback)

      -- Assert
      assert.spy(callback).was_not_called()

      -- Cleanup
      vim.ui.select:revert()
    end)
  end)

  describe("prompt_for_review_options", function()
    it("should call vim.ui.input with correct parameters", function()
      -- Arrange
      stub(vim.ui, "input")

      local default_prompt = "default prompt"
      local callback = function() end

      -- Act
      ui.prompt_for_review_options(default_prompt, callback)

      -- Assert
      assert.stub(vim.ui.input).was_called_with({
        prompt = "Enter custom review prompt (or leave blank for default):",
        default = default_prompt,
      }, match.is_function())

      -- Cleanup
      vim.ui.input:revert()
    end)

    it("should call the callback with user input", function()
      -- Arrange
      -- Mock vim.ui.input to immediately call its callback
      stub(vim.ui, "input", function(_, callback)
        callback("user input")
      end)

      local default_prompt = "default prompt"
      local callback = spy.new(function() end)

      -- Act
      ui.prompt_for_review_options(default_prompt, callback)

      -- Assert
      assert.spy(callback).was_called_with("user input")

      -- Cleanup
      vim.ui.input:revert()
    end)
  end)

  describe("show_review", function()
    it("should create a buffer and window with correct content", function()
      -- Arrange
      stub(vim.api, "nvim_create_buf").returns(100)
      stub(vim.api, "nvim_buf_set_lines")
      stub(vim.api, "nvim_buf_set_option")
      stub(vim.api, "nvim_open_win")
      stub(vim.api, "nvim_buf_set_name")

      local pr_data = {
        number = 123,
        title = "Test PR",
      }

      local review = "This is a review\nWith multiple lines"

      -- Act
      ui.show_review(pr_data, review)

      -- Assert
      assert.stub(vim.api.nvim_create_buf).was_called_with(false, true)
      assert
        .stub(vim.api.nvim_buf_set_lines)
        .was_called_with(100, 0, -1, false, { "This is a review", "With multiple lines" })
      assert.stub(vim.api.nvim_buf_set_option).was_called_with(100, "modifiable", false)
      assert.stub(vim.api.nvim_buf_set_option).was_called_with(100, "filetype", "markdown")
      assert.stub(vim.api.nvim_open_win).was_called(1) -- Called once with any arguments
      assert.stub(vim.api.nvim_buf_set_name).was_called_with(100, "PR Review: #123 Test PR")

      -- Cleanup
      vim.api.nvim_create_buf:revert()
      vim.api.nvim_buf_set_lines:revert()
      vim.api.nvim_buf_set_option:revert()
      vim.api.nvim_open_win:revert()
      vim.api.nvim_buf_set_name:revert()
    end)
  end)
end)
