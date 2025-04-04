local plugin = require("pr-reviewer")

describe("PR Reviewer", function()
  it("can be set up with default options", function()
    plugin.setup()
    assert.are.same(type(plugin.config), "table")
    assert.are.same(type(plugin.config.model_cmd), "function")
    assert.are.same(type(plugin.config.default_prompt), "string")
  end)

  it("can be set up with custom options", function()
    local custom_cmd_function = function(context, prompt)
      return "Custom review for " .. context:sub(1, 10) .. "..."
    end
    
    plugin.setup({
      model_cmd = custom_cmd_function,
      default_prompt = "custom prompt",
      gh_cmd = "custom-gh",
    })

    assert.are.same(plugin.config.model_cmd, custom_cmd_function)
    assert.are.same(plugin.config.default_prompt, "custom prompt")
    assert.are.same(plugin.config.gh_cmd, "custom-gh")
  end)

  -- Mock testing of the review function
  it("can handle review_pr function call", function()
    -- Mock the github module
    local github_mock = {
      get_pr_details = function(pr_number, callback)
        -- Mock successful PR details retrieval
        callback({
          number = "123",
          title = "Test PR",
          body = "Test Description",
          changedFiles = 1,
          additions = 10,
          deletions = 5,
          diff = "mock diff content",
        })
      end,
      format_pr_context = function(pr_data)
        return "Mocked PR context"
      end,
    }

    -- Temporarily replace the modules with mocks
    local real_github = package.loaded["pr-reviewer.github"]
    local real_ui = package.loaded["pr-reviewer.ui"]
    local real_ai = package.loaded["pr-reviewer.ai"]

    package.loaded["pr-reviewer.github"] = github_mock
    package.loaded["pr-reviewer.ui"] = {
      prompt_for_review_options = function(default_prompt, callback)
        callback("Test prompt")
      end,
      setup = function() end,
    }
    package.loaded["pr-reviewer.ai"] = {
      generate_review = function(context, prompt, callback)
        callback("Mock review content")
      end,
      setup = function() end,
    }

    -- Test the function without errors
    local success, err = pcall(function()
      plugin.setup({
        -- Override model_cmd with a test function that returns a string
        model_cmd = function(context, prompt)
          return "This is a test review"
        end
      })
      
      plugin.generate_review({
        number = "123",
        title = "Test PR",
        body = "Test Description",
        changedFiles = 1,
        additions = 10,
        deletions = 5,
        diff = "mock diff content",
      })
    end)
    
    if not success then
      print("Error: " .. tostring(err))
    end

    -- Restore the real modules
    package.loaded["pr-reviewer.github"] = real_github
    package.loaded["pr-reviewer.ui"] = real_ui
    package.loaded["pr-reviewer.ai"] = real_ai

    assert.is_true(success)
  end)
end)
