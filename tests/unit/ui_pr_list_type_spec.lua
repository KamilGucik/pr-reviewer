-- Tests for the PR list type selection UI
local mock = require("luassert.mock")
local stub = require("luassert.stub")

-- Load UI module
local ui = require("pr-reviewer.ui")

describe("UI PR List Type Selection", function()
  before_each(function()
    -- Set up config
    ui.setup({ ui = { use_telescope = false } })
  end)
  
  describe("prompt_pr_list_type", function()
    it("should call vim.ui.select with the correct options", function()
      -- Arrange
      stub(vim.ui, "select", function(items, opts, on_choice)
        -- Verify items structure
        assert.equals(2, #items)
        assert.equals("PRs assigned to me for review", items[1].text)
        assert.equals(false, items[1].value)
        assert.equals("All open PRs in the repository", items[2].text)
        assert.equals(true, items[2].value)
        
        -- Call the callback with a selection
        on_choice(items[1])
      end)
      
      local callback_spy = spy.new(function() end)
      
      -- Act
      ui.prompt_pr_list_type(callback_spy)
      
      -- Assert
      assert.stub(vim.ui.select).was_called(1)
      assert.spy(callback_spy).was_called_with(false)
      
      -- Cleanup
      vim.ui.select:revert()
    end)
    
    it("should handle user selecting all PRs", function()
      -- Arrange
      stub(vim.ui, "select", function(items, opts, on_choice)
        -- Call the callback with the "all PRs" option
        on_choice(items[2])
      end)
      
      local callback_spy = spy.new(function() end)
      
      -- Act
      ui.prompt_pr_list_type(callback_spy)
      
      -- Assert
      assert.stub(vim.ui.select).was_called(1)
      assert.spy(callback_spy).was_called_with(true)
      
      -- Cleanup
      vim.ui.select:revert()
    end)
    
    it("should default to assigned PRs if user cancels", function()
      -- Arrange
      stub(vim.ui, "select", function(items, opts, on_choice)
        -- Call the callback with nil (simulating cancel)
        on_choice(nil)
      end)
      
      local callback_spy = spy.new(function() end)
      
      -- Act
      ui.prompt_pr_list_type(callback_spy)
      
      -- Assert
      assert.stub(vim.ui.select).was_called(1)
      assert.spy(callback_spy).was_called_with(false)
      
      -- Cleanup
      vim.ui.select:revert()
    end)
  end)
end)
