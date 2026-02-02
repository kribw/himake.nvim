# AGENTS.md - Agentic Coding Guidelines for himake.nvim

## Project Overview

**himake.nvim** is a Neovim plugin written in Lua for managing HiMake build system packages (`.hmk` files). It provides a file picker interface using snacks.nvim.

- **Language**: Lua
- **Platform**: Neovim >= 0.9.0
- **Dependencies**: snacks.nvim, plenary.nvim

## Build/Lint/Test Commands

Currently, this project has no formal build, lint, or test infrastructure set up:

- **No test framework** - Tests need to be run manually in Neovim
- **No linter configured** - Consider adding `.luacheckrc` for linting
- **No formatter configured** - Consider adding `stylua.toml` for formatting
- **No CI/CD** - Consider adding GitHub Actions

### Manual Testing

Test changes by loading the plugin in Neovim:
```lua
-- In Neovim, reload the module
:lua package.loaded['himake'] = nil
:lua require('himake').setup({})
:HiMake pick
```

## Code Style Guidelines

### Module Structure

Use the standard Lua module pattern:
```lua
local M = {}

-- Module contents here

return M
```

### Indentation

- **Use tabs** for indentation (as seen in `lua/himake/init.lua`)
- Be consistent within each file

### Naming Conventions

- **Modules**: `snake_case` (e.g., `himake`, `himake.config`)
- **Functions**: `snake_case` (e.g., `pick_package`, `get_config`)
- **Variables**: `snake_case` (e.g., `hmk_files`, `active_package`)
- **Constants**: May use UPPER_CASE or remain snake_case
- **Configuration keys**: `snake_case` (e.g., `state_key`, `keybind`)

### Imports

- Use `require()` for module imports
- Use local variables to cache requires at the top of files
- Order: standard library, third-party, local modules
```lua
local config = require("himake.config")
local utils = require("himake.utils")
```

### Error Handling

- Use `pcall()` for safe requiring of optional dependencies
- Use `vim.notify()` with appropriate log levels for user-facing messages
```lua
local ok, snacks = pcall(require, "snacks")
if not ok then
    vim.notify("himake.nvim requires snacks.nvim", vim.log.levels.ERROR)
    return
end
```

### Vim API Usage

- Use `vim.api.nvim_*` for API calls (e.g., `vim.api.nvim_create_user_command`)
- Use `vim.fn.*` for Vim function calls (e.g., `vim.fn.getcwd()`)
- Use `vim.g.*` for global state persistence
- Use `vim.keymap.set()` for keymaps with `{ silent = true }`
- Use `vim.tbl_deep_extend('force', ...)` for config merging

### File Organization

```
lua/himake/
├── init.lua      # Public API and main logic
├── config.lua    # Configuration management
└── utils.lua     # Utility functions

plugin/
└── himake.lua    # Plugin entry point (lazy loading, user commands)
```

### State Management

- Store persistent state in `vim.g` variables
- Use the config module for state management functions
- Clear state appropriately with `nil` values

### Comments

- Use `--` for single-line comments
- Use blank lines to separate logical sections
- Document public API functions

## Key Patterns

### Configuration
```lua
M.defaults = {
    keybind = '<leader>hp',
    state_key = 'himake_active_package',
}
M.config = M.defaults

function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.defaults, user_config or {})
end
```

### Safe Requires
```lua
local ok, module = pcall(require, "module_name")
if not ok then
    vim.notify("Error message", vim.log.levels.ERROR)
    return
end
```

### User Commands
```lua
vim.api.nvim_create_user_command('CommandName', function()
    require('module').function()
end, { desc = 'Description' })
```

### Subcommand Dispatcher Pattern
For multi-command interfaces like `:HiMake`:
```lua
local subcommands = {
    cmd = function() require('module').function() end,
}

vim.api.nvim_create_user_command('Command', function(opts)
    local cmd_func = subcommands[opts.fargs[1]]
    if cmd_func then cmd_func() end
end, {
    nargs = '?',
    complete = function(_, line)
        return vim.tbl_keys(subcommands)
    end,
})
```

### Async Job Execution
Use `vim.fn.jobstart()` for running external commands:
```lua
local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data, _) end,
    on_stderr = function(_, data, _) end,
    on_exit = function(_, exit_code, _) end,
    stdout_buffered = false,
    stderr_buffered = false,
})
```

## Available Commands

### HiMake Subcommands
- `:HiMake build` - Run himake compilation
- `:HiMake refresh` - Generate compile_commands.json (+compilation_db)
- `:HiMake config` - Configure build options (platform, variant, etc.)
- `:HiMake status` - Show active package and build configuration
- `:HiMake pick` - Select active .hmk package (same as `:HiMakePicker`)

### Legacy Command
- `:HiMakePicker` - Pick HiMake package (backward compatibility)

## Default Keybindings

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>hp` | `:HiMake pick` | Pick HiMake package |
| `<leader>hb` | `:HiMake build` | Run build |
| `<leader>hr` | `:HiMake refresh` | Refresh compilation DB |
| `<leader>hc` | `:HiMake config` | Configure build options |
| `<leader>hs` | `:HiMake status` | Show status |
| `<leader>ho` | Toggle output window | Show/hide output buffer |

## Dependencies

- [snacks.nvim](https://github.com/folke/snacks.nvim) - UI picker interface
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua utilities (via snacks.nvim)

## Notes for Agents

- This is a "vibe code" project - early development stage
- Keep the codebase simple and focused
- Test all changes in a real Neovim environment
- Maintain compatibility with Neovim >= 0.9.0
- No Cursor rules or Copilot instructions currently exist
