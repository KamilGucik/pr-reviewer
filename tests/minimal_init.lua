-- Add the plugin directory to package.path
local plugin_root = vim.fn.getcwd()
vim.opt.runtimepath:append(plugin_root)

-- We need plenary for testing
vim.cmd("packadd plenary.nvim")

-- Setup log levels if not defined
if not vim.log or not vim.log.levels then
  vim.log = vim.log or {}
  vim.log.levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
  }
end

-- Minimal plugin configuration for testing
require("pr-reviewer").setup({
  ui = {
    use_telescope = false,
    width = 0.8,
    height = 0.8,
  },
})

-- Add stub helper for tests
_G.stub = function(module, method)
  local original = module[method]
  module[method] = setmetatable({
    calls = {},
    original = original,
    stub = true,
    revert = function()
      module[method] = original
    end,
    returns = function(value)
      local ret_value = value
      module[method] = function(...)
        table.insert(module[method].calls, {
          refs = { ... },
        })
        return ret_value
      end
      return module[method]
    end,
  }, {
    __call = function(self, ...)
      table.insert(self.calls, {
        refs = { ... },
      })
      return nil
    end,
    __index = function(self, key)
      if key == "was_called" then
        return function(times)
          return #self.calls == (times or 1)
        end
      elseif key == "was_called_with" then
        return function(...)
          local expected = { ... }
          for _, call in ipairs(self.calls) do
            local matches = true
            for j, exp in ipairs(expected) do
              if call.refs[j] ~= exp then
                matches = false
                break
              end
            end
            if matches then
              return true
            end
          end
          return false
        end
      end
      return nil
    end,
  })
  return module[method]
end

-- Add spy helper for tests
_G.spy = {
  new = function(fn)
    local spy_fn = {
      calls = {},
      call_count = 0,
      was_called = function(self, times)
        return self.call_count == (times or 1)
      end,
      was_not_called = function(self)
        return self.call_count == 0
      end,
    }

    return setmetatable(spy_fn, {
      __call = function(self, ...)
        table.insert(self.calls, { ... })
        self.call_count = self.call_count + 1
        if fn then
          return fn(...)
        end
      end,
    })
  end,
}
