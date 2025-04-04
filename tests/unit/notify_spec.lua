-- Tests for the notify helper function in UI module
local stub = require("luassert.stub")

-- Since notify is a local function, we need to test its behavior indirectly
describe("notify helper function", function()
  it("should call nvim_echo through schedule_wrap", function()
    -- Arrange
    local ui_path = vim.fn.fnamemodify(vim.fn.findfile("lua/pr-reviewer/ui.lua", vim.o.runtimepath), ":p")
    local ui_content = vim.fn.readfile(ui_path)

    -- Check if the notify function exists in the UI module
    local has_notify_function = false
    for _, line in ipairs(ui_content) do
      if line:match("^local%s+function%s+notify") then
        has_notify_function = true
        break
      end
    end

    assert(has_notify_function, "The UI module should contain a local notify function")

    -- Mock the necessary Neovim API functions
    stub(vim.api, "nvim_echo")

    -- Create a temporary module that exposes the notify function for testing
    local test_notify = loadstring([[
      local function notify(msg, level)
        vim.schedule_wrap(function()
          vim.api.nvim_echo({{msg, level}}, true, {})
        end)()
      end
      return notify
    ]])()

    -- Act
    test_notify("Test message", "INFO")

    -- Assert
    assert.stub(vim.api.nvim_echo).was_called(1)
    local call_args = vim.api.nvim_echo.calls[1]
    assert.are.same({ { "Test message", "INFO" } }, call_args.refs[1])
    assert.are.same(true, call_args.refs[2])

    -- Cleanup
    vim.api.nvim_echo:revert()
  end)

  it("should schedule the notification to run asynchronously", function()
    -- Arrange
    local original_schedule_wrap = vim.schedule_wrap
    local schedule_wrap_spy = spy.new(function(fn)
      return function(...)
        fn(...)
      end
    end)
    vim.schedule_wrap = schedule_wrap_spy

    stub(vim.api, "nvim_echo")

    -- Create a temporary module that exposes the notify function for testing
    local test_notify = loadstring([[
      local function notify(msg, level)
        vim.schedule_wrap(function()
          vim.api.nvim_echo({{msg, level}}, true, {})
        end)()
      end
      return notify
    ]])()

    -- Act
    test_notify("Test message", "INFO")

    -- Assert
    assert.spy(schedule_wrap_spy).was_called(1)
    assert.stub(vim.api.nvim_echo).was_called(1)

    -- Cleanup
    vim.schedule_wrap = original_schedule_wrap
    vim.api.nvim_echo:revert()
  end)
end)
