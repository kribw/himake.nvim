local M = {}

-- Default configuration
M.defaults = {
  keybind = '<leader>hp',
  state_key = 'himake_active_package',
}

-- Global config state
M.config = M.defaults

-- Merge user config with defaults
function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', M.defaults, user_config or {})
end

-- Get current configuration
function M.get_config()
  return M.config
end

-- Set active package in persistent storage
function M.set_active_package(path)
  vim.g[M.config.state_key] = path
end

-- Get active package from persistent storage
function M.get_active_package()
  return vim.g[M.config.state_key]
end

-- Clear active package
function M.clear_active_package()
  vim.g[M.config.state_key] = nil
end

return M