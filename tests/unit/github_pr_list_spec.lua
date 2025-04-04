-- Tests for the PR-Reviewer GitHub module's PR listing functionality
local mock = require("luassert.mock")
local stub = require("luassert.stub")

-- Mocking the job module from plenary
local job_mock = mock(require("plenary.job"), true)

-- Load GitHub module
local github = require("pr-reviewer.github")

describe("GitHub PR List Module", function()
  before_each(function()
    -- Set up config
    github.setup({ gh_cmd = "gh" })
  end)

  after_each(function()
    -- Cleanup mocks/stubs
    job_mock:revert()
  end)

  describe("list_prs", function()
    it("should fetch PRs assigned for review when show_all is false", function()
      -- Arrange
      local fake_result = '[{"number": 123, "title": "Fix bug", "author": {"login": "user1"}}]'
      
      job_mock.new = function(opts)
        return {
          result = function() return {fake_result} end,
          start = function()
            -- Validate the correct args were passed
            assert.are.same("gh", opts.command)
            assert.are.same("pr", opts.args[1])
            assert.are.same("list", opts.args[2])
            assert.are.same("--search", opts.args[5])
            assert.are.same("review-requested:@me", opts.args[6])
            
            opts.on_exit(opts, 0)
          end
        }
      end

      local callback_spy = spy.new(function() end)
      
      -- Act
      github.list_prs(callback_spy, false)
      
      -- Assert
      assert.spy(callback_spy).was_called(1)
    end)
    
    it("should fetch all PRs when show_all is true", function()
      -- Arrange
      local fake_result = '[{"number": 123, "title": "Fix bug", "author": {"login": "user1"}}]'
      
      job_mock.new = function(opts)
        return {
          result = function() return {fake_result} end,
          start = function()
            -- Validate the correct args were passed (should not have --search flag)
            assert.are.same("gh", opts.command)
            assert.are.same("pr", opts.args[1])
            assert.are.same("list", opts.args[2])
            assert.are_not.same("--search", opts.args[5]) -- This should not be present
            
            opts.on_exit(opts, 0)
          end
        }
      end

      local callback_spy = spy.new(function() end)
      
      -- Act
      github.list_prs(callback_spy, true)
      
      -- Assert
      assert.spy(callback_spy).was_called(1)
    end)
    
    it("should handle errors when fetching PRs", function()
      -- Arrange
      job_mock.new = function(opts)
        return {
          result = function() return {} end,
          start = function()
            opts.on_exit(opts, 1) -- Error exit code
          end
        }
      end
      
      stub(vim, "notify")
      local callback_spy = spy.new(function() end)
      
      -- Act
      github.list_prs(callback_spy, false)
      
      -- Assert
      assert.stub(vim.notify).was_called(1)
      assert.spy(callback_spy).was_not_called()
      
      -- Cleanup
      vim.notify:revert()
    end)
    
    it("should handle invalid JSON response", function()
      -- Arrange
      local fake_result = 'not valid json'
      
      job_mock.new = function(opts)
        return {
          result = function() return {fake_result} end,
          start = function()
            opts.on_exit(opts, 0)
          end
        }
      end
      
      stub(vim, "notify")
      stub(vim.json, "decode", function() error("JSON parse error") end)
      local callback_spy = spy.new(function() end)
      
      -- Act
      github.list_prs(callback_spy, false)
      
      -- Assert
      assert.stub(vim.notify).was_called(1)
      assert.spy(callback_spy).was_not_called()
      
      -- Cleanup
      vim.notify:revert()
      vim.json.decode:revert()
    end)
  end)
end)
