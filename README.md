![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/KamilGucik/pr-reviewer/lint-test.yml?branch=main&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

PR Reviewer is a Neovim plugin that helps you review GitHub pull requests with AI assistance.

## Features

- Review GitHub PRs directly from Neovim
- AI-assisted analysis of PR changes
- User-friendly UI for PR selection
- Customizable review prompts
- Support for multiple PR review styles

## Requirements

- Neovim 0.7.0+
- GitHub CLI (`gh`) installed and authenticated
- Plenary.nvim
- (Optional) Telescope.nvim for enhanced PR selection UI

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'KamilGucik/pr-reviewer',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim', -- optional but recommended
  }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'KamilGucik/pr-reviewer',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim', -- optional but recommended
  },
  config = function()
    require('pr-reviewer').setup({
      -- your configuration here
    })
  end
}
```

## Configuration

```lua
require('pr-reviewer').setup({
  -- Command template for the AI model integration
  -- {context} will be replaced with PR content
  -- {prompt} will be replaced with the review prompt
  model_cmd = 'CodeCompanion query "{context}" "{prompt}"',
  
  -- Default review prompt template
  default_prompt = [[
      Please review this PR and provide feedback on:
      1. Code quality and best practices
      2. Potential bugs or issues
      3. Performance considerations
      4. Security concerns
      5. Suggested improvements
  ]],

  -- GitHub CLI command to use
  gh_cmd = "gh",
  
  -- UI options
  ui = {
    -- Whether to use Telescope for PR selection
    use_telescope = true,
    -- Width of the PR selection window (percentage of screen)
    width = 0.8,
    -- Height of the PR selection window (percentage of screen)
    height = 0.6,
  },
})
```

## Usage

The plugin provides the following commands:

- `:PRReview [PR_NUMBER]` - Review a PR by number, or select from your assigned PRs
- `:PRReviewCheck` - Check if GitHub CLI is authenticated and ready
- `:PRReviewSetup {config}` - Update configuration at runtime

## Workflow

1. Run `:PRReviewCheck` to ensure GitHub CLI is properly authenticated
2. Run `:PRReview` to see a list of PRs assigned to you for review
3. Select a PR to review
4. (Optional) Customize the review prompt
5. Wait for the AI-generated review to appear in a new buffer
6. Use the review as guidance for your actual PR review

## License

MIT
