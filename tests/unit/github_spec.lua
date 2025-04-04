-- Tests for the PR-Reviewer GitHub module
local mock = require("luassert.mock")
local stub = require("luassert.stub")

-- Mocking the job module from plenary
local job_mock = mock(require("plenary.job"), true)

-- Load GitHub module
local github = require("pr-reviewer.github")

describe("GitHub Module", function()
  after_each(function()
    -- Cleanup mocks/stubs
    job_mock:revert()
  end)

  describe("fetch_pull_requests", function()
    it("should call gh command to fetch PRs and parse the result", function()
      -- Arrange
      local fake_output = [[
        {
          "number": 123,
          "title": "Fix bug in UI",
          "author": { "login": "user1" },
          "url": "https://github.com/user/repo/pull/123",
          "headRefName": "feature-branch"
        }
      ]]

      -- Mock the job to return our fake output
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(0, 0) -- success exit code
            end
            if opts.on_stdout then
              opts.on_stdout(fake_output)
            end
          end,
        }
      end

      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_requests(callback_spy)

      -- Assert
      assert.spy(callback_spy).was_called(1)
      local args = callback_spy.calls[1]
      assert.equals(1, #args.refs) -- One argument was passed
      assert.equals(1, #args.refs[1]) -- One PR was returned
      assert.equals(123, args.refs[1][1].number)
      assert.equals("Fix bug in UI", args.refs[1][1].title)
      assert.equals("user1", args.refs[1][1].author.login)
    end)

    it("should handle empty PR list", function()
      -- Arrange
      local fake_output = "[]"

      -- Mock the job to return our fake output
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(0, 0) -- success exit code
            end
            if opts.on_stdout then
              opts.on_stdout(fake_output)
            end
          end,
        }
      end

      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_requests(callback_spy)

      -- Assert
      assert.spy(callback_spy).was_called_with({})
    end)

    it("should handle errors in the command execution", function()
      -- Arrange
      -- Mock the job to simulate an error
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(1, 0) -- error exit code
            end
            if opts.on_stderr then
              opts.on_stderr("Error: couldn't authenticate")
            end
          end,
        }
      end

      stub(vim, "notify")
      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_requests(callback_spy)

      -- Assert
      assert.stub(vim.notify).was_called(1)
      assert.spy(callback_spy).was_not_called()

      -- Cleanup
      vim.notify:revert()
    end)
  end)

  describe("fetch_pull_request_details", function()
    it("should call gh command to fetch PR details and parse the result", function()
      -- Arrange
      local pr_number = 123
      local fake_output = [[
        {
          "number": 123,
          "title": "Fix bug in UI",
          "author": { "login": "user1" },
          "body": "This PR fixes a bug",
          "files": [
            {"path": "src/main.lua", "additions": 10, "deletions": 5, "changes": 15}
          ],
          "commits": [
            {"message": "Fix bug", "sha": "abc123"}
          ]
        }
      ]]

      -- Mock the job to return our fake output
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(0, 0) -- success exit code
            end
            if opts.on_stdout then
              opts.on_stdout(fake_output)
            end
          end,
        }
      end

      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_request_details(pr_number, callback_spy)

      -- Assert
      assert.spy(callback_spy).was_called(1)
      local args = callback_spy.calls[1]
      assert.equals(123, args.refs[1].number)
      assert.equals("Fix bug in UI", args.refs[1].title)
      assert.equals("This PR fixes a bug", args.refs[1].body)
    end)

    it("should handle errors in command execution", function()
      -- Arrange
      local pr_number = 999

      -- Mock the job to simulate an error
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(1, 0) -- error exit code
            end
            if opts.on_stderr then
              opts.on_stderr("Error: PR not found")
            end
          end,
        }
      end

      stub(vim, "notify")
      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_request_details(pr_number, callback_spy)

      -- Assert
      assert.stub(vim.notify).was_called(1)
      assert.spy(callback_spy).was_not_called()

      -- Cleanup
      vim.notify:revert()
    end)
  end)

  describe("fetch_pull_request_diff", function()
    it("should call gh command to fetch PR diff and process it", function()
      -- Arrange
      local pr_number = 123
      local fake_diff =
        "diff --git a/file.lua b/file.lua\nindex abc123..def456 100644\n--- a/file.lua\n+++ b/file.lua\n@@ -1,5 +1,5 @@\n-old line\n+new line"

      -- Mock the job to return our fake output
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(0, 0) -- success exit code
            end
            if opts.on_stdout then
              opts.on_stdout(fake_diff)
            end
          end,
        }
      end

      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_request_diff(pr_number, callback_spy)

      -- Assert
      assert.spy(callback_spy).was_called_with(fake_diff)
    end)

    it("should handle errors in command execution", function()
      -- Arrange
      local pr_number = 999

      -- Mock the job to simulate an error
      job_mock.new = function(opts)
        return {
          start = function()
            if opts.on_exit then
              opts.on_exit(1, 0) -- error exit code
            end
            if opts.on_stderr then
              opts.on_stderr("Error: PR not found")
            end
          end,
        }
      end

      stub(vim, "notify")
      local callback_spy = spy.new(function() end)

      -- Act
      github.fetch_pull_request_diff(pr_number, callback_spy)

      -- Assert
      assert.stub(vim.notify).was_called(1)
      assert.spy(callback_spy).was_not_called()

      -- Cleanup
      vim.notify:revert()
    end)
  end)

  -- Test the _user_on_exit function which was mentioned in the error stack trace
  describe("_user_on_exit (internal)", function()
    it("should handle successful exit codes", function()
      -- We need to expose the internal function for testing
      -- This is a bit hacky but necessary for testing private functions
      local _user_on_exit = github._user_on_exit or function() end

      if type(_user_on_exit) ~= "function" then
        pending("Cannot test _user_on_exit as it's not exposed")
        return
      end

      -- Arrange
      local captured_stdout = { "test output" }
      local callback_spy = spy.new(function() end)
      local code = 0 -- success
      local signal = 0 -- no signal

      -- Act
      _user_on_exit(callback_spy, captured_stdout)(code, signal)

      -- Assert
      assert.spy(callback_spy).was_called_with("test output")
    end)

    it("should handle error exit codes", function()
      -- Same caveat as above about testing private functions
      local _user_on_exit = github._user_on_exit or function() end

      if type(_user_on_exit) ~= "function" then
        pending("Cannot test _user_on_exit as it's not exposed")
        return
      end

      -- Arrange
      local captured_stdout = { "test output" }
      local captured_stderr = { "error message" }
      local callback_spy = spy.new(function() end)
      local code = 1 -- error
      local signal = 0 -- no signal

      stub(vim, "notify")
      stub(vim, "schedule_wrap", function(fn)
        return fn
      end) -- Mock schedule_wrap to just return the function

      -- Act
      _user_on_exit(callback_spy, captured_stdout, captured_stderr)(code, signal)

      -- Assert
      assert.spy(callback_spy).was_not_called()
      assert.stub(vim.notify).was_called(1)

      -- Cleanup
      vim.notify:revert()
      vim.schedule_wrap:revert()
    end)
  end)
end)
