# himake.nvim (vibe code)

A Neovim plugin for managing HiMake build system packages. This plugin provides a simple file picker to select and manage active `.hmk` packages for the HiMake build system.

## Features

- 🎯 **File Picker**: Easy selection of `.hmk` files using a modern picker interface
- 💾 **State Management**: Persistent storage of the active package across Neovim sessions  
- 🎨 **Clean Interface**: Simple, intuitive interface with minimal configuration
- 🔧 **Modern**: Built with Folke's ecosystem (snacks.nvim) for the best user experience

## Requirements

- Neovim >= 0.9.0
- [snacks.nvim](https://github.com/folke/snacks.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (required by snacks.nvim)

## Installation

### Using lazy.nvim

```lua
{
  'your-username/himake.nvim',
  dependencies = {
    'folke/snacks.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('himake').setup({
      keybind = '<leader>hp', -- Optional: customize keybinding
    })
  end
}
```

## Usage

### Basic Usage

1. Press `<leader>hp` (or run `:HiMakePicker`) to open the file picker
2. Select a `.hmk` file from the current working directory
3. The selected package becomes the active package

### API

```lua
-- Setup the plugin
require('himake').setup({
  keybind = '<leader>hp',  -- Default keybinding
  state_key = 'himake_active_package',  -- Global variable for state
})

-- Open the package picker
require('himake').pick_package()

-- Get current active package (relative path)
local current_package = require('himake').get_active_package()

-- Get current active package (absolute path)  
local current_package_abs = require('himake').get_active_package_absolute()

-- Set package programmatically
require('himake').set_active_package('path/to/package.hmk')

-- Clear active package
require('himake').clear_active_package()
```

## Configuration

The plugin works out of the box with sensible defaults:

```lua
{
  keybind = '<leader>hp',        -- Keybinding to open picker
  state_key = 'himake_active_package',  -- Global variable for persistence
}
```

## How it Works

1. The plugin searches the current working directory recursively for `.hmk` files
2. Files are displayed in a clean picker interface with relative paths
3. When you select a file, it's stored as the "active package" 
4. The active package persists across Neovim sessions using `vim.g`

## Integration with HiMake

This plugin is designed to work alongside your HiMake build system. After selecting an active package, you can:

- Use the stored package path in custom commands
- Integrate with your build workflows
- Access the current package programmatically for further automation

## Contributing

Feel free to submit issues and pull requests.

## License

See [LICENSE](LICENSE) file.