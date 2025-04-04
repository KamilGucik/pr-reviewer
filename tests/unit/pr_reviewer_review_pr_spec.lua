-- Tests for the PR-Reviewer main module's review_pr function
local mock = require("luassert.mock")
local stub = require("luassert.stub")

-- Load PR-Reviewer module
local pr_reviewer = require("pr-reviewer")
local github_mock = mock(require("pr-reviewer.github"))
local ui_mock = mock(require("pr-reviewer.ui"))

describe("PR-Reviewer review_pr function", function()
  after_each(function()
    -- Cleanup mocks/stubs
    github_mock:revert()
    ui_mock:revert()
  end)

  describe("review_pr", function()
    it("should get PR details directly when PR number is provided", function()
      -- Arrange
      stub(github_mock, "get_pr_details", function(pr_number, callback)
        assert.equals("123", pr_number)
        callback({ number = 123, title = "Test PR" })
      end)
      
      stub(pr_reviewer, "generate_review", function(pr_data)
        assert.equals(123, pr_data.number)
      end)
      
      -- Act
      pr_reviewer.review_pr("123")
      
      -- Assert
      assert.stub(github_mock.get_pr_details).was_called(1)
      assert.stub(pr_reviewer.generate_review).was_called(1)
    end)
    
    it("should prompt for PR list type when no PR number is provided", function()
      -- Arrange
      stub(ui_mock, "prompt_pr_list_type", function(callback)
        -- Simulate user selecting assigned PRs
        callback(false)
      end)
      
      stub(github_mock, "list_prs", function(callback, show_all)
        assert.equals(false, show_all)
        callback({ { number = 123, title = "Test PR" } })
      end)
      
      stub(ui_mock, "show_pr_selection", function(prs, callback)
        assert.equals(1, #prs)
        assert.equals(123, prs[1].number)
        callback(prs[1])
      end)
      
      stub(github_mock, "get_pr_details", function(pr_number, callback)
        assert.equals(123, pr_number)
        callback({ number = 123, title = "Test PR" })
      end)
      
      stub(pr_reviewer, "generate_review", function(pr_data)
        assert.equals(123, pr_data.number)
      end)
      
      -- Act
      pr_reviewer.review_pr(nil)
      
      -- Assert
      assert.stub(ui_mock.prompt_pr_list_type).was_called(1)
      assert.stub(github_mock.list_prs).was_called(1)
      assert.stub(ui_mock.show_pr_selection).was_called(1)
      assert.stub(github_mock.get_pr_details).was_called(1)
      assert.stub(pr_reviewer.generate_review).was_called(1)
    end)
    
    it("should list all PRs when user selects that option", function()
      -- Arrange
      stub(ui_mock, "prompt_pr_list_type", function(callback)
        -- Simulate user selecting all PRs
        callback(true)
      end)
      
      stub(github_mock, "list_prs", function(callback, show_all)
        assert.equals(true, show_all)
        callback({ { number = 456, title = "Another PR" } })
      end)
      
      stub(ui_mock, "show_pr_selection", function(prs, callback)
        assert.equals(1, #prs)
        assert.equals(456, prs[1].number)
        callback(prs[1])
      end)
      
      stub(github_mock, "get_pr_details", function(pr_number, callback)
        assert.equals(456, pr_number)
        callback({ number = 456, title = "Another PR" })
      end)
      
      stub(pr_reviewer, "generate_review", function(pr_data)
        assert.equals(456, pr_data.number)
      end)
      
      -- Act
      pr_reviewer.review_pr(nil)
      
      -- Assert
      assert.stub(ui_mock.prompt_pr_list_type).was_called(1)
      assert.stub(github_mock.list_prs).was_called_with(match._, true)
      assert.stub(ui_mock.show_pr_selection).was_called(1)
      assert.stub(github_mock.get_pr_details).was_called(1)
      assert.stub(pr_reviewer.generate_review).was_called(1)
    end)
  end)
end)
